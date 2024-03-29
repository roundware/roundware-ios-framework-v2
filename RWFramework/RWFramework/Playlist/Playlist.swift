
import AVFoundation
import CoreLocation
import Foundation
import Promises
import Repeat
import SceneKit

struct UserAssetData {
    let lastListen: Date
    let playCount: Int
}

public class StreamParams {
    let location: CLLocation
    let panAudioBasedOnLocation: Bool
    let minDist: Double?
    let maxDist: Double?
    let heading: Double?
    let angularWidth: Double?
    let tags: [Int]?

    init(location: CLLocation, panAudioBasedOnLocation: Bool, minDist: Double?, maxDist: Double?, heading: Double?, angularWidth: Double?, tags: [Int]?) {
        self.location = location
        self.panAudioBasedOnLocation = panAudioBasedOnLocation
        self.minDist = minDist
        self.maxDist = maxDist
        self.heading = heading
        self.angularWidth = angularWidth
        self.tags = tags
    }
}

public class Playlist {
    // server communication
    private var updateTimer: Repeater?
    public private(set) var currentParams: StreamParams?
    private(set) var startTime = Date()

    // assets and filters
    private var filters: AssetFilter
    private var sortMethods: [SortMethod]

    /// Map asset ID to data like last listen time.
    private(set) var userAssetData = [Int: UserAssetData]()

    /**
     Mapping of project id to asset pool, allowing for one app
     to support loading multiple projects at once.
     */
    private var assetPool: AssetPool?

    var filteredAssets: [Int: [Asset]] = [:]

    // audio tracks, background and foreground
    public private(set) var speakers: [Speaker] = []
    public private(set) var tracks: [AudioTrack] = []

    private var demoStream: AVPlayer?
    private var demoLooper: Any?

    public private(set) var project: Project!

    private let audioEngine = AVAudioEngine()
    private let audioMixer = AVAudioEnvironmentNode()

    init(filters: AssetFilter, sortBy: [SortMethod]) {
        DispatchQueue.promises = .global()

        self.filters = filters
        sortMethods = sortBy

        // Restart the audio engine upon changing outputs
        NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: audioEngine,
            queue: .main
        ) { _ in
            print("audio engine config change")
            if !self.audioEngine.isRunning {
                self.audioEngine.disconnectNodeOutput(self.audioMixer)
                self.setupAudioConnection()
            }
        }

        // Restart the audio engine after interruptions.
        // For example, another app playing audio over you or the user taking a phone call.
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: audioEngine,
            queue: .main
        ) { notification in
            print("audio engine interruption")
            let type = AVAudioSession.InterruptionType(
                rawValue: notification.userInfo![AVAudioSessionInterruptionTypeKey] as! UInt
            )
            let options = AVAudioSession.InterruptionOptions(
                rawValue: notification.userInfo![AVAudioSessionInterruptionOptionKey] as! UInt
            )
            if type == AVAudioSession.InterruptionType.ended,
                options.contains(.shouldResume),
                !self.audioEngine.isRunning {
                self.audioEngine.disconnectNodeOutput(self.audioMixer)
                self.setupAudioConnection()
            }
        }

        // Push audio attenuation to far away
        audioMixer.distanceAttenuationParameters.distanceAttenuationModel = .linear
        audioMixer.distanceAttenuationParameters.rolloffFactor = 0.00001
        audioMixer.distanceAttenuationParameters.referenceDistance = 1
        audioMixer.distanceAttenuationParameters.maximumDistance = 200_000
        audioMixer.renderingAlgorithm = .HRTFHQ

        // Setup audio engine & mixer
        audioEngine.attach(audioMixer)
        setupAudioConnection()
    }

    private func setupAudioConnection() {
        print("booting audio engine")
        do {
            audioEngine.connect(
                audioMixer,
                to: audioEngine.mainMixerNode,
                format: nil
            )
            try audioEngine.start()
        } catch {
            print(error)
        }
    }
}

// Start-up and public API
extension Playlist {
    // Public API
    public var isPlaying: Bool {
        return tracks.contains { $0.isPlaying }
    }

    func lastListenDate(for asset: Asset) -> Date? {
        return userAssetData[asset.id]?.lastListen
    }

    /**
      All assets available in the current active project.
     */
    public var allAssets: [Asset] {
        return assetPool?.assets ?? []
    }

    public var currentlyPlayingAssets: [Asset] {
        return tracks.compactMap { $0.currentAsset }
    }

    // Internal
    private var assetPoolFile: URL {
        // Keep a separate asset pool file for each project
        return documentsDir.appendingPathComponent("asset-pool-\(RWFramework.projectId).json")
    }

    private var documentsDir: URL {
        return try! FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
    }

    func start() {
        // Starts a session and retrieves project-wide config.
        RWFramework.sharedInstance.apiStartForClientMixing().then { project in
            self.project = project
            print("project settings: \(project)")
            self.useProjectDefaults()
            self.afterSessionInit()
        }
    }

    private func useProjectDefaults() {
        switch project.ordering {
        case "random":
            sortMethods = [SortRandomly()]
        case "by_weight":
            sortMethods = [SortByWeight()]
        case "by_like":
            sortMethods = [SortByLikes()]
        default: break
        }
    }

    /**
      * Retrieve tags to filter by for the current project.
      * Setup the speakers for background audio.
      * Retrieve the list of all assets and check for new assets every few minutes.
     **/
    private func afterSessionInit() {
        // Mark start of the session
        startTime = Date()

        // Load cached assets first
        loadAssetPool()

        // Start playing background music from speakers.
        let speakerUpdate = initSpeakers()

        // Retrieve the list of tracks
        let trackUpdate = initTracks()

        // Initial grab of assets and speakers.
        let assetsUpdate = refreshAssetPool()

        all(speakerUpdate, trackUpdate, assetsUpdate).always {
            RWFramework.sharedInstance.rwStartedSuccessfully()
            self.pause()
        }

        updateTimer = .every(.seconds(project.asset_refresh_interval)) { _ in
            _ = self.refreshAssetPool()
        }
    }

    func pause() {
        for s in speakers { s.pause() }
        for t in tracks { t.pause() }
        if demoLooper != nil {
            demoStream?.pause()
        }
    }

    func resume() {
        print("tracks? \(tracks.count)")
        for s in speakers { s.resume() }
        for t in tracks { t.resume() }
        if demoLooper != nil {
            demoStream?.play()
        }
    }

    func skip() {
        // Fade out the currently playing assets on all tracks.
        for t in tracks {
            t.playNext()
        }
    }

    func skip(to assetId: Int, onTrack trackId: Int? = nil) {
        if let track = tracks.first(where: { $0.id == trackId }) ?? tracks.first,
            let asset = assetPool?.assets.first(where: { $0.id == assetId }) {
            // Play the given asset on a particular track.
            track.playNext(asset: asset)
            // All other tracks fade to silence.
            for other in tracks.filter({ $0 !== track }) {
                other.holdSilence()
            }
        }
    }

    func replay() {
        for t in tracks {
            t.replay()
        }
    }
}

// Offline playback
extension Playlist {
    public enum SaveProgress {
        case none
        case partial
        case complete
    }

    /** Are all the asset files in this project saved for offline playback? */
    public var assetsSavedProgress: SaveProgress {
        guard let assetPool = self.assetPool else { return .none }

        let saved = assetPool.assets.filter { asset in
            (try? self.assetDataFile(for: asset)?.checkResourceIsReachable()) ?? false
        }.count
        if saved >= assetPool.assets.count {
            return .complete
        } else if saved > 0 || assetPool.cached {
            return .partial
        } else {
            return .none
        }
    }

    internal func ensureAssetsSaved() -> Promise<Void> {
        if assetsSavedProgress == .partial {
            return saveAllAssets()
        } else {
            return Promise(())
        }
    }

    /**
     Save all assets in the current pool to disk. This facilitates offline playback.
     */
    public func saveAllAssets() -> Promise<Void> {
        // If offline, make sure we download next time we come online.
        if !assetPool!.cached {
            assetPool = AssetPool(assets: assetPool!.assets, date: assetPool!.date, cached: true)
        }
        return Promise<Void>(on: .global()) {
            // Sort assets by nearness to download closer assets first.
            var allAssets = self.assetPool!.assets
            if let loc = self.currentParams?.location {
                allAssets = allAssets.sorted { a, b in
                    if let aLoc = a.location, let bLoc = b.location {
                        return aLoc.distance(from: loc) < bLoc.distance(from: loc)
                    } else {
                        return a.location != nil
                    }
                }
            }

            // Save each asset to the offline folder.
            let totalAssets = Double(allAssets.count)
            for (index, asset) in allAssets.enumerated() {
                let f = self.assetDataFile(for: asset)!
                // Only download the asset if we don't already have it.
                if !((try? f.checkResourceIsReachable()) ?? false) {
                    // Download the audio data.
                    let remoteUrl = asset.mp3Url!
                    print("offline: downloading \(remoteUrl)")
                    let data = try Data(contentsOf: remoteUrl)

                    // Write the audio data to a file in the cache.
                    try data.write(to: f)
                }

                // Notify the caller that this asset has been downloaded.
                RWFramework.sharedInstance.rwAssetDownloadProgress(Double(index + 1) / totalAssets)
            }
        }
    }

    /**
      Remove all saved assets that belong to the current project.
     */
    public func purgeSavedAssets() -> Promise<Void> {
        if assetPool!.cached {
            assetPool = AssetPool(assets: assetPool!.assets, date: assetPool!.date, cached: false)
        }
        return Promise<Void>(on: .global()) {
            let totalAssets = Double(self.assetPool!.assets.count)
            let fm = FileManager.default
            let parentDir = try fm.url(
                // Not backed up to iCloud, but also not deleted by clearing cache.
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            ).appendingPathComponent("assets-\(RWFramework.projectId)")

            for (index, fileName) in try fm.contentsOfDirectory(atPath: parentDir.path).enumerated() {
                let f = parentDir.appendingPathComponent(fileName)
                try fm.removeItem(at: f)
                RWFramework.sharedInstance.rwAssetDeleteProgress(Double(index + 1) / totalAssets)
            }
        }
    }

    /** Where to save asset data for offline playback. */
    internal func assetDataFile(for asset: Asset) -> URL? {
        guard let url = asset.mp3Url else { return nil }
        do {
            let fm = FileManager.default
            let parentDir = try fm.url(
                // Not backed up to iCloud, but also not deleted by clearing cache.
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            // Keep a separate folder for each project
            let assetsDir = parentDir.appendingPathComponent("assets-\(project.id)")
            // Make sure it exists.
            _ = try? fm.createDirectory(at: assetsDir, withIntermediateDirectories: true, attributes: nil)
            // Convert the remote URL to a local one.
            return assetsDir.appendingPathComponent(url.lastPathComponent)
        } catch {
            print(error)
            return nil
        }
    }
}

// Filters functionality
extension Playlist {
    func updateFilterData() -> Promise<Void> {
        return filters.onUpdateAssets(playlist: self)
            .recover { err in print(err) }
    }

    func passesFilters(_ asset: Asset, forTrack track: AudioTrack) -> Bool {
        return filters.keep(asset, playlist: self, track: track) != .discard
    }
}

// Speaker-associated functionality
extension Playlist {
    /// Prepares all the speakers for this project.
    private func initSpeakers() -> Promise<[Speaker]> {
        return RWFramework.sharedInstance.apiGetSpeakers([
            "project_id": String(project.id),
            "activeyn": "true",
        ]).then { speakers in
            print("playing \(speakers.count) speakers")
            self.speakers = speakers
            self.updateSpeakerVolumes()
        }
    }

    public var distanceToNearestSpeaker: Double {
        if let params = currentParams {
            return speakers.lazy.map {
                $0.distance(to: params.location)
            }.min() ?? 0.0
        } else {
            return 0.0
        }
    }

    public var inSpeakerRange: Bool {
        if currentParams != nil {
            return distanceToNearestSpeaker <= project.out_of_range_distance
        } else {
            return false
        }
    }

    /**
      Update the volumes of all speakers depending on our proximity to each one.
      If the distance to the nearest speaker > outOfRangeDistance, then play demo stream.
     */
    private func updateSpeakerVolumes() {
        if let params = currentParams, !speakers.isEmpty, isPlaying {
            // Only consider playing the demo stream if we're away from all speakers
            let dist = distanceToNearestSpeaker
            if dist > project.out_of_range_distance {
                print("dist to nearest speaker: \(dist)")
                // silence all speakers
                for speaker in speakers {
                    speaker.updateVolume(0)
                }
                playDemoStream()
            } else {
                // Update all speaker volumes
                for speaker in speakers {
                    speaker.updateVolume(at: params.location)
                }
                if let ds = demoStream, let looper = demoLooper {
                    ds.pause()
                    NotificationCenter.default.removeObserver(looper)
                    demoLooper = nil
                }
            }
        }
    }

    private func playDemoStream() {
        // we're out of range, start playing from project.out_of_range_url
        if demoStream == nil, let demoUrl = URL(string: project.out_of_range_url) {
            demoStream = AVPlayer(url: demoUrl)
        }

        // If we weren't playing this before, show the notification.
        if demoLooper == nil {
            RWFramework.sharedInstance.rwUpdateStatus("Out of range!")
            demoStream!.play()
            // Loop the demo stream infinitely
            demoLooper = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: demoStream!.currentItem, queue: .main) { [weak self] _ in
                self?.demoStream?.seek(to: CMTime.zero)
                self?.demoStream?.play()
            }
        }
    }
}

// Track-associated functionality
extension Playlist {
    /// Grab the list of `AudioTrack`s for the current project.
    private func initTracks() -> Promise<Void> {
        let rw = RWFramework.sharedInstance

        return rw.apiGetAudioTracks([
            "project_id": String(project.id),
        ]).then { data -> Void in
            print("assets: using " + data.count.description + " tracks")
            for it in data {
                // TODO: Try to remove playlist dependency. Maybe pass into method?
                it.playlist = self
                self.audioEngine.attach(it.player)
                self.audioEngine.connect(
                    it.player,
                    to: self.audioMixer,
                    format: AVAudioFormat(standardFormatWithSampleRate: 96000, channels: 1)
                )
            }
            if !self.audioEngine.isRunning {
                try self.audioEngine.start()
            }
            self.tracks = data
        }.catch { err in
            print(err)
        }
    }

    private func updateTrackParams() {
        if let params = currentParams {
            // update all tracks in parallel, in case they need to load a new asset
            for t in tracks {
                _ = Promise<Void>(on: .global()) {
                    t.updateParams(params)
                }
            }
        }
    }

    /// Picks the next-up asset to play on the given track.
    /// Applies all the playlist-level and track-level filters to make the decision.
    func next(forTrack track: AudioTrack) -> Asset? {
        print("finding next asset in \(allAssets.count)...")
        
        let filteredAssets = allAssets.lazy.filter { asset in
            // don't pick anything currently playing on another track
            !self.currentlyPlayingAssets.contains { $0.id == asset.id }
                && asset.file != nil
        }.map { asset in
            (asset, self.filters.keep(asset, playlist: self, track: track))
        }.filter { _, rank in
            rank != .discard
        }

        let asset = filteredAssets.min { a, b in
            // play less played assets first
            let playsOfA = userAssetData[a.0.id]?.playCount ?? 0
            let playsOfB = userAssetData[b.0.id]?.playCount ?? 0
            return playsOfA <= playsOfB && a.1.rawValue > b.1.rawValue
        }?.0

        print("playing asset with tags \(asset?.tags)")

        return asset
    }
}

// Asset pool functionality
extension Playlist {
    /// Periodically check for newly published assets
    func refreshAssetPool() -> Promise<Void> {
        return updateAssets().then {
            // Update filtered assets given any newly uploaded assets
            self.updateParams()

            let locRequested = RWFramework.sharedInstance.requestWhenInUseAuthorizationForLocation()
            print("location requested? \(locRequested)")
        }.then(ensureAssetsSaved)
    }

    /// Retrieve audio assets stored on the server.
    /// At the start of a session, gets all the assets.
    /// After that, only adds the assets uploaded since the last call of this function.
    private func updateAssets() -> Promise<Void> {
        let rw = RWFramework.sharedInstance

        var opts = [
            "project_id": String(project.id),
            "media_type": "audio",
            "language": "en",
        ]
        // Only grab assets added since the last update
        if let date = assetPool?.date {
            let timeZone = RWFrameworkConfig.getConfigValueAsNumber("session_timezone", group: .session).intValue

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(secondsFromGMT: timeZone)
            opts["updated__gte"] = dateFormatter.string(from: date)
        } else {
            // On the first call for the asset pool, we only want submitted assets.
            // On subsequent calls, we'll need to know if anything was unsubmitted.
            opts["submitted"] = "true"
        }

        // retrieve newly published assets
        return rw.apiGetAssets(opts).then { (updatedAssets: [Asset]) in
            var assets = self.assetPool?.assets ?? []
            // Remove all old duplicates
            assets.removeAll { a in updatedAssets.contains { b in a.id == b.id } }
            // Append updated assets to our existing pool
            assets.append(contentsOf: updatedAssets)
            // Remove any unsubmitted ones.
            assets.removeAll { $0.submitted == false }

            // Ensure all sort methods have necessary data before sorting.
            _ = try awaitPromise(all(self.sortMethods.map {
                $0.onRefreshAssets(in: self)
            }))

            // Sort the asset pool.
            for sortMethod in self.sortMethods {
                assets.sort(by: { a, b in
                    sortMethod.sortRanking(for: a, in: self) < sortMethod.sortRanking(for: b, in: self)
                })
            }

            // Update this project's asset pool
            self.assetPool = AssetPool(assets: assets, date: Date(), cached: self.assetPool?.cached ?? false)

            print("\(updatedAssets.count) updated assets, total is \(assets.count)")

            // notify filters that the asset pool is updated.
            return self.updateFilterData()
        }.catch { err in
            print(err)
        }.always {
            // Cache the asset pool to reduce future launch time
            self.saveAssetPool()
        }
    }

    /// Framework should call this when stream parameters are updated.
    func updateParams(_ opts: StreamParams) {
        currentParams = opts

        print("playlist tags: \(currentParams?.tags)")

        if let heading = opts.heading {
            audioMixer.listenerAngularOrientation = AVAudio3DAngularOrientation(
                yaw: Float(heading),
                pitch: 0,
                roll: 0
            )
        }

        if project != nil {
            updateParams()
        }
    }

    private func updateParams() {
        updateSpeakerVolumes()
        // TODO: Use a filter to clear data for assets we've moved away from.
        // Tell our tracks to play any new assets.
        updateTrackParams()
    }

    func recordFinishedPlaying(asset: Asset) {
        var playCount = 1
        if let prevEntry = userAssetData[asset.id] {
            playCount += prevEntry.playCount
        }

        userAssetData.updateValue(
            UserAssetData(lastListen: Date(), playCount: playCount),
            forKey: asset.id
        )
    }

    private func saveAssetPool() {
        print("saving asset pool...")
        do {
            let data = try RWFramework.encoder.encode(assetPool)
            try data.write(to: assetPoolFile)
        } catch {
            print(error)
        }
    }

    private func loadAssetPool() {
        // Load existing asset pool from a file
        print("loading asset pool...")
        do {
            let data = try Data(contentsOf: assetPoolFile)
            assetPool = try RWFramework.decoder.decode(AssetPool.self, from: data)
        } catch {
            print(error)
        }
    }
}

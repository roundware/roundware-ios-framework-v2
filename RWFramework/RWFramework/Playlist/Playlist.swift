
import Foundation
import CoreLocation
import AVFoundation
import Promises
import SceneKit
import Repeat

struct UserAssetData {
    let lastListen: Date
    let playCount: Int
}

struct StreamParams {
    let location: CLLocation
    let minDist: Double?
    let maxDist: Double?
    let heading: Double?
    let angularWidth: Double?
}

public class Playlist {
    // server communication
    private var lastUpdate: Date? = nil
    private var updateTimer: Repeater? = nil
    private(set) var currentParams: StreamParams? = nil
    private(set) var startTime = Date()

    // assets and filters
    private var filters: AllAssetFilters
    private var sortMethods: [SortMethod]
    public private(set) var allAssets = [Asset]()
    
    /// Map asset ID to data like last listen time.
    private(set) var userAssetData = [Int: UserAssetData]()

    // audio tracks, background and foreground
    private(set) var speakers: [Speaker]? = nil
    private(set) var tracks: [AudioTrack]? = nil

    private var demoStream: AVPlayer? = nil
    private var demoLooper: Any? = nil

    private(set) var project: Project!

    private let audioEngine = AVAudioEngine()
    private let audioMixer = AVAudioEnvironmentNode()

    init(filters: [AssetFilter], sortBy: [SortMethod]) {
        DispatchQueue.promises = .global()

        self.filters = AllAssetFilters(filters)
        self.sortMethods = sortBy
        
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
            if type == AVAudioSession.InterruptionType.ended
                    && options.contains(.shouldResume)
                    && !self.audioEngine.isRunning {
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

extension Playlist {
    public var currentlyPlayingAssets: [Asset] {
        return tracks?.compactMap { $0.currentAsset } ?? []
    }

    func apply(filter: AssetFilter) {
        self.filters.filters.append(filter)
    }
    
    func lastListenDate(for asset: Asset) -> Date? {
        return self.userAssetData[asset.id]?.lastListen
    }
    
    /// Prepares all the speakers for this project.
    @discardableResult
    private func initSpeakers() -> Promise<[Speaker]> {
        return RWFramework.sharedInstance.apiGetSpeakers([
            "project_id": String(project.id),
            "activeyn": "true"
        ]).then { speakers in
            print("playing \(speakers.count) speakers")
            self.speakers = speakers
            self.updateSpeakerVolumes()
        }
    }

    /**
     Update the volumes of all speakers depending on our proximity to each one.
     If the distance to the nearest speaker > outOfRangeDistance, then play demo stream.
    */
    private func updateSpeakerVolumes() {
        if let params = self.currentParams, let speakers = self.speakers {
            var playDemo = true
            for speaker in speakers {
                let vol = speaker.updateVolume(at: params.location)
                // Only consider playing the demo stream if all speakers are silent.
                if vol > 0.001 {
                    playDemo = false
                }
            }

            if playDemo {
                self.playDemoStream()
            } else if let ds = self.demoStream {
                ds.pause()
                NotificationCenter.default.removeObserver(demoLooper)
            }
        }
    }

    private func playDemoStream() {
        guard let params = self.currentParams,
              let speakers = self.speakers
            else { return }

        // distance to nearest point on a speaker shape
        let distToSpeaker = speakers.lazy.map {
            $0.distance(to: params.location)
        }.min() ?? 0

        print("dist to nearest speaker: \(distToSpeaker)")
        // if we're out of range, start playing from out_of_range_url
        if distToSpeaker > project.out_of_range_distance {
            print("out of range")
            RWFramework.sharedInstance.rwUpdateStatus("Out of range!")

            if demoStream == nil, let demoUrl = URL(string: project.out_of_range_url) {
                demoStream = AVPlayer(url: demoUrl)
            }

            // Only play the out-of-range stream if
            // we're a sufficient distance from all speakers
            demoStream?.play()
            if demoLooper == nil {
                demoLooper = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: demoStream!.currentItem, queue: .main) { [weak self] _ in
                    self?.demoStream?.seek(to: CMTime.zero)
                    self?.demoStream?.play()
                }
            }
        } else if let demoStream = self.demoStream {
            demoStream.pause()
        }
    }
    
    /// Picks the next-up asset to play on the given track.
    /// Applies all the playlist-level and track-level filters to make the decision.
    func next(forTrack track: AudioTrack) -> Asset? {
        let filteredAssets = self.allAssets.lazy.map { asset in
            (asset, self.filters.keep(asset, playlist: self, track: track))
        }.filter { (asset, rank) in
            rank != .discard
                // don't pick anything currently playing on another track
                && !self.currentlyPlayingAssets.contains { $0.id == asset.id }
        }
        
        let sortedAssets = filteredAssets.sorted { a, b in
            a.1.rawValue >= b.1.rawValue
        }.sorted { a, b in
            // play less played assets first
            let dataA = userAssetData[a.0.id]
            let dataB = userAssetData[b.0.id]
            if let dataA = dataA, let dataB = dataB {
                return dataA.playCount <= dataB.playCount
            } else if dataA != nil {
                return false
            } else {
                return true
            }
        }.map { (asset, rank) in asset }
        
        print("\(sortedAssets.count) filtered assets")
        
        let next = sortedAssets.first
        if let next = next {
            print("picking asset: \(next)")
        }
        return next
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

    func passesFilters(_ asset: Asset, forTrack track: AudioTrack) -> Bool {
        return self.filters.keep(asset, playlist: self, track: track) != .discard
    }
    
    private func updateTrackParams() {
        if let tracks = self.tracks, let params = self.currentParams {
            // update all tracks in parallel, in case they need to load a new track
            for t in tracks {
                Promise<Void>(on: .global()) {
                    t.updateParams(params)
                }
            }
        }
    }
    
    /// Grab the list of `AudioTrack`s for the current project.
    private func initTracks() -> Promise<Void> {
        let rw = RWFramework.sharedInstance
        
        return rw.apiGetAudioTracks([
            "project_id": String(project.id)
        ]).then { data -> () in
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
    
    /// Retrieve audio assets stored on the server.
    /// At the start of a session, gets all the assets.
    /// After that, only adds the assets uploaded since the last call of this function.
    private func updateAssets() -> Promise<Void> {
        let rw = RWFramework.sharedInstance
        
        var opts = [
            "project_id": String(project.id),
            "media_type": "audio",
            "language": "en",
            "submitted": "true"
        ]
        // Only grab assets added since the last update
        if let date = lastUpdate {
            let timeZone = RWFrameworkConfig.getConfigValueAsNumber("session_timezone", group: .session).intValue

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            dateFormatter.locale = Locale.init(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(secondsFromGMT: timeZone)
            opts["created__gte"] = dateFormatter.string(from: date)
        }

        // retrieve newly published assets
        return rw.apiGetAssets(opts).then { data -> () in
            self.allAssets.append(contentsOf: data)
            print("\(data.count) added assets")
        }.then {
            // Ensure all sort methods are setup before sorting.
            return all(self.sortMethods.map {
                $0.onRefreshAssets(in: self)
            })
        }.then { _ -> Promise<Void> in
            // Sort the asset pool.
            for sortMethod in self.sortMethods {
                self.allAssets.sort(by: { a, b in
                    sortMethod.sortRanking(for: a, in: self) < sortMethod.sortRanking(for: b, in: self)
                })
            }

            // notify filters that the asset pool is updated.
            return self.updateFilterData()
        }.catch { err in
            print(err)
        }.always {
            self.lastUpdate = Date()
        }
    }
    
    func updateFilterData() -> Promise<Void> {
        return self.filters.onUpdateAssets(playlist: self)
            .recover { err in print(err) }
    }
    
    /// Framework should call this when stream parameters are updated.
    func updateParams(_ opts: StreamParams) {
        self.currentParams = opts
        
        if let heading = opts.heading {
            self.audioMixer.listenerAngularOrientation = AVAudio3DAngularOrientation(
                yaw: Float(heading),
                pitch: 0,
                roll: 0
            )
        }
        
        if project != nil {
            self.updateParams()
        }
    }
    
    private func updateParams() {
        updateSpeakerVolumes()
        // TODO: Use a filter to clear data for assets we've moved away from.
        
        // Tell our tracks to play any new assets.
        self.updateTrackParams()
    }
    
    /// Periodically check for newly published assets
    internal func refreshAssetPool() -> Promise<Void> {
        return self.updateAssets().then {
            // Update filtered assets given any newly uploaded assets
            self.updateParams()

            let locRequested = RWFramework.sharedInstance.requestWhenInUseAuthorizationForLocation()
            print("location requested? \(locRequested)")
        }
    }
    
    func start() {
        RWFramework.sharedInstance.isPlaying = false
        
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
            self.sortMethods = [SortRandomly()]
        case "by_weight":
            self.sortMethods = [SortByWeight()]
        case "by_like":
            self.sortMethods = [SortByLikes()]
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
        
        // Start playing background music from speakers.
        let speakerUpdate = initSpeakers()
        
        // Retrieve the list of tracks
        let trackUpdate = initTracks()

        // Initial grab of assets and speakers.
        let assetsUpdate = refreshAssetPool()

        all(speakerUpdate, trackUpdate, assetsUpdate).then { _ in
            RWFramework.sharedInstance.rwStartedSuccessfully()
        }

        updateTimer = .every(.seconds(project.asset_refresh_interval)) { _ in
            self.refreshAssetPool()
        }
    }
    
    func pause() {
        if RWFramework.sharedInstance.isPlaying {
            RWFramework.sharedInstance.isPlaying = false
            speakers?.forEach { $0.pause() }
            tracks?.forEach { $0.pause() }
            if demoLooper != nil {
                demoStream?.pause()
            }
        }
    }
    
    func resume() {
        if !RWFramework.sharedInstance.isPlaying {
            RWFramework.sharedInstance.isPlaying = true
            speakers?.forEach { $0.resume() }
            tracks?.forEach { $0.resume() }
            if demoLooper != nil {
                demoStream?.play()
            }
        }
    }
    
    func skip() {
        // Fade out the currently playing assets on all tracks.
        tracks?.forEach {
            $0.playNext()
        }
    }
}


extension CLLocation {
    func bearingToLocationRadian(_ destinationLocation: CLLocation) -> Double {
        
        let lat1 = self.coordinate.latitude.degreesToRadians
        let lon1 = self.coordinate.longitude.degreesToRadians
        
        let lat2 = destinationLocation.coordinate.latitude.degreesToRadians
        let lon2 = destinationLocation.coordinate.longitude.degreesToRadians
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)
        
        return radiansBearing
    }
    
    func bearingToLocationDegrees(_ destinationLocation: CLLocation) -> Double {
        return bearingToLocationRadian(destinationLocation).radiansToDegrees
    }

    func toAudioPoint() -> AVAudio3DPoint {
        let coord = self.coordinate
        let mult = 1.0
        return AVAudio3DPoint(
            x: Float(coord.longitude * mult),
            y: 0.0,
            z: -Float(coord.latitude * mult)
        )
    }
    
    func toAudioPoint(relativeTo other: CLLocation) -> AVAudio3DPoint {
        let latCoord = CLLocation(latitude: self.coordinate.latitude, longitude: other.coordinate.longitude)
        let lngCoord = CLLocation(latitude: other.coordinate.latitude, longitude: self.coordinate.longitude)
        let latDist = latCoord.distance(from: other)
        let lngDist = lngCoord.distance(from: other)
        let latDir = (self.coordinate.latitude - other.coordinate.latitude).sign
        let latMult = latDir == .plus ? -1.0 : 1.0
        let lngDir = (self.coordinate.longitude - other.coordinate.longitude).sign
        let lngMult = lngDir == .plus ? 1.0 : -1.0
        let mult = 0.1
        return AVAudio3DPoint(
            x: Float(lngDist * lngMult * mult),
            y: 0.0,
            z: Float(latDist * latMult * mult)
        )
    }
}

extension Double {
    var degreesToRadians: Double { return self * .pi / 180 }
    var radiansToDegrees: Double { return self * 180 / .pi }
}

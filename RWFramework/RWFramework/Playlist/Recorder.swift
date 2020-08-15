import AVFoundation
import Promises

public class Recorder: Codable {
    private var uploaderTask: Promise<Void>? = nil

    private static var recorderFile: URL {
        return try! FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("recorder-\(RWFramework.projectId).json")
    }

    static func load() -> Recorder {
        var recorder: Recorder!
        if let recData = try? Data(contentsOf: Recorder.recorderFile),
            let rec = try? RWFramework.decoder.decode(Recorder.self, from: recData) {
            recorder = rec
        } else {
            recorder = Recorder()
        }
        // Remove any old dangling recording files.
//        recorder.cleanUp()
        // Start recording timer.
        RWFramework.sharedInstance.startAudioTimer()
        // Let the app know it can record now.
        RWFramework.sharedInstance.rwReadyToRecord()
        return recorder
    }

    internal func save() {
        do {
            try (try RWFramework.encoder.encode(self)).write(to: Recorder.recorderFile)
        } catch {
            print(error)
        }
    }

    /** Launches a background task to upload any pending recordings. */
    func uploadPending() -> Promise<Void> {
        let rwf = RWFramework.sharedInstance
        print("recorder: uploading pending, \(pendingEnvelopes.debugDescription)")
        if rwf.reachability.connection == .unavailable {
            rwf.rwRecordedOffline()
            return Promise(())
        } else if uploaderTask != nil || pendingEnvelopes.count == 0 {
            // We've already got an upload going.
            return Promise(())
        } else {
            rwf.rwUploadResumed()
            uploaderTask = Promise<Void>(on: .global()) {
                let totalCount = self.pendingEnvelopes.count
                var currentAttempts = 0
                while !self.pendingEnvelopes.isEmpty, currentAttempts < 3 {
                    // Give every envelope a few chances to upload.
                    var toRemove = [Int]()
                    for (i, envelope) in self.pendingEnvelopes.enumerated() {
                        if self.isReachable(envelope: envelope) {
                            // Upload this envelope.
                            do {
                                _ = try await(self.upload(envelope: envelope))
                                // Remove it from the queue.
                                toRemove.append(i)
                            } catch {
                                print(error)
                            }
                        } else {
                            // TODO Hook for alert that the file is missing.
                            toRemove.append(i)
                        }
                        // Show progress update.
                        let uploadedCount = totalCount - (self.pendingEnvelopes.count - toRemove.count)
                        RWFramework.sharedInstance.rwUploadProgress(Double(uploadedCount) / Double(totalCount))
                        // Update the badge.
                        self.updateBadge()
                    }
                    for i in toRemove {
                        self.pendingEnvelopes.remove(at: i)
                    }
                    self.save()
                    currentAttempts += 1
                }
            }.always {
                self.uploaderTask = nil
            }
            return uploaderTask!
        }
    }

    func stopUpload() {
        if let task = uploaderTask {
            // task.reject("Stopped" as! Error)
        }
    }

    /** Upload a single envelope that may contain multiple assets. */
    private func upload(envelope: Envelope) -> Promise<Void> {
        print("recorder: upload single envelope")
        let rw = RWFramework.sharedInstance
        return Promise<Void> {
            // If the envelope has no id yet, then create it on the server.
            if envelope.id == nil {
                envelope.id = try await(rw.apiPostEnvelopes())
                for m in envelope.media {
                    m.envelopeID = envelope.id!
                }
            }
            // create and store sharing url for current envelope
            // FIXME: Not sure what this sharing url is used for!
            let sharingUrl = RWFrameworkConfig.getConfigValueAsString("sharing_url", group: RWFrameworkConfig.ConfigGroup.project)
            let currentSharingUrl = sharingUrl + "?eid=" + envelope.id!.description
            RWFrameworkConfig.setConfigValue("sharing_url_current", value: currentSharingUrl as AnyObject, group: RWFrameworkConfig.ConfigGroup.project)

            // Upload each media item to the envelope.
            _ = try await(all(envelope.media.map { m in self.upload(media: m) }))
            // Refresh the asset pool to pull in this new asset.
            _ = try await(RWFramework.sharedInstance.playlist.refreshAssetPool())
        }
    }
    
    private func isReachable(envelope: Envelope) -> Bool {
        return envelope.media.contains { m in
            (try? recordingPath(for: m.string).checkResourceIsReachable()) ?? false
        }
    }

    internal var recordingsDir: URL {
        return try! FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
    }

    /** Path of the given recording name as saved on disk. */
    internal func recordingPath(for name: String) -> URL {
        return recordingsDir.appendingPathComponent(name)
    }

    private var recordingIndex: Int?
    /** List of recorded audio files to upload as assets. */
    private var pendingEnvelopes = [Envelope]()
    internal var currentMedia = [RWFramework.Media]()
    public private(set) var soundRecorder: AVAudioRecorder? = nil
    private enum CodingKeys: String, CodingKey {
        case recordingIndex, pendingEnvelopes, currentMedia
    }

    class Envelope: Codable {
        /** The id is only nil before this envelope is created on the server. */
        var id: Int? = nil
        // let key: String
        let media: [RWFramework.Media]

        init( /* key: String, */ media: [RWFramework.Media]) {
            // self.key = key
            self.media = media
        }
    }

    internal var currentRecordingName: String {
        return "recording-\(RWFramework.projectId)-\(recordingIndex ?? 0).m4a"
    }

    internal var hasRecording: Bool {
        return (try? recordingPath(for: currentRecordingName).checkResourceIsReachable()) ?? false
    }

    /** Start recording audio. */
    public func startRecording() {
        recordingIndex = (recordingIndex ?? 0) + 1
        save()
        let soundFileUrl = recordingPath(for: currentRecordingName)
        print("recorder: start recording for \(soundFileUrl.description)")
        let recordSettings =
            [AVSampleRateKey: 22050,
             AVFormatIDKey: kAudioFormatMPEG4AAC,
             AVNumberOfChannelsKey: 1,
             AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue] as [String: Any]

        do {
//            try FileManager.default.createDirectory(at: soundFileUrl.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
//            FileManager.default.createFile(atPath: soundFileUrl.absoluteString, contents: nil, attributes: nil)
            soundRecorder = try AVAudioRecorder(url: soundFileUrl, settings: recordSettings)
            soundRecorder!.delegate = RWFramework.sharedInstance
            let prepSuccess = soundRecorder!.prepareToRecord()
            print("recorder: prep? \(prepSuccess)")
            soundRecorder!.isMeteringEnabled = true
            let maxRecordingLength = RWFrameworkConfig.getConfigValueAsNumber("max_recording_length")
            let success = soundRecorder!.record(forDuration: maxRecordingLength.doubleValue)
            print("recorder: started? \(success)")
        } catch {
            print("recorder RWFramework - Couldn't create AVAudioRecorder \(error)")
        }

        print("recorder: isrecording = \(isRecording)")
    }

    public func stopRecording() {
        print("recorder: stop")
        soundRecorder?.stop()
        soundRecorder = nil
    }

    /**
     Add the most recent recording to the next envelope to upload.
     */
    public func addRecording(_ description: String = "") -> URL? {
        if !hasRecording { return nil }

        let recordedFilePath = recordingPath(for: currentRecordingName)
        print("addRecording path: \(recordedFilePath)")
        let loc = RWFramework.sharedInstance.lastRecordedLocation

        currentMedia.append(RWFramework.Media(
            mediaType: RWFramework.MediaType.Audio,
            string: currentRecordingName,
            description: description,
            location: loc,
            tagIDs: RWFramework.sharedInstance.getSubmittableSpeakIDsSetAsTags()
        ))
        save()
        print("recorder: added media with tags \(currentMedia.last!.tagIDs.description)")

        return recordedFilePath
    }

    internal func addMedia(_ media: RWFramework.Media) {
        if !hasMedia(type: media.mediaType, text: media.string) {
            currentMedia.append(media)
        }
    }

    internal func hasMedia(type: RWFramework.MediaType, text: String? = nil) -> Bool {
        return currentMedia.contains { m in
            m.mediaType == type && (text == nil || m.string == text!)
        }
    }

    internal func setMediaDescription(_ type: RWFramework.MediaType, _ string: String, _ description: String) {
        for media in currentMedia {
            if media.mediaType == type, media.string == string {
                media.desc = description
                return
            }
        }
    }

    /// Remove the specific piece of media from the mediaArray
    func removeMedia(_ media: RWFramework.Media) {
        currentMedia = currentMedia.filter { $0.desc != media.desc }
    }

    /// Remove a MediaType by type and string
    func removeMedia(_ mediaType: RWFramework.MediaType, string: String) {
        if hasMedia(type: mediaType, text: string) {
            currentMedia = currentMedia.filter {
                "\($0.mediaType.rawValue)\($0.string)" != "\(mediaType.rawValue)\(string)"
            }
        }
    }

    /// Remove a MediaType by type
    func removeMedia(_ mediaType: RWFramework.MediaType) {
        if hasMedia(type: mediaType) {
            currentMedia = currentMedia.filter { $0.mediaType != mediaType }
        }
    }

    public var lastRecordingPath: URL {
        return recordingPath(for: currentRecordingName)
    }

    public var isRecording: Bool {
        return soundRecorder != nil
    }
    
    private func updateBadge() {
        let assetCount = pendingEnvelopes.reduce(0) { sum, e in sum + e.media.count }
        RWFramework.sharedInstance.rwUpdateApplicationIconBadgeNumber(assetCount)
    }

    public func submitEnvelopeForUpload( /* _ key: String */ ) {
        print("recorder: submit envelope")
        pendingEnvelopes.append(Envelope( /* key: key, */ media: currentMedia))
        // Update the badge.
        updateBadge()
        // Try uploading any pending recordings.
        currentMedia = []
        save()
        _ = uploadPending()
    }

    /** Delete local recordings that have been uploaded or discarded. */
    internal func cleanUp() {
        // We never, ever want to delete a file being written to.
        if isRecording || !currentMedia.isEmpty || !pendingEnvelopes.isEmpty {
            return
        }
        do {
            let dir = recordingsDir
            let items = try FileManager.default.contentsOfDirectory(atPath: dir.path)
            for file in items {
                print("recorder: Removing \(file)")
                let path = dir.appendingPathComponent(file).path
                try FileManager.default.removeItem(atPath: path)
            }
        } catch {
            print("recorder: \(error)")
        }
    }

    /// Upload the passed media, after multiple attempts to upload a file will not be attempted further. See countUploadFailedMedia and purgeUploadFailedMedia to manage those failures
    func upload(media: RWFramework.Media) -> Promise<Void> {
        print("recorder: upload media")
        let rw = RWFramework.sharedInstance
        media.mediaStatus = RWFramework.MediaStatus.Uploading

        let bti = UIApplication.shared.beginBackgroundTask(withName: "RWFramework_uploadMedia", expirationHandler: { () -> Void in
            // last ditch effort
            // self.logToServer("upload_failed", data: "RWFramework_uploadMedia background task expired.")
            print("RWFramework couldn't finish uploading in time.")
        })

        // Upload the asset by patching the envelope.x
        return rw.apiPatchEnvelopesId(media).then { () -> Void in
            print("recorder apiPatchEnvelopesId success")
            media.mediaStatus = RWFramework.MediaStatus.UploadCompleted
            UIApplication.shared.endBackgroundTask(bti)
            // Remove the local file.
            let fm = FileManager.default
            if let _ = try? fm.removeItem(at: self.recordingPath(for: media.string)) {
            } else {
                _ = try? fm.removeItem(atPath: media.string)
            }
        }.catch { (error: Error) -> Void in
            let error = error as NSError
            print("recorder apiPatchEnvelopesId failure \(error)")
            if error.code == 400 {
                // self.deleteMediaFile(media)
                // self.removeMedia(media)
            } else {
                media.mediaStatus = RWFramework.MediaStatus.UploadFailed
                media.retryCount += 1
            }
            UIApplication.shared.endBackgroundTask(bti)
        }
    }
}

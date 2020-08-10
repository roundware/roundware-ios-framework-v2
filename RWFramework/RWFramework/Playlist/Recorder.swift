import AVFoundation
import Promises
import Reachability

public class Recorder: Codable {
    private var reachability: Reachability!
    private var uploaderTask: Promise<Void>? = nil
    
    internal func setupReachability() {
        do {
            reachability = try Reachability()
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.reachabilityChanged(_:)),
                name: Notification.Name.reachabilityChanged,
                object: reachability
            )
            try reachability.startNotifier()
        } catch {
            print("recorder: \(error)")
        }
    }
    
    @objc func reachabilityChanged(_ note: NSNotification) {
        let reachability = note.object as! Reachability
        if reachability.connection != .unavailable {
            if pendingEnvelopes.count > 0 {
                RWFramework.sharedInstance.rwUploadResumed()
            }
            _ = uploadPending()
            if reachability.connection == .wifi {
                print("recorder: Reachable via WiFi")
            } else {
                print("recorder: Reachable via Cellular")
            }
        } else {
            print("recorder: Not reachable")
        }
    }

    /** Launches a background task to upload any pending recordings. */
    func uploadPending() -> Promise<Void> {
        if reachability.connection == .unavailable {
            RWFramework.sharedInstance.rwRecordedOffline()
            return Promise(())
        } else if uploaderTask != nil || pendingEnvelopes.count == 0 {
            // We've already got an upload going.
            return Promise(())
        } else {
            print("recorder: uploading pending, \(pendingEnvelopes.debugDescription)")
            uploaderTask = Promise<Void>(on: .global()) {
                let totalCount = self.pendingEnvelopes.count
                while !self.pendingEnvelopes.isEmpty {
                    // Upload this envelope.
                    _ = try await(self.upload(envelope: self.pendingEnvelopes[0]))
                    // Remove it from the queue.
                    self.pendingEnvelopes.remove(at: 0)
                    // Show progress update.
                    let uploadedCount = totalCount - self.pendingEnvelopes.count
                    RWFramework.sharedInstance.rwUploadProgress(Double(uploadedCount) / Double(totalCount))
                }
            }.always {
                self.uploaderTask = nil
            }
            return uploaderTask!
        }
    }

    func stopUpload() {
        if let task = uploaderTask {
            //task.reject("Stopped" as! Error)
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
            // FIXME: each media needs the envelope id
            // for media in envelope.media {
            //     if media.mediaStatus == RWFramework.MediaStatus.Hold {
            //         media.envelopeID = envelopeID
            //     }
            // }
            // create and store sharing url for current envelope
            // FIXME: Not sure what this sharing url is used for!
            let sharingUrl = RWFrameworkConfig.getConfigValueAsString("sharing_url", group: RWFrameworkConfig.ConfigGroup.project)
            let currentSharingUrl = sharingUrl + "?eid=" + envelope.id!.description
            RWFrameworkConfig.setConfigValue("sharing_url_current", value: currentSharingUrl as AnyObject, group: RWFrameworkConfig.ConfigGroup.project)

            // Upload each media item to the envelope.
            _ = try await(all(envelope.media.map { m in self.upload(media: m) }))
            // Refresh the asset pool to pull in this new asset.
            _ = try await(RWFramework.sharedInstance.playlist.refreshAssetPool())
        }.recover { error in
            print("recorder: \(error)")
        }
    }
    
    private var recordingsDir: URL {
        let parent = try! FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return parent.appendingPathComponent("recordings-\(Playlist.projectId)")
    }

    /** Path of the given recording name as saved on disk. */
    private func recordingPath(for name: String) -> URL {
        return recordingsDir.appendingPathComponent(name)
    }

    private var recordingIndex: Int = 0
    /** List of recorded audio files to upload as assets. */
    private var pendingEnvelopes = [Envelope]() {
        didSet {
            RWFramework.sharedInstance.rwUpdateApplicationIconBadgeNumber(pendingEnvelopes.count)
        }
    }
    internal var currentMedia = [RWFramework.Media]()
    internal var soundRecorder: AVAudioRecorder? = nil
    private enum CodingKeys: String, CodingKey {
        case recordingIndex, pendingEnvelopes, currentMedia
    }

    class Envelope: Codable {
        /** The id is only nil before this envelope is created on the server. */
        var id: Int? = nil
        // let key: String
        let media: [RWFramework.Media]

        init(/*key: String,*/ media: [RWFramework.Media]) {
            // self.key = key
            self.media = media
        }
    }

    private var currentRecordingName: String {
        return "recording-\(recordingIndex).m4a"
    }

    private var nextRecordingName: String {
        recordingIndex += 1
        return currentRecordingName
    }
    
    internal var hasRecording: Bool {
        return (try? recordingPath(for: currentRecordingName).checkResourceIsReachable()) ?? false
    }

    /** Start recording audio. */
    public func startRecording() {
        let soundFileUrl = recordingPath(for: nextRecordingName)
        print("recorder: start recording for \(soundFileUrl.description)")
        let recordSettings =
            [AVSampleRateKey: 22050,
             AVFormatIDKey: kAudioFormatMPEG4AAC,
             AVNumberOfChannelsKey: 1,
             AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue] as [String: Any]

        do {
            try FileManager.default.createDirectory(at: soundFileUrl.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
            FileManager.default.createFile(atPath: soundFileUrl.absoluteString, contents: nil, attributes: nil)
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
        // if (hasRecording() == false) { return key }

        let recordedFilePath = recordingPath(for: currentRecordingName)
        print("addRecording path: \(recordedFilePath)")
        let loc = RWFramework.sharedInstance.lastRecordedLocation

        currentMedia.append(RWFramework.Media(
            mediaType: RWFramework.MediaType.Audio,
            string: recordedFilePath.path,
            description: description,
            location: loc,
            tagIDs: RWFramework.sharedInstance.getSubmittableSpeakIDsSetAsTags(),
            userID: RWFrameworkConfig.getConfigValueAsNumber("user_id", group: RWFrameworkConfig.ConfigGroup.client).intValue
        ))
        print("recorder: added media with tags \(currentMedia.last!.tagIDs.description)")

        return recordedFilePath
    }

    public var lastRecordingPath: URL {
        return recordingPath(for: currentRecordingName)
    }

    public var isRecording: Bool {
        return soundRecorder != nil
    }
    
    public func submitEnvelopeForUpload(/*_ key: String*/) {
        print("recorder: submit envelope")
        self.pendingEnvelopes.append(Envelope(/*key: key,*/ media: self.currentMedia))
        self.currentMedia = []
        _ = uploadPending()
    }
    
    /** Delete local recordings that have been uploaded or discarded. */
    internal func cleanUp() {
        // We never, ever want to delete a file being written to.
        if isRecording {
            return
        }
        do {
            let dir = recordingsDir
            let items = try FileManager.default.contentsOfDirectory(atPath: dir.path)
            for file in items {
                let path = dir.appendingPathComponent(file).path
                let inCurrent = currentMedia.contains { m in m.string.contains(file) }
                let inPending = pendingEnvelopes.contains { e in e.media.contains { m in m.string.contains(file) } }
                if !inCurrent && !inPending {
                    print("recorder: Removing \(file)")
                    try FileManager.default.removeItem(atPath: path)
                }
            }
        } catch {
            print("recorder: \(error)")
        }
    }

    /// Upload the passed media, after multiple attempts to upload a file will not be attempted further. See countUploadFailedMedia and purgeUploadFailedMedia to manage those failures
    func upload(media: RWFramework.Media) -> Promise<Void> {
        print("recorder: upload media")
        let rw = RWFramework.sharedInstance
        // media.mediaStatus = MediaStatus.Uploading

        let bti = UIApplication.shared.beginBackgroundTask(withName: "RWFramework_uploadMedia", expirationHandler: { () -> Void in
            // last ditch effort
            // self.logToServer("upload_failed", data: "RWFramework_uploadMedia background task expired.")
            print("RWFramework couldn't finish uploading in time.")
        })

        // Upload the asset by patching the envelope.x
        return rw.apiPatchEnvelopesId(media).then { () -> Void in
            print("recorder apiPatchEnvelopesId success")
            // media.mediaStatus = MediaStatus.UploadCompleted
            UIApplication.shared.endBackgroundTask(bti)
        }.catch { (error: Error) -> Void in
            let error = error as NSError
            print("recorder apiPatchEnvelopesId failure \(error)")
            if error.code == 400 {
                // self.deleteMediaFile(media)
                // self.removeMedia(media)
            } else {
                // media.mediaStatus = MediaStatus.UploadFailed
                media.retryCount += 1
            }
            UIApplication.shared.endBackgroundTask(bti)
        }
    }
}

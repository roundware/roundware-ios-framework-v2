//
//  RWFrameworkMedia.swift
//  RWFramework
//
//  Created by Joe Zobkiw on 2/6/15.
//  Copyright (c) 2015 Roundware. All rights reserved.
//

import CoreLocation
import Foundation

extension RWFramework {
    func mapMediaTypeToServerMediaType(_ mediaType: MediaType) -> ServerMediaType {
        switch mediaType {
        case .Audio:
            return ServerMediaType.Audio
        case .Text:
            return ServerMediaType.Text
        case .Image:
            return ServerMediaType.Photo
        case .Movie:
            return ServerMediaType.Video
        case .None:
            return ServerMediaType.None
        }
    }

    /// These are the media type names that the server expects
    enum ServerMediaType: String, CaseIterable {
        case None = "none"
        case Audio = "audio"
        case Text = "text"
        case Photo = "photo"
        case Video = "video"
    }

    /// These are the media type names that make the most sense for the iOS platform
    enum MediaType: String, CaseIterable, Codable {
        case None
        case Audio
        case Text
        case Image
        case Movie
    }

    enum MediaStatus: String, CaseIterable, Codable {
        case None
        case Hold
        case Ready
        case Uploading
        case UploadFailed
        case UploadCompleted
    }

    class Media: Codable {
        let mediaType: MediaType
        var mediaStatus: MediaStatus
        /**
         Plain text for MediaType.Text, file path for MediaType.Audio,
         MediaType.Image and MediaType.Movie
         */
        let string: String
        var desc: String
        let latitude: Double
        let longitude: Double
        var tagIDs: String
        var userID: Int
        var envelopeID: Int = 0
        var retryCount: Int = 0
        
        enum CodingKeys: String, CodingKey {
            // Don't persist retry count between launches
            case mediaType, mediaStatus, string, desc, latitude, longitude, tagIDs, userID, envelopeID
        }

        init(mediaType: MediaType, string: String, description: String, location: CLLocation, tagIDs: String, userID: Int) {
             self.mediaType = mediaType
             mediaStatus = MediaStatus.Hold
             self.string = string
             desc = description
             latitude = location.coordinate.latitude
             longitude = location.coordinate.longitude
            self.tagIDs = tagIDs
            self.userID = userID
         }
    }

    /// Loads the array of media from NSUserDefaults during framework initialization.
    /// The array is stored to NSUserDefaults via its willSet
    func loadMediaArray() -> [Media] {
        if let mediaArrayData: Data = RWFrameworkConfig.getConfigValue("mediaArray", group: RWFrameworkConfig.ConfigGroup.client) as? Data {
            if let a = NSKeyedUnarchiver.unarchiveObject(with: mediaArrayData) {
                var b = a as! [Media]
                for item in b {
                    // validate existence of file at path and delete if doesn't exist
                    var n = 0
                    let filePath = item.string as String
                    let url = URL(string: filePath)
                    if FileManager.default.fileExists(atPath: url!.path) {
                        print("file in media queue exists")
                    } else {
                        print("file in media queue doesn't exist; deleting media queue item: \(n)")
                        b.remove(at: n)
                    }
                    n += 1
                }
                println("POST validation: loadMediaArray loaded \(b.count) items")
                return b
            }
        }
        return [Media]()
    }

    // MARK: media upload management

    /// Called to take all media on hold and prepare it for upload by enveloping, etc.
    /// Mark all media on MediaStatus.Hold as MediaStatus.Ready and add current speak tags and envelope ID (called from apiPostEnvelopesSuccess)
    public func uploadAllMedia() {
        self.playlist.recorder!.submitEnvelopeForUpload()
    }

    /// Reset any retryCounts for failed uploads, effectively making them try again, can be called at application startup
    public func resetAllRetryCounts() {
        // NOTE Should not be needed anymore.
//        for media: Media in mediaArray {
//            if media.mediaStatus == MediaStatus.UploadFailed {
//                media.retryCount = 0
//            }
//        }
    }

    // MARK: failed

    /// Return a count of all media that has failed to upload at least once
    public func countUploadFailedMedia() -> Int {
//        let found = mediaArray.filter { m in m.mediaStatus == MediaStatus.UploadFailed }
//        return found.count
        print("recorder: count failed media")
        return 0
    }

    /// Purge all media that has failed to upload at least once
    public func purgeUploadFailedMedia() {
//        let newArray = mediaArray.filter { $0.mediaStatus != MediaStatus.UploadFailed }
//        mediaArray = newArray
        println("recorder purgeUploadFailedMedia")
    }

    // MARK: add

    /// Add a MediaType to the array
    func addMedia(_ mediaType: MediaType, string: String) {
//        if mediaExists(mediaType, string: string) { return }
//        let media = Media(mediaType: mediaType, string: string, description: "", location: lastRecordedLocation, tagIDs: "", userID: 0)
//        mediaArray.append(media)
        println("recorder addMedia: \(mediaType.rawValue) \(string)")
    }

    /// Add a MediaType to the array with description
    func addMedia(_ mediaType: MediaType, string: String, description: String) {
//        if mediaExists(mediaType, string: string) { return }
//        let media = Media(mediaType: mediaType, string: string, description: description, location: lastRecordedLocation, tagIDs: "", userID: 0)
//        mediaArray.append(media)
        println("recorder addMedia: \(mediaType.rawValue) \(string)")
    }

    // MARK: exists

    /// Return true if media is already in the array based on type and string
//    func mediaExists(_ mediaType: MediaType, string: String) -> Bool {
//        let found = mediaArray.filter { m in m.mediaType == mediaType && m.string == string }
//        return found.count > 0
//    }

    /// Return true if media is already in the array based on type and string
//    func mediaExists(_ mediaType: MediaType) -> Bool {
//        let found = mediaArray.filter { m in m.mediaType == mediaType }
//        return found.count > 0
//    }

    // MARK: edit

    /// Set a description on an existing media item
    func setMediaDescription(_ mediaType: MediaType, string: String, description: String) {
        print("recorder: set media desc")
//        for media in mediaArray {
//            if media.mediaType == mediaType, media.string == string {
//                media.desc = description
//                return
//            }
//        }
    }

    // MARK: remove

    // TODO: Do not remove media.mediaStatus if currently being pre-processed or uploaded

    /// Remove the specific piece of media from the mediaArray
    func removeMedia(_ media: Media) {
//        let newArray = mediaArray.filter { "\($0.desc)" != "\(media.desc)" }
//        mediaArray = newArray
        print("recorder removeMedia: \(media)")
    }

    /// Remove a MediaType by type and string
    func removeMedia(_ mediaType: MediaType, string: String) {
//        if !mediaExists(mediaType, string: string) { return }
//        let newArray = mediaArray.filter { "\($0.mediaType.rawValue)\($0.string)" != "\(mediaType.rawValue)\(string)" }
//        mediaArray = newArray
        print("recorder removeMedia: \(mediaType.rawValue) \(string)")
    }

    /// Remove a MediaType by type
    func removeMedia(_ mediaType: MediaType) {
//        if !mediaExists(mediaType) { return }
//        let newArray = mediaArray.filter { $0.mediaType.rawValue != mediaType.rawValue }
//        mediaArray = newArray
        println("recorder removeMedia: \(mediaType.rawValue)")
    }

    // MARK: count

    /// Return the number of media in the array
    public func countMedia() -> Int {
        return playlist.recorder!.currentMedia.count
    }

    /// Return the number of types of media in the array of a specific type
    func countMedia(_ mediaType: MediaType) -> Int {
//        var count = 0
//        for media: Media in mediaArray {
//            if media.mediaType == mediaType {
//                count += 1
//            }
//        }
//        return count
        print("recorder: count media")
        return 0
    }
}

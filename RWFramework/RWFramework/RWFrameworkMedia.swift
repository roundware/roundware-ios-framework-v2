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

        init(mediaType: MediaType, string: String, description: String, location: CLLocation = RWFramework.sharedInstance.lastRecordedLocation, tagIDs: String? = nil) {
            self.mediaType = mediaType
            mediaStatus = MediaStatus.Ready
            self.string = string
            desc = description
            latitude = location.coordinate.latitude
            longitude = location.coordinate.longitude
            userID = RWFrameworkConfig.getConfigValueAsNumber("user_id", group: RWFrameworkConfig.ConfigGroup.client).intValue
            self.tagIDs = tagIDs ?? RWFramework.sharedInstance.getSubmittableSpeakIDsSetAsTags()
        }
    }

    // MARK: media upload management

    /// Called to take all media on hold and prepare it for upload by enveloping, etc.
    /// Mark all media on MediaStatus.Hold as MediaStatus.Ready and add current speak tags and envelope ID (called from apiPostEnvelopesSuccess)
    public func uploadAllMedia() {
        recorder.submitEnvelopeForUpload()
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

    // MARK: count

    /// Return the number of media in the array
    public func countMedia() -> Int {
        return recorder.currentMedia.count
    }
}

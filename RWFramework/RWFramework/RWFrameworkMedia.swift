//
//  RWFrameworkMedia.swift
//  RWFramework
//
//  Created by Joe Zobkiw on 2/6/15.
//  Copyright (c) 2015 Roundware. All rights reserved.
//

import Foundation
import CoreLocation

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
    enum ServerMediaType: String {
        case None = "none"
        case Audio = "audio"
        case Text = "text"
        case Photo = "photo"
        case Video = "video"

        static let allValues = [None, Audio, Text, Photo, Video]
    }

    /// These are the media type names that make the most sense for the iOS platform
    enum MediaType: String {
        case None = "None"
        case Audio = "Audio"
        case Text = "Text"
        case Image = "Image"
        case Movie = "Movie"

        static let allValues = [None, Audio, Text, Image, Movie]
    }

    enum MediaStatus: String {
        case None = "None"
        case Hold = "Hold"
        case Ready = "Ready"
        case Uploading = "Uploading"
        case UploadFailed = "UploadFailed"
        case UploadCompleted = "UploadCompleted"

        static let allValues = [None, Hold, Ready, Uploading, UploadFailed, UploadCompleted]
    }

    @objc(RWMedia)class Media: NSObject, NSCoding {
        var mediaType: MediaType = MediaType.None
        var mediaStatus: MediaStatus = MediaStatus.None
        var string: String = ""     // plain text for MediaType.Text, file path for MediaType.Audio, MediaType.Image and MediaType.Movie
        var desc: String = ""
        var latitude: NSNumber = 0
        var longitude: NSNumber = 0
        var tagIDs: String = ""
        var envelopeID: NSNumber = 0
        var retryCount: NSNumber = 0

        init(mediaType: MediaType, string: String, location: CLLocation) {
            self.mediaType = mediaType
            self.mediaStatus = MediaStatus.Hold
            self.string = string
            self.latitude = NSNumber(value: location.coordinate.latitude)
            self.longitude = NSNumber(value: location.coordinate.longitude)
        }

        init(mediaType: MediaType, string: String, description: String, location: CLLocation) {
            self.mediaType = mediaType
            self.mediaStatus = MediaStatus.Hold
            self.string = string
            self.desc = description
            self.latitude = NSNumber(value: location.coordinate.latitude)
            self.longitude = NSNumber(value: location.coordinate.longitude)
        }

        required init(coder aDecoder: NSCoder) {
            mediaType = MediaType.allValues[aDecoder.decodeInteger(forKey: "mediaType")]
            mediaStatus = MediaStatus.allValues[aDecoder.decodeInteger(forKey: "mediaStatus")]
            string = aDecoder.decodeObject(forKey: "string") as! String
            desc = aDecoder.decodeObject(forKey: "desc") as! String
            latitude = aDecoder.decodeObject(forKey: "latitude") as! NSNumber
            longitude = aDecoder.decodeObject(forKey: "longitude") as! NSNumber
            tagIDs = aDecoder.decodeObject(forKey: "tagIDs") as! String
            envelopeID = aDecoder.decodeObject(forKey: "envelopeID") as! NSNumber
            retryCount = aDecoder.decodeObject(forKey: "retryCount") as! NSNumber
        }

        func encode(with aCoder: NSCoder) {
            aCoder.encode(MediaType.allValues.index(of: mediaType)!, forKey: "mediaType")
            aCoder.encode(MediaStatus.allValues.index(of: mediaStatus)!, forKey: "mediaStatus")
            aCoder.encode(string, forKey: "string")
            aCoder.encode(desc, forKey: "desc")
            aCoder.encode(latitude, forKey: "latitude")
            aCoder.encode(longitude, forKey: "longitude")
            aCoder.encode(tagIDs, forKey: "tagIDs")
            aCoder.encode(envelopeID, forKey: "envelopeID")
            aCoder.encode(retryCount, forKey: "retryCount")
        }
    }

    /// Loads the array of media from NSUserDefaults during framework initialization.
    /// The array is stored to NSUserDefaults via its willSet
    func loadMediaArray() -> Array<Media> {
        if let mediaArrayData: Data = RWFrameworkConfig.getConfigValue("mediaArray", group: RWFrameworkConfig.ConfigGroup.client) as? Data {
            if let a = NSKeyedUnarchiver.unarchiveObject(with: mediaArrayData) {
                var b = a as! Array<Media>
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
        return Array<Media>()
    }

// MARK: media upload management

    /// Called to take all media on hold and prepare it for upload by enveloping, etc.
    /// Mark all media on MediaStatus.Hold as MediaStatus.Ready and add current speak tags and envelope ID (called from apiPostEnvelopesSuccess)
    public func uploadAllMedia() {
        if (countMedia() == 0) { return }
        apiPostEnvelopes().then { (envelopeID: Int) -> Void in
            for media: Media in self.mediaArray {
                if media.mediaStatus == MediaStatus.Hold {
                    media.envelopeID = NSNumber(value: envelopeID)
                    media.tagIDs = self.getSubmittableSpeakIDsSetAsTags() //self.getAllSpeakTagsCurrentAsString() // the old way
                    media.mediaStatus = MediaStatus.Ready
                }
            }
            // create and store sharing url for current envelope
            let sharingUrl = RWFrameworkConfig.getConfigValueAsString("sharing_url")
            let currentSharingUrl = sharingUrl + "?eid=" + String(envelopeID)
            RWFrameworkConfig.setConfigValue("sharing_url_current", value: currentSharingUrl as AnyObject, group: RWFrameworkConfig.ConfigGroup.project)
        }
    }

    /// Reset any retryCounts for failed uploads, effectively making them try again, can be called at application startup
    public func resetAllRetryCounts() {
        for media: Media in self.mediaArray {
            if media.mediaStatus == MediaStatus.UploadFailed {
                media.retryCount = 0
            }
        }
    }

// MARK: failed

    /// Return a count of all media that has failed to upload at least once
    public func countUploadFailedMedia() -> Int {
        let found = mediaArray.filter({m in m.mediaStatus == MediaStatus.UploadFailed})
        return found.count
    }

    /// Purge all media that has failed to upload at least once
    public func purgeUploadFailedMedia() {
        let newArray = mediaArray.filter() {$0.mediaStatus != MediaStatus.UploadFailed}
        self.mediaArray = newArray
        println("purgeUploadFailedMedia: ITEMS: \(mediaArray.count)")
    }

// MARK: add

    /// Add a MediaType to the array
    func addMedia(_ mediaType: MediaType, string: String) {
        if mediaExists(mediaType, string: string) { return }
        let media = Media(mediaType: mediaType, string: string, location: lastRecordedLocation)
        self.mediaArray.append(media)
        println("addMedia: \(mediaType.rawValue) \(string) ITEMS: \(mediaArray.count)")
    }

    /// Add a MediaType to the array with description
    func addMedia(_ mediaType: MediaType, string: String, description: String) {
        if mediaExists(mediaType, string: string) { return }
        let media = Media(mediaType: mediaType, string: string, description: description, location: lastRecordedLocation)
        self.mediaArray.append(media)
        println("addMedia: \(mediaType.rawValue) \(string) ITEMS: \(mediaArray.count)")
    }

// MARK: exists

    /// Return true if media is already in the array based on type and string
    func mediaExists(_ mediaType: MediaType, string: String) -> Bool {
        let found = mediaArray.filter({m in m.mediaType == mediaType && m.string == string})
        return found.count>0
    }

    /// Return true if media is already in the array based on type and string
    func mediaExists(_ mediaType: MediaType) -> Bool {
        let found = mediaArray.filter({m in m.mediaType == mediaType})
        return found.count>0
    }

// MARK: edit

    /// Set a description on an existing media item
    func setMediaDescription(_ mediaType: MediaType, string: String, description: String) {
        for media in mediaArray {
            if media.mediaType == mediaType && media.string == string {
                media.desc = description
                return
            }
        }
    }

// MARK: remove

    // TODO: Do not remove media.mediaStatus if currently being pre-processed or uploaded

    /// Remove the specific piece of media from the mediaArray
    func removeMedia(_ media: Media) {
        let newArray = mediaArray.filter() {"\($0.description)" != "\(media.description)"}
        self.mediaArray = newArray
        println("removeMedia: \(media) ITEMS: \(mediaArray.count)")
    }

    /// Remove a MediaType by type and string
    func removeMedia(_ mediaType: MediaType, string: String) {
        if (!mediaExists(mediaType, string: string)) { return }
        let newArray = mediaArray.filter() {"\($0.mediaType.rawValue)\($0.string)" != "\(mediaType.rawValue)\(string)"}
        self.mediaArray = newArray
        println("removeMedia: \(mediaType.rawValue) \(string) ITEMS: \(mediaArray.count)")
    }

    /// Remove a MediaType by type
    func removeMedia(_ mediaType: MediaType) {
        if (!mediaExists(mediaType)) { return }
        let newArray = mediaArray.filter() {$0.mediaType.rawValue != mediaType.rawValue}
        self.mediaArray = newArray
        println("removeMedia: \(mediaType.rawValue) ITEMS: \(mediaArray.count)")
    }

// MARK: count

    /// Return the number of media in the array
    public func countMedia() -> Int {
        return mediaArray.count
    }

    /// Return the number of types of media in the array of a specific type
    func countMedia(_ mediaType: MediaType) -> Int {
        var count = 0
        for media: Media in mediaArray {
            if media.mediaType == mediaType {
                count += 1
            }
        }
        return count
    }
}

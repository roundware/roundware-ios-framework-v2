//
//  RWFrameworkMediaUploader.swift
//  RWFramework
//
//  Created by Joe Zobkiw on 3/4/15.
//  Copyright (c) 2015 Roundware. All rights reserved.
//

import Foundation
import AVFoundation

extension RWFramework {

    /// Maximum number of times to try re-uploading beore we skip an item
    var mediaRetryLimit: NSNumber {
        get { return 3 }
    }

// MARK: Entry

    /// Handles kicking off the upload of the skip available item in the queue
    func mediaUploader() {
        if (uploaderActive == false) { return }
        if (uploaderUploading == true) { return }
        uploaderUploading = true

        let media = getMediaToProcess()
        if (media != nil) {
            self.uploadMedia(media: media!)
        } else {
            self.uploaderUploading = false
        }
    }

// MARK: Iterator

    /// Return the skip media item to process in the queue via completion routine, or nil
    func getMediaToProcess() -> Media? {
        for media in mediaArray {
            if ((media.mediaStatus == MediaStatus.Ready) ||
                (media.mediaStatus == MediaStatus.UploadFailed && media.retryCount.intValue < mediaRetryLimit.intValue)) {
                return media
            }
            if (media.mediaStatus == MediaStatus.UploadFailed && media.retryCount.intValue >= mediaRetryLimit.intValue) {
                self.deleteMediaFile(media: media)
                self.removeMedia(media: media)
            }
        }
        return nil
    }

// MARK: Uploader

    /// Upload the passed media, after multiple attempts to upload a file will not be attempted further. See countUploadFailedMedia and purgeUploadFailedMedia to manage those failures
    func uploadMedia(media: Media) {
        media.mediaStatus = MediaStatus.Uploading

        let bti = UIApplication.shared.beginBackgroundTask(withName: "RWFramework_uploadMedia", expirationHandler: { () -> Void in
            // last ditch effort
            self.logToServer(event_type: "upload_failed", data: "RWFramework_uploadMedia background task expired.")
            self.println(object: "RWFramework couldn't finish uploading in time.")
        })

        // upload here
        apiPatchEnvelopesId(media: media, success:{ () -> Void in
            self.println(object: "apiPatchEnvelopesId success")
            media.mediaStatus = MediaStatus.UploadCompleted
            self.deleteMediaFile(media: media)
            self.removeMedia(media: media)
            UIApplication.shared.endBackgroundTask(bti)
            self.uploaderUploading = false
        }, failure:{ (error: NSError) -> Void in
            self.println(object: "apiPatchEnvelopesId failure")
            if (error.code == 400) {
                self.deleteMediaFile(media: media)
                self.removeMedia(media: media)
            } else {
                media.mediaStatus = MediaStatus.UploadFailed
                media.retryCount = (media.retryCount.intValue + 1) as NSNumber
            }
            UIApplication.shared.endBackgroundTask(bti)
            self.uploaderUploading = false
        })
    }

// MARK: Cleanup

    func deleteMediaFile(media: Media) {
        var error: NSError?
        var b: Bool
        do {
            try FileManager.default.removeItem(atPath: media.string)
            b = true
        } catch let error1 as NSError {
            error = error1
            b = false
        }
        if let _ = error {
            println(object: "RWFramework - Couldn't delete media file after successful upload \(String(describing: error))")
        } else if (b == false) {
            println(object: "RWFramework - Couldn't delete media file after successful upload for an unknown reason")
        }
    }
}

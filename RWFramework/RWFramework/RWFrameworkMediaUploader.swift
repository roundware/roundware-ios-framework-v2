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
    var mediaRetryLimit: Int {
        get { return 3 }
    }

// MARK: Entry

    /// Handles kicking off the upload of the next available item in the queue
    func mediaUploader() {
        if (uploaderActive == false) { return }
        if (uploaderUploading == true) { return }
        uploaderUploading = true

        let media = getMediaToProcess()
        if (media != nil) {
            self.uploadMedia(media!)
        } else {
            self.uploaderUploading = false
        }
    }

// MARK: Iterator

    /// Return the next media item to process in the queue via completion routine, or nil
    func getMediaToProcess() -> Media? {
        for media in mediaArray {
            if ((media.mediaStatus == MediaStatus.Ready) ||
                (media.mediaStatus == MediaStatus.UploadFailed && media.retryCount.intValue < mediaRetryLimit)) {
                return media
            }
            if (media.mediaStatus == MediaStatus.UploadFailed && media.retryCount.intValue >= mediaRetryLimit) {
                self.deleteMediaFile(media)
                self.removeMedia(media)
            }
        }
        return nil
    }

// MARK: Uploader

    /// Upload the passed media, after multiple attempts to upload a file will not be attempted further. See countUploadFailedMedia and purgeUploadFailedMedia to manage those failures
    func uploadMedia(_ media: Media) {
        media.mediaStatus = MediaStatus.Uploading

        let bti = UIApplication.shared.beginBackgroundTask(withName: "RWFramework_uploadMedia", expirationHandler: { () -> Void in
            // last ditch effort
            self.logToServer("upload_failed", data: "RWFramework_uploadMedia background task expired.")
            self.println("RWFramework couldn't finish uploading in time.")
        })

        // upload here
        apiPatchEnvelopesId(media).then { () -> Void in
            self.println("apiPatchEnvelopesId success")
            media.mediaStatus = MediaStatus.UploadCompleted
            self.deleteMediaFile(media)
            self.removeMedia(media)
            UIApplication.shared.endBackgroundTask(bti)
            self.uploaderUploading = false
        }.catch { (error: Error) -> Void in
            let error = error as NSError
            self.println("apiPatchEnvelopesId failure")
            if (error.code == 400) {
                self.deleteMediaFile(media)
                self.removeMedia(media)
            } else {
                media.mediaStatus = MediaStatus.UploadFailed
                media.retryCount = NSNumber(value: media.retryCount.intValue+1 as Int)
            }
            UIApplication.shared.endBackgroundTask(bti)
            self.uploaderUploading = false
        }
    }

// MARK: Cleanup

    func deleteMediaFile(_ media: Media) {
        do {
            try FileManager.default.removeItem(atPath: media.string)
        }
        catch {
            println("RWFramework - Couldn't delete media file after successful upload \(error)")
        }
    }
}

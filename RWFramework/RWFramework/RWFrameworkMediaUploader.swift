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
    // func mediaUploader() {
    //     if (uploaderActive == false) { return }
    //     if (uploaderUploading == true) { return }
    //     uploaderUploading = true

    //     let media = getMediaToProcess()
    //     if (media != nil) {
    //         self.uploadMedia(media!)
    //     } else {
    //         self.uploaderUploading = false
    //     }
    // }

// MARK: Iterator

    /// Return the next media item to process in the queue via completion routine, or nil
    // func getMediaToProcess() -> Media? {
    //     for media in mediaArray {
    //         if ((media.mediaStatus == MediaStatus.Ready) ||
    //             (media.mediaStatus == MediaStatus.UploadFailed && media.retryCount < mediaRetryLimit)) {
    //             return media
    //         }
    //         if (media.mediaStatus == MediaStatus.UploadFailed && media.retryCount >= mediaRetryLimit) {
    //             self.deleteMediaFile(media)
    //             self.removeMedia(media)
    //         }
    //     }
    //     return nil
    // }

// MARK: Uploader


// MARK: Cleanup

    // func deleteMediaFile(_ media: Media) {
    //     do {
    //         try FileManager.default.removeItem(atPath: media.string)
    //     }
    //     catch {
    //         println("RWFramework - Couldn't delete media file after successful upload \(error)")
    //     }
    // }
}

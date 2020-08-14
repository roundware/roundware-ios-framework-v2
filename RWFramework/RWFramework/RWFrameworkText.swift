//
//  RWFrameworkText.swift
//  RWFramework
//
//  Created by Joe Zobkiw on 2/6/15.
//  Copyright (c) 2015 Roundware. All rights reserved.
//

import Foundation

extension RWFramework {

// MARK: Media queue

    /// Add string as text with optional description, returns a path (key) to the file that will ultimately be uploaded
    public func addText(_ string: String, description: String = "") -> String? {
        var key: String? = nil

        let r = arc4random()
        let text_file_name = RWFrameworkConfig.getConfigValueAsString("text_file_name")
        let textFileName = "\(r)_\(text_file_name)"

        do {
            let textFilePathURL = self.recorder.recordingPath(for: textFileName)
            try string.write(to: textFilePathURL, atomically: true, encoding: String.Encoding.utf8)
            recorder.addMedia(Media(mediaType: .Text, string: textFileName, description: description))
            key = textFilePathURL.path
        } catch {
            print(error)
        }

        return key
    }

    /// Set a description on an already added text, pass the path returned from addText as the string parameter
    public func setTextDescription(_ string: String, description: String) {
        recorder.setMediaDescription(MediaType.Text, string, description)
    }

    /// Remove a string of text, pass the path returned from addText as the string parameter
    public func removeText(_ string: String) {
        recorder.removeMedia(MediaType.Text, string: string)
    }

}

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
    public func addText(string: String, description: String = "") -> String? {
        var key: String? = nil

        let r = arc4random()
        let text_file_name = RWFrameworkConfig.getConfigValueAsString("text_file_name")
        let textFilePath = (NSTemporaryDirectory() as NSString).stringByAppendingPathComponent("\(r)_\(text_file_name)")

        var error: NSError?
        var success: Bool
        do {
                try string.writeToFile(textFilePath, atomically: false, encoding: NSUTF8StringEncoding)
                success = true
        } catch let error1 as NSError {
                error = error1
                success = false
        }
        if let _ = error {
            println("RWFramework - Couldn't write text to file \(error)")
        } else if success == false {
            println("RWFramework - Couldn't write text to file for an unknown reason")
        } else {
            addMedia(MediaType.Text, string: textFilePath, description: description)
            key = textFilePath
        }

        return key
    }

    /// Set a description on an already added text, pass the path returned from addText as the string parameter
    public func setTextDescription(string: String, description: String) {
        setMediaDescription(MediaType.Text, string: string, description: description)
    }

    /// Remove a string of text, pass the path returned from addText as the string parameter
    public func removeText(string: String) {
        removeMedia(MediaType.Text, string: string)
    }

}

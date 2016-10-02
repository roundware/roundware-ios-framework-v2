//
//  RWFrameworkHTTP.swift
//  RWFramework
//
//  Created by Joe Zobkiw on 2/6/15.
//  Copyright (c) 2015 Roundware. All rights reserved.
//

import Foundation
import MobileCoreServices

extension RWFramework: NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate /*, NSURLSessionDownloadDelegate */ {

    func httpPostUsers(device_id: String, client_type: String, completion:(data: NSData?, error: NSError?) -> Void) {
        if let url = NSURL(string: RWFrameworkURLFactory.postUsersURL()) {
            let postData = ["device_id": device_id, "client_type": client_type]
            postDataToURL(url, postData: postData, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "postUsersURL unable to be created."])
            completion(data: nil, error: error)
        }
    }

    func httpPostSessions(project_id: String, timezone: String, client_system: String, language: String, completion:(data: NSData?, error: NSError?) -> Void) {
        if let url = NSURL(string: RWFrameworkURLFactory.postSessionsURL()) {
            let postData = ["project_id": project_id, "timezone": timezone, "client_system": client_system, "language": language]
            postDataToURL(url, postData: postData, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "postSessionsURL unable to be created."])
            completion(data: nil, error: error)
        }
    }

    func httpGetProjectsId(project_id: String, session_id: String, completion:(data: NSData?, error: NSError?) -> Void) {
        if let url = NSURL(string: RWFrameworkURLFactory.getProjectsIdURL(project_id, session_id: session_id)) {
            getDataFromURL(url, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "getProjectsIdURL unable to be created."])
            completion(data: nil, error: error)
        }
    }

    func httpGetProjectsIdTags(project_id: String, session_id: String, completion:(data: NSData?, error: NSError?) -> Void) {
        if let url = NSURL(string: RWFrameworkURLFactory.getProjectsIdTagsURL(project_id, session_id: session_id)) {
            getDataFromURL(url, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "getProjectsIdTagsURL unable to be created."])
            completion(data: nil, error: error)
        }
    }

    func httpPostStreams(session_id: String, completion:(data: NSData?, error: NSError?) -> Void) {
        if let url = NSURL(string: RWFrameworkURLFactory.postStreamsURL()) {
            let postData = ["session_id": session_id]
            postDataToURL(url, postData: postData, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "postStreamsURL unable to be created."])
            completion(data: nil, error: error)
        }
    }

    func httpPatchStreamsId(stream_id: String, latitude: String, longitude: String, completion:(data: NSData?, error: NSError?) -> Void) {
        if let url = NSURL(string: RWFrameworkURLFactory.patchStreamsIdURL(stream_id)) {
            let postData = ["latitude": latitude, "longitude": longitude]
            patchDataToURL(url, postData: postData, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "patchStreamsIdURL unable to be created."])
            completion(data: nil, error: error)
        }
    }

    func httpPatchStreamsId(stream_id: String, tag_ids: String, completion:(data: NSData?, error: NSError?) -> Void) {
        if let url = NSURL(string: RWFrameworkURLFactory.patchStreamsIdURL(stream_id)) {
            let postData = ["tag_ids": tag_ids]
            patchDataToURL(url, postData: postData, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "patchStreamsIdURL unable to be created."])
            completion(data: nil, error: error)
        }
    }

    func httpPostStreamsIdHeartbeat(stream_id: String, completion:(data: NSData?, error: NSError?) -> Void) {
        if let url = NSURL(string: RWFrameworkURLFactory.postStreamsIdHeartbeatURL(stream_id)) {
            let postData = [:] as Dictionary<String, String>
            postDataToURL(url, postData: postData, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "postStreamsIdHeartbeatURL unable to be created."])
            completion(data: nil, error: error)
        }
    }

    func httpPostStreamsIdNext(stream_id: String, completion:(data: NSData?, error: NSError?) -> Void) {
        if let url = NSURL(string: RWFrameworkURLFactory.postStreamsIdNextURL(stream_id)) {
            let postData = [:] as Dictionary<String, String>
            postDataToURL(url, postData: postData, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "postStreamsIdNextURL unable to be created."])
            completion(data: nil, error: error)
        }
    }

    func httpGetStreamsIdCurrent(stream_id: String, completion:(data: NSData?, error: NSError?) -> Void) {
        if let url = NSURL(string: RWFrameworkURLFactory.getStreamsIdCurrentURL(stream_id)) {
            getDataFromURL(url, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "getStreamsIdCurrentURL unable to be created."])
            completion(data: nil, error: error)
        }
    }

    func httpPostEnvelopes(session_id: String, completion:(data: NSData?, error: NSError?) -> Void) {
        if let url = NSURL(string: RWFrameworkURLFactory.postEnvelopesURL()) {
            let postData = ["session_id": session_id]
            postDataToURL(url, postData: postData, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "postEnvelopesURL unable to be created."])
            completion(data: nil, error: error)
        }
    }

    func httpPatchEnvelopesId(media: Media, session_id: String, completion:(data: NSData?, error: NSError?) -> Void) {
        if let url = NSURL(string: RWFrameworkURLFactory.patchEnvelopesIdURL(media.envelopeID.stringValue)) {
            let serverMediaType = mapMediaTypeToServerMediaType(media.mediaType)
            let postData = ["session_id": session_id, "media_type": serverMediaType.rawValue, "latitude": media.latitude.stringValue, "longitude": media.longitude.stringValue, "tag_ids": media.tagIDs, "description": media.desc]
            patchFileAndDataToURL(url, filePath: media.string, postData: postData, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "httpPatchEnvelopesId unable to be created."])
            completion(data: nil, error: error)
        }
    }

    func httpGetAssets(dict: [String:String], completion:(data: NSData?, error: NSError?) -> Void) {
        if let url = NSURL(string: RWFrameworkURLFactory.getAssetsURL(dict)) {
            getDataFromURL(url, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "httpGetAssets unable to be created."])
            completion(data: nil, error: error)
        }
    }

    func httpGetAssetsId(asset_id: String, completion:(data: NSData?, error: NSError?) -> Void) {
        if let url = NSURL(string: RWFrameworkURLFactory.getAssetsIdURL(asset_id)) {
            getDataFromURL(url, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "httpGetAssetsId unable to be created."])
            completion(data: nil, error: error)
        }
    }

    func httpPostAssetsIdVotes(asset_id: String, session_id: String, vote_type: String, value: NSNumber = 0, completion:(data: NSData?, error: NSError?) -> Void) {
        if let url = NSURL(string: RWFrameworkURLFactory.postAssetsIdVotesURL(asset_id)) {
            let postData = ["session_id": session_id, "vote_type": vote_type, "value": value.stringValue]
            postDataToURL(url, postData: postData, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "postAssetsIdVotesURL unable to be created."])
            completion(data: nil, error: error)
        }
    }

    func httpGetAssetsIdVotes(asset_id: String, completion:(data: NSData?, error: NSError?) -> Void) {
        if let url = NSURL(string: RWFrameworkURLFactory.getAssetsIdVotesURL(asset_id)) {
            getDataFromURL(url, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "getAssetsIdVotesURL unable to be created."])
            completion(data: nil, error: error)
        }
    }

    func httpPostEvents(session_id: String, event_type: String, data: String?, latitude: String, longitude: String, client_time: String, tag_ids: String, completion:(data: NSData?, error: NSError?) -> Void) {
        if let url = NSURL(string: RWFrameworkURLFactory.postEventsURL()) {
            let postData = ["session_id": session_id, "event_type": event_type, "data": data ?? "", "latitude": latitude, "longitude": longitude, "client_time": client_time, "tag_ids": tag_ids]
            postDataToURL(url, postData: postData, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "postEventsURL unable to be created."])
            completion(data: nil, error: error)
        }
    }

// MARK: - Generic functions

    // Upload file and load data via PATCH and return in completion with or without error
    func patchFileAndDataToURL(url: NSURL, filePath: String, postData: Dictionary<String,String>, completion:(data: NSData?, error: NSError?) -> Void) {
        println("patchFileAndDataToURL: " + url.absoluteString! + " filePath = " + filePath + " postData = " + postData.description)

        // Multipart/form-data boundary
        func makeBoundary() -> String {
            let uuid = NSUUID().UUIDString
            return "Boundary-\(uuid)"
        }
        let boundary = makeBoundary()

        // Mime type
        var mimeType: String {
            get {
                let pathExtension = NSURL(fileURLWithPath: filePath).pathExtension!
                let UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, nil)
                let str = UTTypeCopyPreferredTagWithClass(UTI!.takeRetainedValue(), kUTTagClassMIMEType)
                if (str == nil) {
                    return "application/octet-stream"
                } else {
                    return str!.takeUnretainedValue() as String
                }
            }
        }

        let session = NSURLSession.sharedSession()
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "PATCH"

        // Token
        let token = RWFrameworkConfig.getConfigValueAsString("token", group: RWFrameworkConfig.ConfigGroup.Client)
        if token.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
            request.addValue("token \(token)", forHTTPHeaderField: "Authorization")
        }

        // Multipart/form-data
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var fileData: NSData
        do {
            fileData = try NSData(contentsOfFile: filePath, options: NSDataReadingOptions.DataReadingMappedAlways)
        }
        catch {
            print(error)
            completion(data: nil, error: nil)
            return
        }

        // The actual Multipart/form-data content
        let data = NSMutableData()
        data.appendData("--\(boundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
        let fileName = NSURL(fileURLWithPath: filePath).lastPathComponent!

        data.appendData("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
        data.appendData("Content-Type: \(mimeType)\r\n".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
        println("mimeType = \(mimeType)")
        data.appendData("\r\n".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
        data.appendData(fileData)
        data.appendData("\r\n".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
        for (key, value) in postData {
            if (value.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0) {
                data.appendData("--\(boundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
                data.appendData("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)\r\n".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
            }
        }
        data.appendData("--\(boundary)--\r\n".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)

        let uploadTask = session.uploadTaskWithRequest(request, fromData: data, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            if let errorResponse = error {
                completion(data: nil, error: errorResponse)
            } else if let httpResponse = response as? NSHTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    completion(data: data, error: nil)
                } else {
                    let error = NSError(domain:self.reverse_domain, code:httpResponse.statusCode, userInfo:[NSLocalizedDescriptionKey : "HTTP status code \(httpResponse.statusCode)."])
                    completion(data: data, error: error)
                }
            } else {
                let error = NSError(domain:self.reverse_domain, code:NSURLErrorUnknown, userInfo:[NSLocalizedDescriptionKey : "HTTP request returned no data and no error."])
                completion(data: nil, error: error)
            }
        })
        uploadTask.resume()
    }

    // Load data via PATCH and return in completion with or without error
    func patchDataToURL(url: NSURL, postData: Dictionary<String,String>, completion:(data: NSData?, error: NSError?) -> Void) {
        println("patchDataToURL: " + url.absoluteString! + " postData = " + postData.description)

        let session = NSURLSession.sharedSession()
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "PATCH"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "content-type")

        let token = RWFrameworkConfig.getConfigValueAsString("token", group: RWFrameworkConfig.ConfigGroup.Client)
        if token.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
            request.addValue("token \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = ""
        for (key, value) in postData {
            body += "\(key)=\(value)&"
        }
        request.HTTPBody = body.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        let loadDataTask = session.dataTaskWithRequest(request, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            if let errorResponse = error {
                completion(data: nil, error: errorResponse)
            } else if let httpResponse = response as? NSHTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    completion(data: data, error: nil)
                } else {
                    let error = NSError(domain:self.reverse_domain, code:httpResponse.statusCode, userInfo:[NSLocalizedDescriptionKey : "HTTP status code \(httpResponse.statusCode)."])
                    completion(data: data, error: error)
                }
            } else {
                let error = NSError(domain:self.reverse_domain, code:NSURLErrorUnknown, userInfo:[NSLocalizedDescriptionKey : "HTTP request returned no data and no error."])
                completion(data: nil, error: error)
            }
        })
        loadDataTask.resume()
    }

    // Load data via POST and return in completion with or without error
    func postDataToURL(url: NSURL, postData: Dictionary<String,String>, completion:(data: NSData?, error: NSError?) -> Void) {
        println("postDataToURL: " + url.absoluteString! + " postData = " + postData.description)

        let session = NSURLSession.sharedSession()
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"

        let token = RWFrameworkConfig.getConfigValueAsString("token", group: RWFrameworkConfig.ConfigGroup.Client)
        if token.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
            request.addValue("token \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = ""
        for (key, value) in postData {
            body += "\(key)=\(value)&"
        }
        request.HTTPBody = body.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        let loadDataTask = session.dataTaskWithRequest(request, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            if let errorResponse = error {
                completion(data: nil, error: errorResponse)
            } else if let httpResponse = response as? NSHTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    completion(data: data, error: nil)
                } else {
                    let error = NSError(domain:self.reverse_domain, code:httpResponse.statusCode, userInfo:[NSLocalizedDescriptionKey : "HTTP status code \(httpResponse.statusCode)."])
                    completion(data: data, error: error)
                }
            } else {
                let error = NSError(domain:self.reverse_domain, code:NSURLErrorUnknown, userInfo:[NSLocalizedDescriptionKey : "HTTP request returned no data and no error."])
                completion(data: nil, error: error)
            }
        })
        loadDataTask.resume()
    }

    /// Load data via GET and return in completion with or without error
    func getDataFromURL(url: NSURL, completion:(data: NSData?, error: NSError?) -> Void) {
        println("getDataFromURL: " + url.absoluteString!)

        let session = NSURLSession.sharedSession()
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "GET"

        let token = RWFrameworkConfig.getConfigValueAsString("token", group: RWFrameworkConfig.ConfigGroup.Client)
        if token.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
            request.addValue("token \(token)", forHTTPHeaderField: "Authorization")
        }

        let loadDataTask = session.dataTaskWithRequest(request, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            if let errorResponse = error {
                completion(data: nil, error: errorResponse)
            } else if let httpResponse = response as? NSHTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    completion(data: data, error: nil)
                } else {
                    let error = NSError(domain:self.reverse_domain, code:httpResponse.statusCode, userInfo:[NSLocalizedDescriptionKey : "HTTP status code \(httpResponse.statusCode)."])
                    completion(data: data, error: error)
                }
            } else {
                let error = NSError(domain:self.reverse_domain, code:NSURLErrorUnknown, userInfo:[NSLocalizedDescriptionKey : "HTTP request returned no data and no error."])
                completion(data: nil, error: error)
            }
        })
        loadDataTask.resume()
    }


    /// Load data via GET and return in completion with or without error
    /// This call does NOT add any token that may exist
    func loadDataFromURL(url: NSURL, completion:(data: NSData?, error: NSError?) -> Void) {
        println("loadDataFromURL: " + url.absoluteString!)

        let session = NSURLSession.sharedSession()
        let loadDataTask = session.dataTaskWithURL(url, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            if let errorResponse = error {
                completion(data: nil, error: errorResponse)
            } else if let httpResponse = response as? NSHTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    completion(data: data, error: nil)
                } else {
                    let error = NSError(domain:self.reverse_domain, code:httpResponse.statusCode, userInfo:[NSLocalizedDescriptionKey : "HTTP status code \(httpResponse.statusCode)."])
                    completion(data: nil, error: error)
                }
            } else {
                let error = NSError(domain:self.reverse_domain, code:NSURLErrorUnknown, userInfo:[NSLocalizedDescriptionKey : "HTTP request returned no data and no error."])
                completion(data: nil, error: error)
            }
        })
        loadDataTask.resume()
    }

// MARK: - NSURLSessionDelegate

// MARK: - NSURLSessionTaskDelegate

// MARK: - NSURLSessionDataDelegate

}

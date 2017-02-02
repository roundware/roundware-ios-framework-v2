//
//  RWFrameworkHTTP.swift
//  RWFramework
//
//  Created by Joe Zobkiw on 2/6/15.
//  Copyright (c) 2015 Roundware. All rights reserved.
//

import Foundation
import MobileCoreServices

extension RWFramework: URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate /*, NSURLSessionDownloadDelegate */ {

    func httpPostUsers(device_id: String, client_type: String, completion:@escaping (_ data: NSData?, _ error: NSError?) -> Void) {
        if let url = NSURL(string: RWFrameworkURLFactory.postUsersURL()) {
            let postData = ["device_id": device_id, "client_type": client_type]
            postDataToURL(url: url, postData: postData, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "postUsersURL unable to be created."])
            completion(nil, error)
        }
    }

    func httpPostSessions(project_id: String, timezone: String, client_system: String, language: String, completion:@escaping (_ data: NSData?, _ error: NSError?) -> Void) {
        if let url = NSURL(string: RWFrameworkURLFactory.postSessionsURL()) {
            let postData = ["project_id": project_id, "timezone": timezone, "client_system": client_system, "language": language]
            postDataToURL(url: url, postData: postData, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "postSessionsURL unable to be created."])
            completion(nil, error)
        }
    }

    func httpGetProjectsId(project_id: String, session_id: String, completion:@escaping (_ data: NSData?, _ error: NSError?) -> Void) {
        if let url = NSURL(string: RWFrameworkURLFactory.getProjectsIdURL(project_id: project_id, session_id: session_id)) {
            getDataFromURL(url: url, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "getProjectsIdURL unable to be created."])
            completion(nil, error)
        }
    }

    func httpGetProjectsIdTags(project_id: String, session_id: String, completion:@escaping (_ data: NSData?, _ error: NSError?) -> Void) {
        if let url = NSURL(string: RWFrameworkURLFactory.getProjectsIdTagsURL(project_id: project_id, session_id: session_id)) {
            getDataFromURL(url: url, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "getProjectsIdTagsURL unable to be created."])
            completion(nil, error)
        }
    }
    
    func httpGetProjectsIdUIGroups(project_id: String, session_id: String, completion:@escaping (_ data: NSData?, _ error: NSError?) -> Void) {
        if let url = NSURL(string: RWFrameworkURLFactory.getProjectsIdUIGroupsURL(project_id: project_id, session_id: session_id)) {
            getDataFromURL(url: url, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "getProjectsIdUIGroupsURL unable to be created."])
            completion(nil, error)
        }
    }

    func httpPostStreams(session_id: String, latitude: String?, longitude: String?, completion:@escaping (_ data: NSData?, _ error: NSError?) -> Void) {
        if let url = NSURL(string: RWFrameworkURLFactory.postStreamsURL()) {
            var postData = ["session_id": session_id]
            if let ourLatitude = latitude, let ourLongitude = longitude {
                postData["latitude"]    = ourLatitude
                postData["longitude"]   = ourLongitude
            }
            postDataToURL(url: url, postData: postData, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "postStreamsURL unable to be created."])
            completion(nil, error)
        }
    }

    func httpPatchStreamsId(stream_id: String, latitude: String, longitude: String, completion:@escaping (_ data: NSData?, _ error: NSError?) -> Void) {
        if let url = NSURL(string: RWFrameworkURLFactory.patchStreamsIdURL(stream_id: stream_id)) {
            let postData = ["latitude": latitude, "longitude": longitude]
            patchDataToURL(url: url, postData: postData, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "patchStreamsIdURL unable to be created."])
            completion(nil, error)
        }
    }

    func httpPatchStreamsId(stream_id: String, tag_ids: String, completion:@escaping (_ data: NSData?, _ error: NSError?) -> Void) {
        if let url = NSURL(string: RWFrameworkURLFactory.patchStreamsIdURL(stream_id: stream_id)) {
            let postData = ["tag_ids": tag_ids]
            patchDataToURL(url: url, postData: postData, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "patchStreamsIdURL unable to be created."])
            completion(nil, error)
        }
    }

    func httpPostStreamsIdHeartbeat(stream_id: String, completion:@escaping (_ data: NSData?, _ error: NSError?) -> Void) {
        if let url = NSURL(string: RWFrameworkURLFactory.postStreamsIdHeartbeatURL(stream_id: stream_id)) {
            let postData = [:] as Dictionary<String, String>
            postDataToURL(url: url, postData: postData, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "postStreamsIdHeartbeatURL unable to be created."])
            completion(nil, error)
        }
    }

    func httpPostStreamsIdSkip(stream_id: String, completion:@escaping (_ data: NSData?, _ error: NSError?) -> Void) {
        if let url = NSURL(string: RWFrameworkURLFactory.postStreamsIdSkipURL(stream_id: stream_id)) {
            let postData = [:] as Dictionary<String, String>
            postDataToURL(url: url, postData: postData, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "postStreamsIdSkipURL unable to be created."])
            completion(nil, error)
        }
    }

    func httpPostStreamsIdPlayAsset(stream_id: String, asset_id: String, completion:@escaping (_ data: NSData?, _ error: NSError?) -> Void) {
        if let url = NSURL(string: RWFrameworkURLFactory.postStreamsIdPlayAssetURL(stream_id: stream_id)) {
            let postData = ["asset_id": asset_id] as Dictionary<String, String>
            postDataToURL(url: url, postData: postData, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "postStreamsIdPlayAssetURL unable to be created."])
            completion(nil, error)
        }
    }

    func httpPostStreamsIdReplayAsset(stream_id: String, completion:@escaping (_ data: NSData?, _ error: NSError?) -> Void) {       if let url = NSURL(string: RWFrameworkURLFactory.postStreamsIdReplayAssetURL(stream_id: stream_id)) {
        let postData = [:] as Dictionary<String, String>
        postDataToURL(url: url, postData: postData, completion: completion)
    } else {
        let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "postStreamsIdReplayAssetURL unable to be created."])
        completion(nil, error)
        }
    }

    func httpPostStreamsIdPause(stream_id: String, completion:@escaping (_ data: NSData?, _ error: NSError?) -> Void) {
        if let url = NSURL(string: RWFrameworkURLFactory.postStreamsIdPauseURL(stream_id: stream_id)) {
            let postData = [:] as Dictionary<String, String>
            postDataToURL(url: url, postData: postData, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "postStreamsIdPauseURL unable to be created."])
            completion(nil, error)
        }
    }

    func httpPostStreamsIdResume(stream_id: String, completion:@escaping (_ data: NSData?, _ error: NSError?) -> Void) {
        if let url = NSURL(string: RWFrameworkURLFactory.postStreamsIdResumeURL(stream_id: stream_id)) {
            let postData = [:] as Dictionary<String, String>
            postDataToURL(url: url, postData: postData, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "postStreamsIdResumeURL unable to be created."])
            completion(nil, error)
        }
    }


    func httpGetStreamsIdCurrent(stream_id: String, completion:@escaping (_ data: NSData?, _ error: NSError?) -> Void) {
        if let url = NSURL(string: RWFrameworkURLFactory.getStreamsIdCurrentURL(stream_id: stream_id)) {
            getDataFromURL(url: url, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "getStreamsIdCurrentURL unable to be created."])
            completion(nil, error)
        }
    }

    func httpPostEnvelopes(session_id: String, completion:@escaping (_ data: NSData?, _ error: NSError?) -> Void) {
        if let url = NSURL(string: RWFrameworkURLFactory.postEnvelopesURL()) {
            let postData = ["session_id": session_id]
            postDataToURL(url: url, postData: postData, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "postEnvelopesURL unable to be created."])
            completion(nil, error)
        }
    }

    func httpPatchEnvelopesId(media: Media, session_id: String, completion:@escaping (_ data: NSData?, _ error: NSError?) -> Void) {
        if let url = NSURL(string: RWFrameworkURLFactory.patchEnvelopesIdURL(envelope_id: media.envelopeID.stringValue)) {
            let serverMediaType = mapMediaTypeToServerMediaType(mediaType: media.mediaType)
            let postData = ["session_id": session_id, "media_type": serverMediaType.rawValue, "latitude": media.latitude.stringValue, "longitude": media.longitude.stringValue, "tag_ids": media.tagIDs, "description": media.desc]
            patchFileAndDataToURL(url: url, filePath: media.string, postData: postData, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "httpPatchEnvelopesId unable to be created."])
            completion(nil, error)
        }
    }

    func httpGetAssets(dict: [String:String], completion:@escaping (_ data: NSData?, _ error: NSError?) -> Void) {
        if let url = NSURL(string: RWFrameworkURLFactory.getAssetsURL(dict: dict)) {
            getDataFromURL(url: url, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "httpGetAssets unable to be created."])
            completion(nil, error)
        }
    }

    func httpGetAssetsId(asset_id: String, completion:@escaping (_ data: NSData?, _ error: NSError?) -> Void) {
        if let url = NSURL(string: RWFrameworkURLFactory.getAssetsIdURL(asset_id: asset_id)) {
            getDataFromURL(url: url, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "httpGetAssetsId unable to be created."])
            completion(nil, error)
        }
    }

    func httpPostAssetsIdVotes(asset_id: String, session_id: String, vote_type: String, value: NSNumber = 0, completion:@escaping (_ data: NSData?, _ error: NSError?) -> Void) {
        if let url = NSURL(string: RWFrameworkURLFactory.postAssetsIdVotesURL(asset_id: asset_id)) {
            let postData = ["session_id": session_id, "vote_type": vote_type, "value": value.stringValue]
            postDataToURL(url: url, postData: postData, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "postAssetsIdVotesURL unable to be created."])
            completion(nil, error)
        }
    }

    func httpGetAssetsIdVotes(asset_id: String, completion:@escaping (_ data: NSData?, _ error: NSError?) -> Void) {
        if let url = NSURL(string: RWFrameworkURLFactory.getAssetsIdVotesURL(asset_id: asset_id)) {
            getDataFromURL(url: url, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "getAssetsIdVotesURL unable to be created."])
            completion(nil, error)
        }
    }

    func httpPostEvents(session_id: String, event_type: String, data: String?, latitude: String, longitude: String, client_time: String, tag_ids: String, completion:@escaping (_ data: NSData?, _ error: NSError?) -> Void) {
        if let url = NSURL(string: RWFrameworkURLFactory.postEventsURL()) {
            let postData = ["session_id": session_id, "event_type": event_type, "data": data ?? "", "latitude": latitude, "longitude": longitude, "client_time": client_time, "tag_ids": tag_ids]
            postDataToURL(url: url, postData: postData, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "postEventsURL unable to be created."])
            completion(nil, error)
        }
    }

// MARK: - Generic functions

    // Upload file and load data via PATCH and return in completion with or without error
    func patchFileAndDataToURL(url: NSURL, filePath: String, postData: Dictionary<String,String>, completion:@escaping (_ data: NSData?, _ error: NSError?) -> Void) {
//        println(object: "patchFileAndDataToURL: " + url.absoluteString + " filePath = " + filePath + " postData = " + postData.description)

        // Multipart/form-data boundary
        func makeBoundary() -> String {
            let uuid = NSUUID().uuidString
            return "Boundary-\(uuid)"
        }
        let boundary = makeBoundary()

        // Mime type
        var mimeType: String {
            get {
                let pathExtension = (filePath as NSString).pathExtension
                let UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as CFString, nil)
                let str = UTTypeCopyPreferredTagWithClass(UTI!.takeRetainedValue(), kUTTagClassMIMEType)
                if (str == nil) {
                    return "application/octet-stream"
                } else {
                    return str!.takeUnretainedValue() as String
                }
            }
        }

        let session = URLSession.shared
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "PATCH"

        // Token
        let token = RWFrameworkConfig.getConfigValueAsString(key: "token", group: RWFrameworkConfig.ConfigGroup.Client)
        if token.lengthOfBytes(using: String.Encoding.utf8) > 0 {
            request.addValue("token \(token)", forHTTPHeaderField: "Authorization")
        }

        // Multipart/form-data
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var error: NSError?
        let fileData: NSData?
        do {
            fileData = try NSData(contentsOfFile: filePath, options: NSData.ReadingOptions.alwaysMapped)
        } catch let error1 as NSError {
            error = error1
            fileData = nil
        }
        if (fileData == nil || error != nil) {
            completion(nil, error)
            return
        }

        // The actual Multipart/form-data content
        let data = NSMutableData()
        data.append("--\(boundary)\r\n".data(using:  String.Encoding.utf8, allowLossyConversion: false)!)
        let fileName = (filePath as NSString).lastPathComponent
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: String.Encoding.utf8, allowLossyConversion: false)!)
        data.append("Content-Type: \(mimeType)\r\n".data(using: String.Encoding.utf8, allowLossyConversion: false)!)
        println(object: "mimeType = \(mimeType)")
        data.append("\r\n".data(using: String.Encoding.utf8, allowLossyConversion: false)!)
        data.append(fileData! as Data)
        data.append("\r\n".data(using:  String.Encoding.utf8, allowLossyConversion: false)!)
        for (key, value) in postData {
            if (value.lengthOfBytes(using: String.Encoding.utf8) > 0) {
                data.append("--\(boundary)\r\n".data(using: String.Encoding.utf8, allowLossyConversion: false)!)
                data.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)\r\n".data(using:  String.Encoding.utf8, allowLossyConversion: false)!)
            }
        }
        data.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8, allowLossyConversion: false)!)

        let uploadTask = session.uploadTask(with: request as URLRequest, from: data as Data, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if let errorResponse = error {
                completion(nil, errorResponse as NSError?)
            } else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    completion(data as NSData?, nil)
                } else {
                    let error = NSError(domain:self.reverse_domain, code:httpResponse.statusCode, userInfo:[NSLocalizedDescriptionKey : "HTTP status code \(httpResponse.statusCode)."])
                    completion(data as NSData?, error)
                }
            } else {
                let error = NSError(domain:self.reverse_domain, code:NSURLErrorUnknown, userInfo:[NSLocalizedDescriptionKey : "HTTP request returned no data and no error."])
                completion(nil, error)
            }
        })
        uploadTask.resume()
    }

    // Load data via PATCH and return in completion with or without error
    func patchDataToURL(url: NSURL, postData: Dictionary<String,String>, completion:@escaping (_ data: NSData?, _ error: NSError?) -> Void) {
        println(object: "patchDataToURL: " + url.absoluteString! + " postData = " + postData.description)

        let session = URLSession.shared
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "PATCH"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "content-type")

        let token = RWFrameworkConfig.getConfigValueAsString(key: "token", group: RWFrameworkConfig.ConfigGroup.Client)
        if token.lengthOfBytes(using: String.Encoding.utf8) > 0 {
            request.addValue("token \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = ""
        for (key, value) in postData {
            body += "\(key)=\(value)&"
        }
        request.httpBody = body.data( using: String.Encoding.utf8, allowLossyConversion: false)
        let loadDataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if let errorResponse = error {
                completion(nil, errorResponse as NSError?)
            } else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    completion(data as NSData?, nil)
                } else {
                    let error = NSError(domain:self.reverse_domain, code:httpResponse.statusCode, userInfo:[NSLocalizedDescriptionKey : "HTTP status code \(httpResponse.statusCode)."])
                    completion(data as NSData?, error)
                }
            } else {
                let error = NSError(domain:self.reverse_domain, code:NSURLErrorUnknown, userInfo:[NSLocalizedDescriptionKey : "HTTP request returned no data and no error."])
                completion(nil, error)
            }
        })
        loadDataTask.resume()
    }

    // Load data via POST and return in completion with or without error
    func postDataToURL(url: NSURL, postData: Dictionary<String,String>, completion:@escaping (_ data: NSData?, _ error: NSError?) -> Void) {
        println(object: "postDataToURL: " + url.absoluteString! + " postData = " + postData.description)

        let session = URLSession.shared
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "POST"

        let token = RWFrameworkConfig.getConfigValueAsString(key: "token", group: RWFrameworkConfig.ConfigGroup.Client)
        if token.lengthOfBytes(using:  String.Encoding.utf8) > 0 {
            request.addValue("token \(token)", forHTTPHeaderField: "Authorization")
            
            //could set for whole session
            //session.configuration.HTTPAdditionalHeaders = ["Authorization" : "token \(token)"]
        }

        var body = ""
        for (key, value) in postData {
            body += "\(key)=\(value)&"
        }
        request.httpBody = body.data( using: String.Encoding.utf8, allowLossyConversion: false)
        
        let loadDataTask = session.dataTask(with:
            request as URLRequest, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if let errorResponse = error {
                completion(nil, errorResponse as NSError?)
            } else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    completion(data as NSData?, nil)
                } else {
                    let error = NSError(domain:self.reverse_domain, code:httpResponse.statusCode, userInfo:[NSLocalizedDescriptionKey : "HTTP status code \(httpResponse.statusCode)."])
                    //let's see those error messages
                    //let dict = JSON(data: data!)
                    //self.println(dict)
                    completion(data as NSData?, error)
                }
            } else {
                let error = NSError(domain:self.reverse_domain, code:NSURLErrorUnknown, userInfo:[NSLocalizedDescriptionKey : "HTTP request returned no data and no error."])
                completion(nil, error)
            }
        })
        loadDataTask.resume()
    }

    /// Load data via GET and return in completion with or without error
    func getDataFromURL(url: NSURL, completion:@escaping (_ data: NSData?, _ error: NSError?) -> Void) {
        println(object: "getDataFromURL: " + url.absoluteString!)

        let session = URLSession.shared
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "GET"

        let token = RWFrameworkConfig.getConfigValueAsString(key: "token", group: RWFrameworkConfig.ConfigGroup.Client)
        if token.lengthOfBytes(using: String.Encoding.utf8) > 0 {
            request.addValue("token \(token)", forHTTPHeaderField: "Authorization")
        }

        let loadDataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if let errorResponse = error {
                completion(nil, errorResponse as NSError?)
            } else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    completion(data as NSData?, nil)
                } else {
                    let error = NSError(domain:self.reverse_domain, code:httpResponse.statusCode, userInfo:[NSLocalizedDescriptionKey : "HTTP status code \(httpResponse.statusCode)."])
                    completion(data as NSData?, error)
                }
            } else {
                let error = NSError(domain:self.reverse_domain, code:NSURLErrorUnknown, userInfo:[NSLocalizedDescriptionKey : "HTTP request returned no data and no error."])
                completion(nil, error)
            }
        })
        loadDataTask.resume()
    }


    /// Load data via GET and return in completion with or without error
    /// This call does NOT add any token that may exist
    func loadDataFromURL(url: NSURL, completion:@escaping (_ data: NSData?, _ error: NSError?) -> Void) {
        println(object: "loadDataFromURL: " + url.absoluteString!)

        let session = URLSession.shared
        let loadDataTask = session.dataTask(with: url as URL, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if let errorResponse = error {
                completion(nil, errorResponse as NSError?)
            } else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    completion(data as NSData?, nil)
                } else {
                    let error = NSError(domain:self.reverse_domain, code:httpResponse.statusCode, userInfo:[NSLocalizedDescriptionKey : "HTTP status code \(httpResponse.statusCode)."])
                    completion(nil, error)
                }
            } else {
                let error = NSError(domain:self.reverse_domain, code:NSURLErrorUnknown, userInfo:[NSLocalizedDescriptionKey : "HTTP request returned no data and no error."])
                completion(nil, error)
            }
        })
        loadDataTask.resume()
    }

// MARK: - NSURLSessionDelegate

// MARK: - NSURLSessionTaskDelegate

// MARK: - NSURLSessionDataDelegate

}

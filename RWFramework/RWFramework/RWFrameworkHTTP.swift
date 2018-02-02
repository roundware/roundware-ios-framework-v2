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

    func httpPostUsers(_ device_id: String, client_type: String, client_system: String, completion:@escaping (_ data: Data?, _ error: NSError?) -> Void) {
        if let url = URL(string: RWFrameworkURLFactory.postUsersURL()) {
            let postData = ["device_id": device_id, "client_type": client_type, "client_system": client_system]
            postDataToURL(url, postData: postData, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "postUsersURL unable to be created."])
            completion(nil, error)
        }
    }

    func httpPostSessions(_ project_id: NSNumber, timezone: String, client_system: String, language: String, completion:@escaping (_ data: Data?, _ error: NSError?) -> Void) {
        if let url = URL(string: RWFrameworkURLFactory.postSessionsURL()) {
            let postData = ["project_id": project_id, "timezone": timezone, "client_system": client_system, "language": language] as [String : Any]
            postDataToURL(url, postData: postData, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "postSessionsURL unable to be created."])
            completion(nil, error)
        }
    }

    func httpGetProjectsId(_ project_id: NSNumber, session_id: NSNumber, completion:@escaping (_ data: Data?, _ error: NSError?) -> Void) {
        if let url = URL(string: RWFrameworkURLFactory.getProjectsIdURL(project_id, session_id: session_id)) {
            getDataFromURL(url, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "getProjectsIdURL unable to be created."])
            completion(nil, error)
        }
    }

    func httpGetUIConfig(_ project_id: NSNumber, session_id: NSNumber, completion:@escaping (_ data: Data?, _ error: NSError?) -> Void) {
        if let url = URL(string: RWFrameworkURLFactory.getUIConfigURL(project_id, session_id: session_id)) {
            getDataFromURL(url, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "getUIConfigURL unable to be created."])
            completion(nil, error)
        }
    }

    func httpGetProjectsIdTags(_ project_id: NSNumber, session_id: NSNumber, completion:@escaping (_ data: Data?, _ error: NSError?) -> Void) {
        if let url = URL(string: RWFrameworkURLFactory.getProjectsIdTagsURL(project_id, session_id: session_id)) {
            getDataFromURL(url, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "getProjectsIdTagsURL unable to be created."])
            completion(nil, error)
        }
    }

    func httpGetProjectsIdUIGroups(_ project_id: NSNumber, session_id: NSNumber, completion:@escaping (_ data: Data?, _ error: NSError?) -> Void) {
        if let url = URL(string: RWFrameworkURLFactory.getProjectsIdUIGroupsURL(project_id, session_id: session_id)) {
            getDataFromURL(url, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "getProjectsIdUIGroupsURL unable to be created."])
            completion(nil, error)
        }
    }
    
    func httpGetTagCategories(completion:@escaping (_ data: Data?, _ error: NSError?) -> Void) {
        if let url = URL(string: RWFrameworkURLFactory.getTagCategoriesURL()) {
            getDataFromURL(url, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "getTagCategoriesURL unable to be created."])
            completion(nil, error)
        }
    }

    func httpPostStreams(_ session_id: NSNumber, latitude: String = "0", longitude: String = "0", completion:@escaping (_ data: Data?, _ error: NSError?) -> Void) {
        if let url = URL(string: RWFrameworkURLFactory.postStreamsURL()) {
            let postData = ["session_id": session_id, "latitude": latitude, "longitude": longitude] as [String:Any]
            postDataToURL(url, postData: postData, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "postStreamsURL unable to be created."])
            completion(nil, error)
        }
    }
    func httpPatchStreamsId(_ stream_id: String, latitude: String, longitude: String, streamPatchOptions: Dictionary<String, Any> = [:], completion:@escaping (_ data: Data?, _ error: NSError?) -> Void) {
        if let url = URL(string: RWFrameworkURLFactory.patchStreamsIdURL(stream_id)) {
            var postData = ["latitude": latitude, "longitude": longitude] as [String:Any]
            // append postData with any key/value pairs that exist in optionalParams dictionary; if empty dictionary, append nothing
            postData = postData.merging(streamPatchOptions, uniquingKeysWith: { (first, _) in
                return first
            })
            
            patchDataToURL(url, postData: postData, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "patchStreamsIdURL unable to be created."])
            completion(nil, error)
        }
    }

    func httpPatchStreamsId(_ stream_id: String, tag_ids: String, completion:@escaping (_ data: Data?, _ error: NSError?) -> Void) {
        if let url = URL(string: RWFrameworkURLFactory.patchStreamsIdURL(stream_id)) {
            let postData = ["tag_ids": tag_ids]
            patchDataToURL(url, postData: postData, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "patchStreamsIdURL unable to be created."])
            completion(nil, error)
        }
    }

    func httpPostStreamsIdHeartbeat(_ stream_id: String, completion:@escaping (_ data: Data?, _ error: NSError?) -> Void) {
        if let url = URL(string: RWFrameworkURLFactory.postStreamsIdHeartbeatURL(stream_id)) {
            let postData = [:] as Dictionary<String, String>
            postDataToURL(url, postData: postData, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "postStreamsIdHeartbeatURL unable to be created."])
            completion(nil, error)
        }
    }

    func httpPostStreamsIdReplay(_ stream_id: String, completion:@escaping (_ data: Data?, _ error: NSError?) -> Void) {
        if let url = URL(string: RWFrameworkURLFactory.postStreamsIdReplayURL(stream_id)) {
            let postData = [:] as Dictionary<String, String>
            postDataToURL(url, postData: postData, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "postStreamsIdReplayURL unable to be created."])
            completion(nil, error)
        }
    }
    
    func httpPostStreamsIdSkip(_ stream_id: String, completion:@escaping (_ data: Data?, _ error: NSError?) -> Void) {
        if let url = URL(string: RWFrameworkURLFactory.postStreamsIdSkipURL(stream_id)) {
            let postData = [:] as Dictionary<String, String>
            postDataToURL(url, postData: postData, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "postStreamsIdSkipURL unable to be created."])
            completion(nil, error)
        }
    }

    func httpPostEnvelopes(_ session_id: NSNumber, completion:@escaping (_ data: Data?, _ error: NSError?) -> Void) {
        if let url = URL(string: RWFrameworkURLFactory.postEnvelopesURL()) {
            let postData = ["session_id": session_id]
            postDataToURL(url, postData: postData, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "postEnvelopesURL unable to be created."])
            completion(nil, error)
        }
    }

    func httpPatchEnvelopesId(_ media: Media, session_id: NSNumber, completion:@escaping (_ data: Data?, _ error: NSError?) -> Void) {
        if let url = URL(string: RWFrameworkURLFactory.patchEnvelopesIdURL(media.envelopeID.stringValue)) {
            let serverMediaType = mapMediaTypeToServerMediaType(media.mediaType)
            let postData = ["session_id": session_id, "media_type": serverMediaType.rawValue, "latitude": media.latitude.stringValue, "longitude": media.longitude.stringValue, "tag_ids": media.tagIDs, "description": media.desc] as [String : Any]
            patchFileAndDataToURL(url, filePath: media.string, postData: postData, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "httpPatchEnvelopesId unable to be created."])
            completion(nil, error)
        }
    }

    func httpGetAssets(_ dict: [String:String], completion:@escaping (_ data: Data?, _ error: NSError?) -> Void) {
        if let url = URL(string: RWFrameworkURLFactory.getAssetsURL(dict)) {
            getDataFromURL(url, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "httpGetAssets unable to be created."])
            completion(nil, error)
        }
    }

    func httpGetAssetsId(_ asset_id: String, completion:@escaping (_ data: Data?, _ error: NSError?) -> Void) {
        if let url = URL(string: RWFrameworkURLFactory.getAssetsIdURL(asset_id)) {
            getDataFromURL(url, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "httpGetAssetsId unable to be created."])
            completion(nil, error)
        }
    }

    func httpPostAssetsIdVotes(_ asset_id: String, session_id: NSNumber, vote_type: String, value: NSNumber = 0, completion:@escaping (_ data: Data?, _ error: NSError?) -> Void) {
        if let url = URL(string: RWFrameworkURLFactory.postAssetsIdVotesURL(asset_id)) {
            let postData = ["session_id": session_id, "vote_type": vote_type, "value": value.stringValue] as [String : Any]
            postDataToURL(url, postData: postData, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "postAssetsIdVotesURL unable to be created."])
            completion(nil, error)
        }
    }

    func httpGetAssetsIdVotes(_ asset_id: String, completion:@escaping (_ data: Data?, _ error: NSError?) -> Void) {
        if let url = URL(string: RWFrameworkURLFactory.getAssetsIdVotesURL(asset_id)) {
            getDataFromURL(url, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "getAssetsIdVotesURL unable to be created."])
            completion(nil, error)
        }
    }

    func httpPostEvents(_ session_id: NSNumber, event_type: String, data: String?, latitude: String, longitude: String, client_time: String, tag_ids: String, completion:@escaping (_ data: Data?, _ error: NSError?) -> Void) {
        if let url = URL(string: RWFrameworkURLFactory.postEventsURL()) {
            let postData = ["session_id": session_id, "event_type": event_type, "data": data ?? "", "latitude": latitude, "longitude": longitude, "client_time": client_time, "tag_ids": tag_ids] as [String : Any]
            postDataToURL(url, postData: postData, completion: completion)
        } else {
            let error = NSError(domain:self.reverse_domain, code:NSURLErrorBadURL, userInfo:[NSLocalizedDescriptionKey : "postEventsURL unable to be created."])
            completion(nil, error)
        }
    }

// MARK: - Generic functions

    // Upload file and load data via PATCH and return in completion with or without error
    func patchFileAndDataToURL(_ url: URL, filePath: String, postData: Dictionary<String,Any>, completion:@escaping (_ data: Data?, _ error: NSError?) -> Void) {
        println("patchFileAndDataToURL: " + url.absoluteString + " filePath = " + filePath + " postData = " + postData.description)

        // Multipart/form-data boundary
        func makeBoundary() -> String {
            let uuid = UUID().uuidString
            return "Boundary-\(uuid)"
        }
        let boundary = makeBoundary()

        // Mime type
        var mimeType: String {
            get {
                let pathExtension = URL(fileURLWithPath: filePath).pathExtension
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
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "PATCH"

        // Token
        let token = RWFrameworkConfig.getConfigValueAsString("token", group: RWFrameworkConfig.ConfigGroup.client)
        if token.lengthOfBytes(using: String.Encoding.utf8) > 0 {
            request.addValue("token \(token)", forHTTPHeaderField: "Authorization")
        }

        // Multipart/form-data
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var fileData: Data
        do {
            fileData = try Data(contentsOf: URL(fileURLWithPath: filePath), options: NSData.ReadingOptions.alwaysMapped)
        }
        catch {
            print(error)
            completion(nil, nil)
            return
        }

        // The actual Multipart/form-data content
        let data = NSMutableData()
        data.append("--\(boundary)\r\n".data(using: String.Encoding.utf8, allowLossyConversion: false)!)
        let fileName = URL(fileURLWithPath: filePath).lastPathComponent

        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: String.Encoding.utf8, allowLossyConversion: false)!)
        data.append("Content-Type: \(mimeType)\r\n".data(using: String.Encoding.utf8, allowLossyConversion: false)!)
        println("mimeType = \(mimeType)")
        data.append("\r\n".data(using: String.Encoding.utf8, allowLossyConversion: false)!)
        data.append(fileData)
        data.append("\r\n".data(using: String.Encoding.utf8, allowLossyConversion: false)!)
        for (key, value) in postData {
            var v = ""
            if let n = value as? NSNumber {
                v = n.stringValue
            } else {
                v = value as! String
            }
            if (v.lengthOfBytes(using: String.Encoding.utf8) > 0) {
                data.append("--\(boundary)\r\n".data(using: String.Encoding.utf8, allowLossyConversion: false)!)
                data.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)\r\n".data(using: String.Encoding.utf8, allowLossyConversion: false)!)
            }
        }
        data.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8, allowLossyConversion: false)!)

        let uploadTask = session.uploadTask(with: request as URLRequest, from: data as Data) { (data: Data?, response: URLResponse?, error: Error?) in
            if let errorResponse = error {
                completion(nil, errorResponse as NSError)
            } else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    completion(data, nil)
                } else {
                    let error = NSError(domain:self.reverse_domain, code:httpResponse.statusCode, userInfo:[NSLocalizedDescriptionKey : "HTTP status code \(httpResponse.statusCode)."])
                    completion(data, error)
                }
            } else {
                let error = NSError(domain:self.reverse_domain, code:NSURLErrorUnknown, userInfo:[NSLocalizedDescriptionKey : "HTTP request returned no data and no error."])
                completion(nil, error)
            }
        }
        uploadTask.resume()
    }

    // Load data via PATCH and return in completion with or without error
    func patchDataToURL(_ url: URL, postData: Dictionary<String,Any>, completion:@escaping (_ data: Data?, _ error: NSError?) -> Void) {
        println("patchDataToURL: " + url.absoluteString + " postData = " + postData.description)

        let session = URLSession.shared
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "PATCH"

        let token = RWFrameworkConfig.getConfigValueAsString("token", group: RWFrameworkConfig.ConfigGroup.client)
        if token.lengthOfBytes(using: String.Encoding.utf8) > 0 {
            request.addValue("token \(token)", forHTTPHeaderField: "Authorization")
        }

#if USE_AMPERSAND_EQUALS
        var body = ""
        for (key, value) in postData {
            body += "\(key)=\(value)&"
        }
        request.httpBody = body.data(using: String.Encoding.utf8, allowLossyConversion: false)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
#else
        let jsonData = try? JSONSerialization.data(withJSONObject: postData)
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
#endif

        let loadDataTask = session.dataTask(with: request as URLRequest) { (data, response, error) -> Void in
            if let errorResponse = error {
                completion(nil, errorResponse as NSError)
            } else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    completion(data, nil)
                } else {
                    let error = NSError(domain:self.reverse_domain, code:httpResponse.statusCode, userInfo:[NSLocalizedDescriptionKey : "HTTP status code \(httpResponse.statusCode)."])
                    completion(data, error)
                }
            } else {
                let error = NSError(domain:self.reverse_domain, code:NSURLErrorUnknown, userInfo:[NSLocalizedDescriptionKey : "HTTP request returned no data and no error."])
                completion(nil, error)
            }
        }
        loadDataTask.resume()
    }

    // Load data via POST and return in completion with or without error
    func postDataToURL(_ url: URL, postData: Dictionary<String, Any>, completion:@escaping (_ data: Data?, _ error: NSError?) -> Void) {
        println("postDataToURL: " + url.absoluteString + " postData = " + postData.description)

        let session = URLSession.shared
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "POST"

        let token = RWFrameworkConfig.getConfigValueAsString("token", group: RWFrameworkConfig.ConfigGroup.client)
        if token.lengthOfBytes(using: String.Encoding.utf8) > 0 {
            request.addValue("token \(token)", forHTTPHeaderField: "Authorization")
        }

#if USE_AMPERSAND_EQUALS
        var body = ""
        for (key, value) in postData {
            body += "\(key)=\(value)&"
        }
        request.httpBody = body.data(using: String.Encoding.utf8, allowLossyConversion: false)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
#else
        let jsonData = try? JSONSerialization.data(withJSONObject: postData)
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
#endif

        let loadDataTask = session.dataTask(with: request as URLRequest) { (data, response, error) -> Void in
            if let errorResponse = error {
                completion(nil, errorResponse as NSError)
            } else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    completion(data, nil)
                } else {
                    let error = NSError(domain:self.reverse_domain, code:httpResponse.statusCode, userInfo:[NSLocalizedDescriptionKey : "HTTP status code \(httpResponse.statusCode)."])
                    completion(data, error)
                }
            } else {
                let error = NSError(domain:self.reverse_domain, code:NSURLErrorUnknown, userInfo:[NSLocalizedDescriptionKey : "HTTP request returned no data and no error."])
                completion(nil, error)
            }
        }
        loadDataTask.resume()
    }

    /// Load data via GET and return in completion with or without error
    func getDataFromURL(_ url: URL, completion: @escaping (_ data: Data?, _ error: NSError?) -> Void) {
        println("getDataFromURL: " + url.absoluteString)

        let session = URLSession.shared
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "GET"

        let token = RWFrameworkConfig.getConfigValueAsString("token", group: RWFrameworkConfig.ConfigGroup.client)
        if token.lengthOfBytes(using: String.Encoding.utf8) > 0 {
            request.addValue("token \(token)", forHTTPHeaderField: "Authorization")
        }

        let loadDataTask = session.dataTask(with: request as URLRequest) { (data, response, error) -> Void in
            if let errorResponse = error {
                completion(nil, errorResponse as NSError)
            } else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    completion(data, nil)
                } else {
                    let error = NSError(domain:self.reverse_domain, code:httpResponse.statusCode, userInfo:[NSLocalizedDescriptionKey : "HTTP status code \(httpResponse.statusCode)."])
                    completion(data, error)
                }
            } else {
                let error = NSError(domain:self.reverse_domain, code:NSURLErrorUnknown, userInfo:[NSLocalizedDescriptionKey : "HTTP request returned no data and no error."])
                completion(nil, error)
            }
        }
        loadDataTask.resume()
    }

    func getDataFromURLNoToken(_ url: URL, completion: @escaping (_ data: Data?, _ error: NSError?) -> Void) {
        println("getDataFromURLNoToken: " + url.absoluteString)
        
        let session = URLSession.shared
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "GET"
        
        let loadDataTask = session.dataTask(with: request as URLRequest) { (data, response, error) -> Void in
            if let errorResponse = error {
                completion(nil, errorResponse as NSError)
            } else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    completion(data, nil)
                } else {
                    let error = NSError(domain:self.reverse_domain, code:httpResponse.statusCode, userInfo:[NSLocalizedDescriptionKey : "HTTP status code \(httpResponse.statusCode)."])
                    completion(data, error)
                }
            } else {
                let error = NSError(domain:self.reverse_domain, code:NSURLErrorUnknown, userInfo:[NSLocalizedDescriptionKey : "HTTP request returned no data and no error."])
                completion(nil, error)
            }
        }
        loadDataTask.resume()
    }

// MARK: - NSURLSessionDelegate

// MARK: - NSURLSessionTaskDelegate

// MARK: - NSURLSessionDataDelegate

}

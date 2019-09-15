//
//  RWFrameworkHTTP.swift
//  RWFramework
//
//  Created by Joe Zobkiw on 2/6/15.
//  Copyright (c) 2015 Roundware. All rights reserved.
//

import Foundation
import MobileCoreServices
import Promises

extension RWFramework: URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate {
    func httpPostUsers(_ device_id: String, client_type: String, client_system: String) -> Promise<Data> {
        return postData(
            to: RWFrameworkURLFactory.postUsersURL(),
            postData: [
                "device_id": device_id,
                "client_type": client_type,
                "client_system": client_system
            ]
        )
    }

    func httpPostSessions(_ project_id: NSNumber, timezone: String, client_system: String, language: String) -> Promise<Data> {
        return postData(
            to: RWFrameworkURLFactory.postSessionsURL(),
            postData: [
                "project_id": project_id,
                "timezone": timezone,
                "client_system": client_system,
                "language": language
            ]
        )
    }

    func httpGetProjectsId(_ project_id: NSNumber, session_id: NSNumber) -> Promise<Data> {
        return getData(
            from: RWFrameworkURLFactory.getProjectsIdURL(project_id, session_id: session_id)
        )
    }

    func httpGetUIConfig(_ project_id: NSNumber, session_id: NSNumber) -> Promise<Data> {
        return getData(
            from: RWFrameworkURLFactory.getUIConfigURL(project_id, session_id: session_id)
        )
    }

    func httpGetProjectsIdTags(_ project_id: NSNumber, session_id: NSNumber) -> Promise<Data> {
        return getData(
            from: RWFrameworkURLFactory.getProjectsIdTagsURL(project_id, session_id: session_id)
        )
    }

    func httpGetProjectsIdUIGroups(_ project_id: NSNumber, session_id: NSNumber) -> Promise<Data> {
        return getData(
            from: RWFrameworkURLFactory.getProjectsIdUIGroupsURL(project_id, session_id: session_id)
        )
    }
    
    func httpGetTagCategories() -> Promise<Data> {
        return getData(from: RWFrameworkURLFactory.getTagCategoriesURL())
    }

    func httpPostStreams(
        _ session_id: NSNumber,
        latitude: String = "0.1",
        longitude: String = "0.1"
    ) -> Promise<Data> {
        return postData(
            to: RWFrameworkURLFactory.postStreamsURL(),
            postData: [
                "session_id": session_id,
                "latitude": latitude,
                "longitude": longitude
            ]
        )
    }
    
    func httpPatchStreamsId(
        _ stream_id: String,
        tagIds: String? = nil,
        latitude: String? = nil,
        longitude: String? = nil,
        streamPatchOptions: [String: Any] = [:]
    ) -> Promise<Data> {
        var postData = [String: Any]()
        if let lat = latitude { postData["latitude"] = lat }
        if let lng = longitude { postData["longitude"] = lng }
        if let ids = tagIds { postData["tag_ids"] = ids }
        // append postData with any key/value pairs that exist in optionalParams dictionary; if empty dictionary, append nothing
        postData.merge(streamPatchOptions) { (first, _) in first }
        
        return patchData(
            to: RWFrameworkURLFactory.patchStreamsIdURL(stream_id),
            postData: postData
        )
    }

    func httpPatchStreamsId(_ stream_id: String, tag_ids: String) -> Promise<Data> {
        return patchData(
            to: RWFrameworkURLFactory.patchStreamsIdURL(stream_id),
            postData: ["tag_ids": tag_ids]
        )
    }

    func httpPostStreamsIdHeartbeat(_ stream_id: String) -> Promise<Data> {
        return postData(
            to: RWFrameworkURLFactory.postStreamsIdHeartbeatURL(stream_id)
        )
    }

    func httpPostStreamsIdReplay(_ stream_id: String) -> Promise<Data> {
        return postData(
            to: RWFrameworkURLFactory.postStreamsIdReplayURL(stream_id)
        )
    }
    
    func httpPostStreamsIdSkip(_ stream_id: String) -> Promise<Data> {
        return postData(
            to: RWFrameworkURLFactory.postStreamsIdSkipURL(stream_id)
        )
    }
    
    func httpPostStreamsIdPause(_ stream_id: String) -> Promise<Data> {
        return postData(
            to: RWFrameworkURLFactory.postStreamsIdPauseURL(stream_id)
        )
    }
    
    func httpPostStreamsIdResume(_ stream_id: String) -> Promise<Data> {
        return postData(
            to: RWFrameworkURLFactory.postStreamsIdResumeURL(stream_id)
        )
    }
    
    func httpGetStreamsIdIsActive(_ stream_id: String) -> Promise<Data> {
        return getData(from: RWFrameworkURLFactory.getStreamsIdIsActiveURL(stream_id))
    }

    func httpPostEnvelopes(_ session_id: NSNumber) -> Promise<Data> {
        return postData(
            to: RWFrameworkURLFactory.postEnvelopesURL(),
            postData: ["session_id": session_id]
        )
    }

    func httpPatchEnvelopesId(_ media: Media, session_id: NSNumber) -> Promise<Data> {
        let serverMediaType = mapMediaTypeToServerMediaType(media.mediaType)
        let postData = ["session_id": session_id,
                        "media_type": serverMediaType.rawValue,
                        "latitude": media.latitude.stringValue,
                        "longitude": media.longitude.stringValue,
                        "tag_ids": media.tagIDs,
                        "user_id": media.userID,
                        "description": media.desc] as [String : Any]
        return patchFileAndData(
            to: RWFrameworkURLFactory.patchEnvelopesIdURL(media.envelopeID.stringValue),
            filePath: media.string,
            postData: postData)
    }
    
    func httpGetAudioTracks(_ dict: [String:String]) -> Promise<Data> {
        return getData(from: RWFrameworkURLFactory.getAudioTracksURL(dict))
    }

    func httpGetTimedAssets(_ dict: [String:String]) -> Promise<Data> {
        return getData(from: RWFrameworkURLFactory.getTimedAssetsURL(dict))
    }

    public func httpGetAssets(_ dict: [String:String]) -> Promise<Data> {
        return getData(from: RWFrameworkURLFactory.getAssetsURL(dict))
    }

    func httpGetBlockedAssets(_ project_id: NSNumber, session_id: NSNumber) -> Promise<Data> {
        return getData(from: RWFrameworkURLFactory.getBlockedAssetsURL(project_id, session_id: session_id))
    }
    
    func httpPatchAssetsId(_ asset_id: String, postData: [String: Any] = [:]) -> Promise<Data> {
        return patchData(
            to: RWFrameworkURLFactory.patchAssetsIdURL(asset_id),
            postData: postData
        )
    }

    func httpGetAssetsId(_ asset_id: String) -> Promise<Data> {
        return getData(from: RWFrameworkURLFactory.getAssetsIdURL(asset_id))
    }

    func httpPostAssetsIdVotes(_ asset_id: String, session_id: NSNumber, vote_type: String, value: NSNumber = 0) -> Promise<Data> {
        return postData(
            to: RWFrameworkURLFactory.postAssetsIdVotesURL(asset_id),
            postData: ["session_id": session_id, "vote_type": vote_type, "value": value.stringValue]
        )
    }

    func httpGetAssetsIdVotes(_ asset_id: String) -> Promise<Data> {
        return getData(from: RWFrameworkURLFactory.getAssetsIdVotesURL(asset_id))
    }

    func httpGetVotesSummary(type: String?, projectId: String?, assetId: String?) -> Promise<Data> {
        return getData(from: RWFrameworkURLFactory.getVotesSummaryURL([
            "type": type ?? "",
            "asset_id": assetId ?? "",
            "project_id": projectId ?? ""
        ]))
    }
    
    
    func httpGetSpeakers(_ dict: [String:String]) -> Promise<Data> {
        return getData(from: RWFrameworkURLFactory.getSpeakersURL(dict))
    }

    func httpPostEvents(_ session_id: NSNumber, event_type: String, data: String?, latitude: String, longitude: String, client_time: String, tag_ids: String) -> Promise<Data> {
        let url = RWFrameworkURLFactory.postEventsURL()
        let body = ["session_id": session_id, "event_type": event_type, "data": data ?? "", "latitude": latitude, "longitude": longitude, "client_time": client_time, "tag_ids": tag_ids] as [String : Any]
        return postData(to: url, postData: body)
    }

// MARK: - Generic functions

    // Upload file and load data via PATCH and return in completion with or without error
    func patchFileAndData(to urlPath: String, filePath: String, postData: Dictionary<String,Any>) -> Promise<Data> {
        let url = URL(string: urlPath)!
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
            return Promise(error)
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

        return session.uploadTaskPromise(with: request as URLRequest, from: data as Data)
    }

    // Load data via PATCH and return in completion with or without error
    func patchData(to urlPath: String, postData: Dictionary<String,Any>) -> Promise<Data> {
        let url = URL(string: urlPath)!
        println("patchData: " + url.absoluteString + " postData = " + postData.description)

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

        return session.dataTaskPromise(with: request as URLRequest)
    }

    // Load data via POST and return in completion with or without error
    func postData(to urlPath: String, postData: Dictionary<String, Any> = [:]) -> Promise<Data> {
        let url = URL(string: urlPath)!
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

        return session.dataTaskPromise(with: request as URLRequest)
    }

    /// Load data via GET and return in completion with or without error
    func getData(from urlPath: String) -> Promise<Data> {
        let url = URL(string: urlPath)!
        println("getDataFromURL: " + url.absoluteString)

        let session = URLSession.shared
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "GET"

        let token = RWFrameworkConfig.getConfigValueAsString("token", group: RWFrameworkConfig.ConfigGroup.client)
        if token.lengthOfBytes(using: String.Encoding.utf8) > 0 {
            request.addValue("token \(token)", forHTTPHeaderField: "Authorization")
        }

        return session.dataTaskPromise(with: request as URLRequest)
    }

    func getDataNoToken(from urlPath: String) -> Promise<Data> {
        let url = URL(string: urlPath)!
        println("getDataFromURLNoToken: " + url.absoluteString)
        
        let session = URLSession.shared
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "GET"
        
        return session.dataTaskPromise(with: request as URLRequest)
    }

// MARK: - NSURLSessionDelegate

// MARK: - NSURLSessionTaskDelegate

// MARK: - NSURLSessionDataDelegate

}

fileprivate extension URLSession {
    func dataTaskPromise(with request: URLRequest) -> Promise<Data> {
        return Promise<Data> { fulfill, reject in
            self.dataTask(with: request) { (data, response, error) -> Void in
                if let errorResponse = error {
                    reject(errorResponse as NSError)
                } else if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        fulfill(data!)
                    } else {
                        let error = NSError(domain: RWFramework.sharedInstance.reverse_domain, code: httpResponse.statusCode, userInfo:[NSLocalizedDescriptionKey : "HTTP status code \(httpResponse.statusCode)."])
                        reject(error)
                    }
                } else {
                    let error = NSError(domain: RWFramework.sharedInstance.reverse_domain, code:NSURLErrorUnknown, userInfo:[NSLocalizedDescriptionKey : "HTTP request returned no data and no error."])
                    reject(error)
                }
            }.resume()
        }
    }
    
    func uploadTaskPromise(with request: URLRequest, from data: Data) -> Promise<Data> {
        return Promise<Data> { fulfill, reject in
            self.uploadTask(with: request, from: data) { (data, response, error) in
                if let errorResponse = error {
                    reject(errorResponse as NSError)
                } else if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        fulfill(data!)
                    } else {
                        let error = NSError(domain:RWFramework.sharedInstance.reverse_domain, code:httpResponse.statusCode, userInfo:[NSLocalizedDescriptionKey : "HTTP status code \(httpResponse.statusCode)."])
                        reject(error)
                    }
                } else {
                    let error = NSError(domain:RWFramework.sharedInstance.reverse_domain, code:NSURLErrorUnknown, userInfo:[NSLocalizedDescriptionKey : "HTTP request returned no data and no error."])
                    reject(error)
                }
            }.resume()
        }
    }
}

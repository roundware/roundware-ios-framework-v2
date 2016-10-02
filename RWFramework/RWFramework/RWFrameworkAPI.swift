//
//  RWFrameworkAPI.swift
//  RWFramework
//
//  Created by Joe Zobkiw on 2/17/15.
//  Copyright (c) 2015 Roundware. All rights reserved.
//

import Foundation
import CoreLocation

extension RWFramework {

// MARK: POST users

    func apiPostUsers(device_id: String, client_type: String) {
        let token = RWFrameworkConfig.getConfigValueAsString("token", group: RWFrameworkConfig.ConfigGroup.Client)
        if (token.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0) {
            postUsersSucceeded = true
            apiPostSessions()
        } else {
            httpPostUsers(device_id, client_type: client_type) { (data, error) -> Void in
                if (data != nil) && (error == nil) {
                    self.postUsersSuccess(data!)
                    self.rwPostUsersSuccess(data)
                } else if (error != nil) {
                    self.rwPostUsersFailure(error)
                    self.apiProcessError(data, error: error!, caller: "apiPostUsers")
                }
            }
        }
    }

    // EXAMPLE CODE TO BE DELETED
    func tobedeleted () {
        let jsonStr = "{\"weather\":[{\"id\":804,\"main\":\"Clouds\",\"description\":\"overcast clouds\",\"icon\":\"04d\"}],}"
        let data = jsonStr.dataUsingEncoding(NSASCIIStringEncoding, allowLossyConversion: false)
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers)

            if let dict = json as? [String: AnyObject] {
                if let weather = dict["weather"] as? [AnyObject] {
                    for dict2 in weather {
                        let id = dict2["id"] as? Int
                        let main = dict2["main"] as? String
                        let description = dict2["description"] as? String
                        print(id)
                        print(main)
                        print(description)
                    }
                }
            }

        }
        catch {
            print(error)
        }
    }

    func postUsersSuccess(data: NSData) {
        // http://stackoverflow.com/questions/24671249/parse-json-in-swift-anyobject-type/27206145#27206145
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers)

            if let dict = json as? [String: AnyObject] {
                if let username = dict["username"] as? String {
                    RWFrameworkConfig.setConfigValue("username", value: username, group: RWFrameworkConfig.ConfigGroup.Client)
                }
                if let token = dict["token"] as? String {
                    RWFrameworkConfig.setConfigValue("token", value: token, group: RWFrameworkConfig.ConfigGroup.Client)
                }
            }

            postUsersSucceeded = true

            apiPostSessions()
        }
        catch {
            print(error)
        }
    }


// MARK: POST sessions

    func apiPostSessions() {
        let project_id = RWFrameworkConfig.getConfigValueAsNumber("project_id").stringValue
        let client_system = clientSystem()
        let language = preferredLanguage()

        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "ZZZ"
        let timezone = dateFormatter.stringFromDate(NSDate())

        httpPostSessions(project_id, timezone: timezone, client_system: client_system, language: language) { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                self.postSessionsSuccess(data!)
                self.rwPostSessionsSuccess(data)
            } else if (error != nil) {
                self.rwPostSessionsFailure(error)
                self.apiProcessError(data, error: error!, caller: "apiPostSessions")
            }
        }
    }

    func postSessionsSuccess(data: NSData) {
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers)

            var session_id : String = ""
            if let dict = json as? [String: AnyObject] {
                if let _session_id = dict["session_id"] as? String {
                    session_id = _session_id
                    RWFrameworkConfig.setConfigValue("session_id", value: session_id, group: RWFrameworkConfig.ConfigGroup.Client)
                }
            }

            postSessionsSucceeded = true

            let project_id = RWFrameworkConfig.getConfigValueAsString("project_id")
            apiGetProjectsId(project_id, session_id: session_id)
        }
        catch {
            print(error)
        }
    }


// MARK: GET projects id

    func apiGetProjectsId(project_id: String, session_id: String) {
        httpGetProjectsId(project_id, session_id: session_id) { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                self.getProjectsIdSuccess(data!, project_id: project_id, session_id: session_id)
                self.rwGetProjectsIdSuccess(data)
            } else if (error != nil) {
                self.rwGetProjectsIdFailure(error)
                self.apiProcessError(data, error: error!, caller: "apiGetProjectsId")
            }
        }
    }

    func getProjectsIdSuccess(data: NSData, project_id: String, session_id: String) {
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers)

            if let dict = json as? [String: AnyObject] {
                RWFrameworkConfig.setConfigDataAsDictionary(data, key: "project")

                reverse_domain = RWFrameworkConfig.getConfigValueAsString("reverse_domain")

                // TODO: where is this going to come from?
                func configDisplayStartupMessage() {
                    let startupMessage = RWFrameworkConfig.getConfigValueAsString("startup_message", group: RWFrameworkConfig.ConfigGroup.Notifications)
                    if (startupMessage.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0) {
                        self.rwUpdateStatus(startupMessage)
                    }
                }
                configDisplayStartupMessage()

                if letFrameworkRequestWhenInUseAuthorizationForLocation {
                    _ = requestWhenInUseAuthorizationForLocation()
                }

                let listen_enabled = RWFrameworkConfig.getConfigValueAsBool("listen_enabled")
                if (listen_enabled) {
                    let geo_listen_enabled = RWFrameworkConfig.getConfigValueAsBool("geo_listen_enabled")
                    if (!geo_listen_enabled) {
                        apiPostStreams()
                    }
                    startHeartbeatTimer()
                }

                let speak_enabled = RWFrameworkConfig.getConfigValueAsBool("speak_enabled")
                if (speak_enabled) {
                    startAudioTimer()
                    startUploadTimer()
                    rwReadyToRecord()
                }

                getProjectsIdSucceeded = true

                apiGetProjectsIdTags(project_id, session_id: session_id)
            }
        }
        catch {
            print(error)
        }
    }


// MARK: GET projects id tags

    func apiGetProjectsIdTags(project_id: String, session_id: String) {
        httpGetProjectsIdTags(project_id, session_id: session_id) { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                self.getProjectsIdTagsSuccess(data!, project_id: project_id, session_id: session_id)
                self.rwGetProjectsIdTagsSuccess(data)
            } else if (error != nil) {
                self.rwGetProjectsIdTagsFailure(error)
                self.apiProcessError(data, error: error!, caller: "apiGetProjectsIdTags")
            }
        }
    }

    func getProjectsIdTagsSuccess(data: NSData, project_id: String, session_id: String) {
        do {

            let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers)

            if let dict = json as? [String: AnyObject] {
                let reset_tag_defaults_on_startup = RWFrameworkConfig.getConfigValueAsBool("reset_tag_defaults_on_startup")

                // Listen
                if let listenArray = dict["listen"] as? [String: AnyObject] {
                    NSUserDefaults.standardUserDefaults().setObject(listenArray, forKey: "tags_listen")

                    // Save defaults as "current settings" for listen tags if they are not already set
                    for (index: _, dict: _) in listenArray {
                        let code = dict["code"]
                        let defaults = dict["defaults"]
                        let defaultsKeyName = "tags_listen_\(code)_current"
                        let current: AnyObject? = NSUserDefaults.standardUserDefaults().objectForKey(defaultsKeyName)
                        if (current == nil || reset_tag_defaults_on_startup) {
                            NSUserDefaults.standardUserDefaults().setObject(defaults!.object, forKey: defaultsKeyName)
                        }
                    }
                }

                // Speak
                if let speakArray = dict["speak"] as? [String: AnyObject] {
                    NSUserDefaults.standardUserDefaults().setObject(speakArray, forKey: "tags_speak")

                    // Save defaults as "current settings" for speak tags if they are not already set
                    for (index: _, dict: _) in speakArray {
                        let code = dict["code"]
                        let defaults = dict["defaults"]
                        let defaultsKeyName = "tags_speak_\(code)_current"
                        let current: AnyObject? = NSUserDefaults.standardUserDefaults().objectForKey(defaultsKeyName)
                        if (current == nil || reset_tag_defaults_on_startup) {
                            NSUserDefaults.standardUserDefaults().setObject(defaults!.object, forKey: defaultsKeyName)
                        }
                    }
                }

                getProjectsIdTagsSucceeded = true
            }
        }
        catch {
            print(error)
        }
    }

// MARK: POST streams

    func apiPostStreams() {
        if (requestStreamInProgress == true) { return }
        if (requestStreamSucceeded == true) { return }
        if (postSessionsSucceeded == false) { return }

        requestStreamInProgress = true

        let session_id = RWFrameworkConfig.getConfigValueAsNumber("session_id", group: RWFrameworkConfig.ConfigGroup.Client).stringValue

        httpPostStreams(session_id) { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                self.postStreamsSuccess(data!, session_id: session_id)
                self.rwPostStreamsSuccess(data)
            } else if (error != nil) {
                self.rwPostStreamsFailure(error)
                self.apiProcessError(data, error: error!, caller: "apiPostStreams")
            }
            self.requestStreamInProgress = false
        }
    }

    func postStreamsSuccess(data: NSData, session_id: String) {
        do {

            let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers)

            if let dict = json as? [String: AnyObject] {
                if let stream_url = dict["stream_url"] as? String {
                    self.streamURL = NSURL(string: stream_url)
                    if let stream_id = dict["stream_id"] as? NSNumber {
                        self.streamID = stream_id.integerValue
                        self.createPlayer()
                        self.requestStreamSucceeded = true
                    }
                }

                // TODO: can we still expect this here?
                func requestStreamDisplayUserMessage(userMessage: String?) {
                    if (userMessage != nil && userMessage!.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0) {
                        self.rwUpdateStatus(userMessage!)
                    }
                }
                requestStreamDisplayUserMessage(dict["user_message"] as? String)
            }
        }
        catch {
            print(error)
        }
    }

// MARK: PATCH streams id

    func apiPatchStreamsIdWithLocation(newLocation: CLLocation?) {
        if (requestStreamSucceeded == false) { return }
        if (self.streamID == 0) { return }
        if (newLocation == nil) { return }

        let latitude = doubleToStringWithZeroAsEmptyString(newLocation!.coordinate.latitude)
        let longitude = doubleToStringWithZeroAsEmptyString(newLocation!.coordinate.longitude)

        httpPatchStreamsId(self.streamID.description, latitude: latitude, longitude: longitude, completion: { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                self.patchStreamsIdSuccess(data!)
                self.rwPatchStreamsIdSuccess(data)
            } else if (error != nil) {
                self.rwPatchStreamsIdFailure(error)
                self.apiProcessError(data, error: error!, caller: "apiPatchStreamsIdWithLocation")
            }
        })
    }

    func apiPatchStreamsIdWithTags(tag_ids: String) {
        if (requestStreamSucceeded == false) { return }
        if (self.streamID == 0) { return }

        httpPatchStreamsId(self.streamID.description, tag_ids: tag_ids, completion: { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                self.patchStreamsIdSuccess(data!)
                self.rwPatchStreamsIdSuccess(data)
            } else if (error != nil) {
                self.rwPatchStreamsIdFailure(error)
                self.apiProcessError(data, error: error!, caller: "apiPatchStreamsIdWithTags")
            }
        })
    }

    func patchStreamsIdSuccess(data: NSData) {
        //let dict = JSON(data: data)
//        println(dict)
        // does nothing for now
    }

// MARK: POST streams id heartbeat

    func apiPostStreamsIdHeartbeat() {
        if (requestStreamSucceeded == false) { return }
        if (self.streamID == 0) { return }

        httpPostStreamsIdHeartbeat(self.streamID.description, completion: { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                self.postStreamsIdHeartbeatSuccess(data!)
                self.rwPostStreamsIdHeartbeatSuccess(data)
            } else if (error != nil) {
                self.rwPostStreamsIdHeartbeatFailure(error)
                self.apiProcessError(data, error: error!, caller: "apiPostStreamsIdHeartbeat")
            }
        })
    }

    func postStreamsIdHeartbeatSuccess(data: NSData) {
        //let dict = JSON(data: data)
//        println(dict)
        // does nothing for now
    }

// MARK: POST streams id next

    func apiPostStreamsIdNext() {
        if (requestStreamSucceeded == false) { return }
        if (self.streamID == 0) { return }

        httpPostStreamsIdNext(self.streamID.description, completion: { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                self.postStreamsIdNextSuccess(data!)
                self.rwPostStreamsIdNextSuccess(data)
            } else if (error != nil) {
                self.rwPostStreamsIdNextFailure(error)
                self.apiProcessError(data, error: error!, caller: "apiPostStreamsIdNext")
            }
        })
    }

    func postStreamsIdNextSuccess(data: NSData) {
        //let dict = JSON(data: data)
//        println(dict)
        // does nothing for now
    }

// MARK: GET streams id current

    func apiGetStreamsIdCurrent() {
        if (requestStreamSucceeded == false) { return }
        if (self.streamID == 0) { return }

        httpGetStreamsIdCurrent(self.streamID.description, completion: { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                self.getStreamsIdCurrentSuccess(data!)
                self.rwGetStreamsIdCurrentSuccess(data)
            } else if (error != nil) {
                self.rwGetStreamsIdCurrentFailure(error)
                self.apiProcessError(data, error: error!, caller: "apiGetStreamsIdCurrent")
            }
        })
    }

    func getStreamsIdCurrentSuccess(data: NSData) {
        //let dict = JSON(data: data)
//        println(dict)
        // does nothing for now
    }

// MARK: POST envelopes

    func apiPostEnvelopes(success:(envelopeID: Int) -> Void) {
        let session_id = RWFrameworkConfig.getConfigValueAsNumber("session_id", group: RWFrameworkConfig.ConfigGroup.Client).stringValue

        httpPostEnvelopes(session_id) { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                self.postEnvelopesSuccess(data!, session_id: session_id, success: success)
                self.rwPostEnvelopesSuccess(data)
            } else if (error != nil) {
                self.rwPostEnvelopesFailure(error)
                self.apiProcessError(data, error: error!, caller: "apiPostEnvelopes")
            }
        }
    }

    func postEnvelopesSuccess(data: NSData, session_id: String, success:(envelopeID: Int) -> Void) {

        do {
            let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers)
            if let dict = json as? [String: AnyObject] {
                if let envelope_id = dict["envelope_id"] as? NSNumber {
                    success(envelopeID: envelope_id.integerValue)
                }
            }
        }
        catch {
            print(error)
        }

    }

// MARK: PATCH envelopes id

    func apiPatchEnvelopesId(media: Media, success:() -> Void, failure:(error: NSError) -> Void) {
        let session_id = RWFrameworkConfig.getConfigValueAsNumber("session_id", group: RWFrameworkConfig.ConfigGroup.Client).stringValue

        httpPatchEnvelopesId(media, session_id: session_id) { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                success()
                self.rwPatchEnvelopesIdSuccess(data)
            } else if (error != nil) {
                failure(error: error!)
                self.rwPatchEnvelopesIdFailure(error)
                self.apiProcessError(data, error: error!, caller: "apiPatchEnvelopesId")
            }
        }
    }

// MARK: POST assets

    // Not needed on client - not implementing for now

// MARK: GET assets PUBLIC

    public func apiGetAssets(dict: [String:String], success:(data: NSData?) -> Void, failure:(error: NSError) -> Void) {
        httpGetAssets(dict) { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                success(data: data)
                self.rwGetAssetsSuccess(data)
            } else if (error != nil) {
                failure(error: error!)
                self.rwGetAssetsFailure(error)
                self.apiProcessError(data, error: error!, caller: "apiGetAssets")
            }
        }
    }

// MARK: GET assets id PUBLIC

    public func apiGetAssetsId(asset_id: String, success:(data: NSData?) -> Void, failure:(error: NSError) -> Void) {
        httpGetAssetsId(asset_id) { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                success(data: data)
                self.rwGetAssetsIdSuccess(data)
            } else if (error != nil) {
                failure(error: error!)
                self.rwGetAssetsIdFailure(error)
                self.apiProcessError(data, error: error!, caller: "apiGetAssetsId")
            }
        }
    }

// MARK: POST assets id votes

    public func apiPostAssetsIdVotes(asset_id: String, vote_type: String, value: NSNumber = 0, success:(data: NSData?) -> Void, failure:(error: NSError) -> Void) {
        let session_id = RWFrameworkConfig.getConfigValueAsNumber("session_id", group: RWFrameworkConfig.ConfigGroup.Client).stringValue

        httpPostAssetsIdVotes(asset_id, session_id: session_id, vote_type: vote_type, value: value) { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                success(data: data)
                self.rwPostAssetsIdVotesSuccess(data)
            } else if (error != nil) {
                failure(error: error!)
                self.rwPostAssetsIdVotesFailure(error)
                self.apiProcessError(data, error: error!, caller: "apiPostAssetsIdVotes")
            }
        }
    }

// MARK: GET assets id votes

    public func apiGetAssetsIdVotes(asset_id: String, success:(data: NSData?) -> Void, failure:(error: NSError) -> Void) {
        httpGetAssetsIdVotes(asset_id) { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                success(data: data)
                self.rwGetAssetsIdVotesSuccess(data)
            } else if (error != nil) {
                failure(error: error!)
                self.rwGetAssetsIdVotesFailure(error)
                self.apiProcessError(data, error: error!, caller: "apiGetAssetsIdVotes")
            }
        }
    }

// MARK: POST events

    func apiPostEvents(event_type: String, data: String?, success:(data: NSData?) -> Void, failure:(error: NSError) -> Void) {
        let session_id = RWFrameworkConfig.getConfigValueAsNumber("session_id", group: RWFrameworkConfig.ConfigGroup.Client).stringValue
        let latitude = doubleToStringWithZeroAsEmptyString(lastRecordedLocation.coordinate.latitude)
        let longitude = doubleToStringWithZeroAsEmptyString(lastRecordedLocation.coordinate.longitude)

        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss" // 2015-03-13T13:00:09
        let client_time = dateFormatter.stringFromDate(NSDate())
        let tag_ids = getAllListenTagsCurrentAsString() + "," + getAllSpeakTagsCurrentAsString()

        httpPostEvents(session_id, event_type: event_type, data: data, latitude: latitude, longitude: longitude, client_time: client_time, tag_ids: tag_ids) { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                success(data: data)
                self.rwPostEventsSuccess(data)
            } else if (error != nil) {
                failure(error: error!)
                self.rwPostEventsFailure(error)
                self.apiProcessError(data, error: error!, caller: "apiPostEvents")
            }
        }
    }

// MARK: GET events id

    // Not needed on client - not implementing for now

// MARK: GET listenevents

    // Not needed on client - not implementing for now

// MARK: GET listenevents id

    // Not needed on client - not implementing for now

// MARK: utilities

    func apiProcessError(data: NSData?, error: NSError, caller: String) {
        let detailStringValue = ""
//        if (data != nil) {
//            let dict = JSON(data: data!)
//            let detail = dict["detail"]
//            detailStringValue = detail.stringValue
//            self.println("API ERROR: \(caller): \(detailStringValue) NSError = \(error.code) \(error.description)")
//        }
        if (caller != "apiPostEvents") { // Don't log errors that occur while reporting errors
            logToServer("client_error", data: "\(caller): \(detailStringValue) NSError = \(error.code) \(error.description)")
        }
    }
}

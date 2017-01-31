//
//  RWFrameworkAPI.swift
//  RWFramework
//
//  Created by Joe Zobkiw on 2/17/15.
//  Copyright (c) 2015 Roundware. All rights reserved.
//

import Foundation
import CoreLocation
import SwiftyJSON

extension RWFramework {

// MARK: POST users

    func apiPostUsers(device_id: String, client_type: String) {
        let token = RWFrameworkConfig.getConfigValueAsString(key: "token", group: RWFrameworkConfig.ConfigGroup.Client)
        if (token.lengthOfBytes(using: String.Encoding.utf8) > 0) {
            postUsersSucceeded = true
            apiPostSessions()
        } else {
            httpPostUsers(device_id: device_id, client_type: client_type) { (data, error) -> Void in
                if (data != nil) && (error == nil) {
                    self.postUsersSuccess(data: data!)
                    self.rwPostUsersSuccess(data: data)
                } else if (error != nil) {
                    self.rwPostUsersFailure(error: error)
                    self.apiProcessError(data: data, error: error!, caller: "apiPostUsers")
                }
            }
        }
    }

    func postUsersSuccess(data: NSData) {
        let dict = JSON(data: data as Data) // JSON returned as a Dictionary

        let username = dict["username"]
        RWFrameworkConfig.setConfigValue(key: "username", value: username.stringValue, group: RWFrameworkConfig.ConfigGroup.Client)
        let token = dict["token"]
        RWFrameworkConfig.setConfigValue(key: "token", value: token.stringValue, group: RWFrameworkConfig.ConfigGroup.Client)

        postUsersSucceeded = true

        apiPostSessions()
    }


// MARK: POST sessions

    func apiPostSessions() {
        let project_id = RWFrameworkConfig.getConfigValueAsNumber(key: "project_id").stringValue
        let client_system = clientSystem()
        let language = preferredLanguage()

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "ZZZ"
        let timezone = dateFormatter.string(from: NSDate() as Date)

        httpPostSessions(project_id: project_id, timezone: timezone, client_system: client_system, language: language) { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                self.postSessionsSuccess(data: data!)
                self.rwPostSessionsSuccess(data: data)
            } else if (error != nil) {
                self.rwPostSessionsFailure(error: error)
                self.apiProcessError(data: data, error: error!, caller: "apiPostSessions")
            }
        }
    }

    func postSessionsSuccess(data: NSData) {
        let dict = JSON(data: data as Data)
        print("sessions success")

        let session_id = dict["session_id"]
        RWFrameworkConfig.setConfigValue(key:"session_id", value: session_id.numberValue, group: RWFrameworkConfig.ConfigGroup.Client)

        postSessionsSucceeded = true

        //do not assume single project id
//        let project_id = RWFrameworkConfig.getConfigValueAsNumber(key: "project_id")
//        apiGetProjectsId(project_id.stringValue, session_id: session_id.stringValue)
    }


// TODO get projects index?

// MARK: GET projects id

    func apiGetProjectsId(project_id: String, session_id: String) {
        httpGetProjectsId(project_id: project_id, session_id: session_id) { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                self.getProjectsIdSuccess(data: data!, project_id: project_id, session_id: session_id)
                self.rwGetProjectsIdSuccess(data: data)
            } else if (error != nil) {
                self.rwGetProjectsIdFailure(error: error)
                self.apiProcessError(data: data, error: error!, caller: "apiGetProjectsId")
            }
        }
    }



    func getProjectsIdSuccess(data: NSData, project_id: String, session_id: String) {
        let dict = JSON(data: data as Data)


        // TODO check respect for and availability to API of
        // reverse_domain
        // listen_enabled
        // geo_listen_enabled
        // startup_message
        // speak_enabled

        RWFrameworkConfig.setConfigDataAsDictionary(data: data, key: "project")
        reverse_domain = RWFrameworkConfig.getConfigValueAsString(key: "reverse_domain")

        // DEPRECATED
//        func configDisplayStartupMessage() {
//            let startupMessage = RWFrameworkConfig.getConfigValueAsString("startup_message", group: RWFrameworkConfig.ConfigGroup.Notifications)
//            if (startupMessage.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0) {
//                self.rwUpdateStatus(startupMessage)
//            }
//        }
//        configDisplayStartupMessage()

        if letFrameworkRequestWhenInUseAuthorizationForLocation {
            _ = requestWhenInUseAuthorizationForLocation()
        }

        let listen_enabled = RWFrameworkConfig.getConfigValueAsBool(key: "listen_enabled")
        if (listen_enabled) {
            let geo_listen_enabled = RWFrameworkConfig.getConfigValueAsBool(key: "geo_listen_enabled")
            if (!geo_listen_enabled) {
                apiPostStreams()
            }
            startHeartbeatTimer()
        }

        let speak_enabled = RWFrameworkConfig.getConfigValueAsBool(key: "speak_enabled")
        if (speak_enabled) {
            startAudioTimer()
            startUploadTimer()
            rwReadyToRecord()
        }

        getProjectsIdSucceeded = true

        apiGetProjectsIdTags(project_id: project_id, session_id: session_id)
    }


// MARK: GET projects id tags

    func apiGetProjectsIdTags(project_id: String, session_id: String) {
        httpGetProjectsIdTags(project_id: project_id, session_id: session_id) { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                self.getProjectsIdTagsSuccess(data: data!, project_id: project_id, session_id: session_id)
                self.rwGetProjectsIdTagsSuccess(data: data)
            } else if (error != nil) {
                self.rwGetProjectsIdTagsFailure(error: error)
                self.apiProcessError(data: data, error: error!, caller: "apiGetProjectsIdTags")
            }
        }
    }

    func getProjectsIdTagsSuccess(data: NSData, project_id: String, session_id: String) {
        //NEW
        //let dict = JSON(data: data)
        //dump(dict)
        //let tagsArray = dict["tags"]
        //NSUserDefaults.standardUserDefaults().setObject(tagsArray.object, forKey: "tags")
        
        apiGetProjectsIdUIGroups(project_id: project_id, session_id: session_id)
        
//        let reset_tag_defaults_on_startup = RWFrameworkConfig.getConfigValueAsBool("reset_tag_defaults_on_startup")
//        let dict = JSON(data: data)
        //OLD
        // Listen
//        let listenArray = dict["listen"]
//        NSUserDefaults.standardUserDefaults().setObject(listenArray.object, forKey: "tags_listen")

        // Save defaults as "current settings" for listen tags if they are not already set
//        for (_, dict): (String, JSON) in listenArray {
//            let code = dict["code"]
//            let defaults = dict["defaults"]
//            let defaultsKeyName = "tags_listen_\(code)_current"
//            let current: AnyObject? = NSUserDefaults.standardUserDefaults().objectForKey(defaultsKeyName)
//            if (current == nil || reset_tag_defaults_on_startup) {
//                NSUserDefaults.standardUserDefaults().setObject(defaults.object, forKey: defaultsKeyName)
//            }
//        }
//
        // Speak
//        let speakArray = dict["speak"]
//        NSUserDefaults.standardUserDefaults().setObject(speakArray.object, forKey: "tags_speak")

        // Save defaults as "current settings" for speak tags if they are not already set
//        for (_, dict): (String, JSON) in speakArray {
//            let code = dict["code"]
//            let defaults = dict["defaults"]
//            let defaultsKeyName = "tags_speak_\(code)_current"
//            let current: AnyObject? = NSUserDefaults.standardUserDefaults().objectForKey(defaultsKeyName)
//            if (current == nil || reset_tag_defaults_on_startup) {
//                NSUserDefaults.standardUserDefaults().setObject(defaults.object, forKey: defaultsKeyName)
//            }
//        }
//
        getProjectsIdTagsSucceeded = true
    }
    
// MARK: GET UIGroups

    func apiGetProjectsIdUIGroups(project_id: String, session_id: String) {
        httpGetProjectsIdUIGroups(project_id: project_id, session_id: session_id) { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                self.getProjectsIdUIGroupsSuccess(data: data!, project_id: project_id, session_id: session_id)
                self.rwGetProjectsIdUIGroupsSuccess(data: data)
            } else if (error != nil) {
                self.rwGetProjectsIdUIGroupsFailure(error: error)
                self.apiProcessError(data: data, error: error!, caller: "apiGetProjectsIdUIGroups")
            }
        }
    }

    func getProjectsIdUIGroupsSuccess(data: NSData, project_id: String, session_id: String) {
        apiGetAssets(dict: ["project_id": project_id],
            success: { (data) -> Void in
            }, failure:  { (error) -> Void in
        })

    }
    
    
    // MARK: POST streams
    
    func apiPostStreams() {
        if (requestStreamInProgress == true) { return }
        if (requestStreamSucceeded == true) { return }
        if (postSessionsSucceeded == false) { return }
        
        requestStreamInProgress = true
        
        let session_id = RWFrameworkConfig.getConfigValueAsNumber(key: "session_id", group: RWFrameworkConfig.ConfigGroup.Client).stringValue

        var latitude: String? = nil
        var longitude: String? = nil
        let geo_listen_enabled = RWFrameworkConfig.getConfigValueAsBool(key: "geo_listen_enabled")
        if (geo_listen_enabled) {
            latitude = doubleToStringWithZeroAsEmptyString(d: lastRecordedLocation.coordinate.latitude)
            longitude = doubleToStringWithZeroAsEmptyString(d: lastRecordedLocation.coordinate.longitude)
        }

        httpPostStreams(session_id: session_id, latitude: latitude, longitude: longitude) { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                self.postStreamsSuccess(data: data!, session_id: session_id)
                self.rwPostStreamsSuccess(data: data)
            } else if (error != nil) {
                self.rwPostStreamsFailure(error: error)
                self.apiProcessError(data: data, error: error!, caller: "apiPostStreams")
            }
            self.requestStreamInProgress = false
        }
    }
    

    
// MARK: POST streams

    func postStreamsSuccess(data: NSData, session_id: String) {
        let dict = JSON(data: data as Data)
//        println(dict)

        let stream_url = dict["stream_url"]
        if (stream_url.string != nil) {
            self.streamURL = NSURL(string: stream_url.stringValue)
            let stream_id = dict["stream_id"]
            self.streamID = stream_id.intValue
            self.createPlayer()
            self.requestStreamSucceeded = true
        }

        // DEPRECATED
//        func requestStreamDisplayUserMessage(userMessage: String?) {
//            if (userMessage != nil && userMessage!.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0) {
//                self.rwUpdateStatus(userMessage!)
//            }
//        }
//        requestStreamDisplayUserMessage(dict["user_message"].string)
    }

// MARK: PATCH streams id

    func apiPatchStreamsIdWithLocation(newLocation: CLLocation?) {
        if (requestStreamSucceeded == false) { return }
        if (self.streamID == 0) { return }
        if (newLocation == nil) { return }

        let latitude = doubleToStringWithZeroAsEmptyString(d: newLocation!.coordinate.latitude)
        let longitude = doubleToStringWithZeroAsEmptyString(d: newLocation!.coordinate.longitude)

        httpPatchStreamsId(stream_id: self.streamID.description, latitude: latitude, longitude: longitude, completion: { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                self.patchStreamsIdSuccess(data: data!)
                self.rwPatchStreamsIdSuccess(data: data)
            } else if (error != nil) {
                self.rwPatchStreamsIdFailure(error: error)
                self.apiProcessError(data: data, error: error!, caller: "apiPatchStreamsIdWithLocation")
            }
        })
    }

    func apiPatchStreamsIdWithTags(tag_ids: String) {
        if (requestStreamSucceeded == false) { return }
        if (self.streamID == 0) { return }

        httpPatchStreamsId(stream_id: self.streamID.description, tag_ids: tag_ids, completion: { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                self.patchStreamsIdSuccess(data: data!)
                self.rwPatchStreamsIdSuccess(data: data)
            } else if (error != nil) {
                self.rwPatchStreamsIdFailure(error: error)
                self.apiProcessError(data: data, error: error!, caller: "apiPatchStreamsIdWithTags")
            }
        })
    }

    func patchStreamsIdSuccess(data: NSData) {
        _ = JSON(data: data as Data)
//        println(dict)
        // does nothing for now
    }

// MARK: POST streams id heartbeat

    func apiPostStreamsIdHeartbeat() {
        if (requestStreamSucceeded == false) { return }
        if (self.streamID == 0) { return }

        httpPostStreamsIdHeartbeat(stream_id: self.streamID.description, completion: { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                self.postStreamsIdHeartbeatSuccess(data: data!)
                self.rwPostStreamsIdHeartbeatSuccess(data: data)
            } else if (error != nil) {
                self.rwPostStreamsIdHeartbeatFailure(error: error)
                self.apiProcessError(data: data, error: error!, caller: "apiPostStreamsIdHeartbeat")
            }
        })
    }

    func postStreamsIdHeartbeatSuccess(data: NSData) {
        _ = JSON(data: data as Data)
//        println(dict)
        // does nothing for now
    }

// MARK: POST streams id next

    func apiPostStreamsIdSkip() {
        if (requestStreamSucceeded == false) { return }
        if (self.streamID == 0) { return }

        httpPostStreamsIdSkip(stream_id: self.streamID.description, completion: { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                self.postStreamsIdSkipSuccess(data: data!)
                self.rwPostStreamsIdSkipSuccess(data: data)
            } else if (error != nil) {
                self.rwPostStreamsIdSkipFailure(error: error)
                self.apiProcessError(data: data, error: error!, caller: "apiPostStreamsIdSkip")
            }
        })
    }

    func postStreamsIdSkipSuccess(data: NSData) {
        _ = JSON(data: data as Data)

//        self.player!.replaceCurrentItemWithPlayerItem(nil)
//        println(dict)
        // does nothing for now
    }


    // MARK: POST streams id play asset
    // MARK: POST streams id replay asset
    // MARK: POST streams id pause
    // MARK: POST streams id resume


// MARK: GET streams id current

    func apiGetStreamsIdCurrent() {
        if (requestStreamSucceeded == false) { return }
        if (self.streamID == 0) { return }

        httpGetStreamsIdCurrent(stream_id: self.streamID.description, completion: { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                self.getStreamsIdCurrentSuccess(data: data!)
                self.rwGetStreamsIdCurrentSuccess(data: data)
            } else if (error != nil) {
                self.rwGetStreamsIdCurrentFailure(error: error)
                self.apiProcessError(data: data, error: error!, caller: "apiGetStreamsIdCurrent")
            }
        })
    }

    func getStreamsIdCurrentSuccess(data: NSData) {
        _ = JSON(data: data as Data)
//        println(dict)
        // does nothing for now
    }

// MARK: POST envelopes

    func apiPostEnvelopes(success:@escaping (_ envelopeID: Int) -> Void) {
        let session_id = RWFrameworkConfig.getConfigValueAsNumber(key: "session_id", group: RWFrameworkConfig.ConfigGroup.Client).stringValue

        httpPostEnvelopes(session_id: session_id) { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                self.postEnvelopesSuccess(data: data!, session_id: session_id, success: success)
                self.rwPostEnvelopesSuccess(data: data)
            } else if (error != nil) {
                self.rwPostEnvelopesFailure(error: error)
                self.apiProcessError(data: data, error: error!, caller: "apiPostEnvelopes")
            }
        }
    }

    func postEnvelopesSuccess(data: NSData, session_id: String, success:(_ envelopeID: Int) -> Void) {
        let dict = JSON(data: data as Data)
//        println(dict)

        let envelope_id = dict["envelope_id"]
        if (envelope_id != nil) {
            success(envelope_id.int!)
        }
    }

// MARK: PATCH envelopes id

    func apiPatchEnvelopesId(media: Media, success:@escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let session_id = RWFrameworkConfig.getConfigValueAsNumber(key: "session_id", group: RWFrameworkConfig.ConfigGroup.Client).stringValue

        httpPatchEnvelopesId(media: media, session_id: session_id) { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                success()
                self.rwPatchEnvelopesIdSuccess(data: data)
            } else if (error != nil) {
                failure(error!)
                self.rwPatchEnvelopesIdFailure(error: error)
                self.apiProcessError(data: data, error: error!, caller: "apiPatchEnvelopesId")
            }
        }
    }

// MARK: POST assets

    // Not needed on client - not implementing for now

// MARK: GET assets PUBLIC

    public func apiGetAssets(dict: [String:String], success:@escaping (_ data: NSData?) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        httpGetAssets(dict: dict) { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                success(data)
                self.rwGetAssetsSuccess(data: data)
            } else if (error != nil) {
                failure(error!)
                self.rwGetAssetsFailure(error: error)
                self.apiProcessError(data: data, error: error!, caller: "apiGetAssets")
            }
        }
    }

// MARK: GET assets id PUBLIC

    public func apiGetAssetsId(asset_id: String, success:@escaping (_ data: NSData?) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        httpGetAssetsId(asset_id: asset_id) { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                success(data)
                self.rwGetAssetsIdSuccess(data: data)
            } else if (error != nil) {
                failure(error!)
                self.rwGetAssetsIdFailure(error: error)
                self.apiProcessError(data: data, error: error!, caller: "apiGetAssetsId")
            }
        }
    }

// MARK: POST assets id votes

    public func apiPostAssetsIdVotes(asset_id: String, vote_type: String, value: NSNumber = 0, success:@escaping (_ data: NSData?) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let session_id = RWFrameworkConfig.getConfigValueAsNumber(key: "session_id", group: RWFrameworkConfig.ConfigGroup.Client).stringValue

        httpPostAssetsIdVotes(asset_id: asset_id, session_id: session_id, vote_type: vote_type, value: value) { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                success(data)
                self.rwPostAssetsIdVotesSuccess(data: data)
            } else if (error != nil) {
                failure(error!)
                self.rwPostAssetsIdVotesFailure(error: error)
                self.apiProcessError(data: data, error: error!, caller: "apiPostAssetsIdVotes")
            }
        }
    }

// MARK: GET assets id votes

    public func apiGetAssetsIdVotes(asset_id: String, success:@escaping (_ data: NSData?) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        httpGetAssetsIdVotes(asset_id: asset_id) { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                success(data)
                self.rwGetAssetsIdVotesSuccess(data: data)
            } else if (error != nil) {
                failure(error!)
                self.rwGetAssetsIdVotesFailure(error: error)
                self.apiProcessError(data: data, error: error!, caller: "apiGetAssetsIdVotes")
            }
        }
    }

// MARK: POST events

    func apiPostEvents(event_type: String, data: String?, success:@escaping (_ data: NSData?) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        //TODO might need a check here to see if session_id has been set
        let session_id = RWFrameworkConfig.getConfigValueAsNumber(key: "session_id", group: RWFrameworkConfig.ConfigGroup.Client).stringValue
        let latitude = doubleToStringWithZeroAsEmptyString(d: lastRecordedLocation.coordinate.latitude)
        let longitude = doubleToStringWithZeroAsEmptyString(d: lastRecordedLocation.coordinate.longitude)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss" // 2015-03-13T13:00:09
        let client_time = dateFormatter.string(from: NSDate() as Date)
//        let tag_ids = getAllListenTagsCurrentAsString() + "," + getAllSpeakTagsCurrentAsString()

//        httpPostEvents(session_id, event_type: event_type, data: data, latitude: latitude, longitude: longitude, client_time: client_time, tag_ids: tag_ids) { (data, error) -> Void in
        httpPostEvents(session_id: session_id, event_type: event_type, data: data, latitude: latitude, longitude: longitude, client_time: client_time, tag_ids:"") { (data, error) -> Void in

            if (data != nil) && (error == nil) {
                success(data)
                self.rwPostEventsSuccess(data: data)
            } else if (error != nil) {
                failure(error!)
                self.rwPostEventsFailure(error: error)
                self.apiProcessError(data: data, error: error!, caller: "apiPostEvents")
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
        var detailStringValue = ""
        if (data != nil) {
            let dict = JSON(data: data! as Data)
            let detail = dict["detail"]
            detailStringValue = detail.stringValue
            self.println(object: "API ERROR: \(caller): \(detailStringValue) NSError = \(error.code) \(error.description)")
        }
        if (caller != "apiPostEvents") { // Don't log errors that occur while reporting errors
            logToServer(event_type: "client_error", data: "\(caller): \(detailStringValue) NSError = \(error.code) \(error.description)")
        }
    }

}

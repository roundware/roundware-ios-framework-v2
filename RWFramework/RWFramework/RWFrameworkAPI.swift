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

    func apiPostUsers(_ device_id: String, client_type: String, client_system: String) {
        let token = RWFrameworkConfig.getConfigValueAsString("token", group: RWFrameworkConfig.ConfigGroup.client)
        if (token.lengthOfBytes(using: String.Encoding.utf8) > 0) {
            postUsersSucceeded = true
            apiPostSessions()
        } else {
            httpPostUsers(device_id, client_type: client_type, client_system: client_system) { (data, error) -> Void in
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

    func postUsersSuccess(_ data: Data) {
        // http://stackoverflow.com/questions/24671249/parse-json-in-swift-anyobject-type/27206145#27206145
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)

            if let dict = json as? [String:AnyObject] {
                if let username = dict["username"] as? String {
                    RWFrameworkConfig.setConfigValue("username", value: username, group: RWFrameworkConfig.ConfigGroup.client)
                } // TODO: Handle missing value
                if let token = dict["token"] as? String {
                    RWFrameworkConfig.setConfigValue("token", value: token, group: RWFrameworkConfig.ConfigGroup.client)
                } // TODO: Handle missing value
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
        let project_id = RWFrameworkConfig.getConfigValueAsNumber("project_id")
        let client_system = clientSystem()
        let language = preferredLanguage()

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "ZZZ"
        let timezone = dateFormatter.string(from: Date())

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

    func postSessionsSuccess(_ data: Data) {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)

            var session_id : NSNumber = 0
            if let dict = json as? [String: AnyObject] {
                if let _session_id = dict["id"] as? NSNumber {
                    session_id = _session_id
                    RWFrameworkConfig.setConfigValue("session_id", value: session_id, group: RWFrameworkConfig.ConfigGroup.client)
                } // TODO: Handle missing value
            }

            postSessionsSucceeded = true

            let project_id = RWFrameworkConfig.getConfigValueAsNumber("project_id")
            apiGetProjectsId(project_id, session_id: session_id)
        }
        catch {
            print(error)
        }
    }


// MARK: GET projects id

    func apiGetProjectsId(_ project_id: NSNumber, session_id: NSNumber) {
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

    func getProjectsIdSuccess(_ data: Data, project_id: NSNumber, session_id: NSNumber) {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)

            if let dict = json as? [String: AnyObject] {
                RWFrameworkConfig.setConfigDataAsDictionary(data, key: "project")

                // TODO: where is this going to come from?
                func configDisplayStartupMessage() {
                    let startupMessage = RWFrameworkConfig.getConfigValueAsString("startup_message", group: RWFrameworkConfig.ConfigGroup.notifications)
                    if (startupMessage.lengthOfBytes(using: String.Encoding.utf8) > 0) {
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
                
                // a simpler alternative to apiGetProjectsIdTags and it's subsequent calls but needs
                // to be properly vetted before turning off the more complex calls
                apiGetUIConfig(project_id, session_id: session_id)
            }
        }
        catch {
            print(error)
        }
    }

    // MARK: GET ui config
    
    func apiGetUIConfig(_ project_id: NSNumber, session_id: NSNumber) {
        httpGetUIConfig(project_id, session_id: session_id) { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                self.getUIConfigSuccess(data!, project_id: project_id)
                self.rwGetUIConfigSuccess(data)
            } else if (error != nil) {
                self.rwGetUIConfigFailure(error)
                self.apiProcessError(data, error: error!, caller: "apiGetUIConfig")
            }
        }
    }
    
    func getUIConfigSuccess(_ data: Data, project_id: NSNumber) {
        // Save data to UserDefaults for later access
        UserDefaults.standard.set(data, forKey: "uiconfig")
        
        getUIConfigSucceeded = true
    }

// MARK: GET projects id tags

    func apiGetProjectsIdTags(_ project_id: NSNumber, session_id: NSNumber) {
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
    
    func getProjectsIdTagsSuccess(_ data: Data, project_id: NSNumber, session_id: NSNumber) {
        // Save data to UserDefaults for later access
        UserDefaults.standard.set(data, forKey: "tags")
        
        getProjectsIdTagsSucceeded = true
        apiGetProjectsIdUIGroups(project_id, session_id: session_id)
    }

// MARK: GET projects id uigroups
    
    func apiGetProjectsIdUIGroups(_ project_id: NSNumber, session_id: NSNumber) {
        httpGetProjectsIdUIGroups(project_id, session_id: session_id) { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                self.getProjectsIdUIGroupsSuccess(data!, project_id: project_id)
                self.rwGetProjectsIdUIGroupsSuccess(data)
            } else if (error != nil) {
                self.rwGetProjectsIdUIGroupsFailure(error)
                self.apiProcessError(data, error: error!, caller: "apiGetProjectsIdUIGroups")
            }
        }
    }
    
    func getProjectsIdUIGroupsSuccess(_ data: Data, project_id: NSNumber) {
        // Save data to UserDefaults for later access
        UserDefaults.standard.set(data, forKey: "ui_groups")
        
        let reset_tag_defaults_on_startup = RWFrameworkConfig.getConfigValueAsBool("reset_tag_defaults_on_startup")
        println("TODO: honor reset_tag_defaults_on_startup = \(reset_tag_defaults_on_startup.description)")

        getProjectsIdUIGroupsSucceeded = true
        apiGetTagCategories()
    }
    
// MARK: GET tagcategories
    
    func apiGetTagCategories() {
        httpGetTagCategories() { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                self.getTagCategoriesSuccess(data!)
                self.rwGetTagCategoriesSuccess(data)
            } else if (error != nil) {
                self.rwGetTagCategoriesFailure(error)
                self.apiProcessError(data, error: error!, caller: "apiGetTagCategories")
            }
        }
    }
    
    func getTagCategoriesSuccess(_ data: Data) {
        // Save data to UserDefaults for later access
        UserDefaults.standard.set(data, forKey: "tagcategories")
        
        getTagCategoriesSucceeded = true
    }

// MARK: POST streams

    func apiPostStreams() {
        if (requestStreamInProgress == true) { return }
        if (requestStreamSucceeded == true) { return }
        if (postSessionsSucceeded == false) { return }

        requestStreamInProgress = true
        lastRecordedLocation = locationManager.location!

        let session_id = RWFrameworkConfig.getConfigValueAsNumber("session_id", group: RWFrameworkConfig.ConfigGroup.client)
        let latitude = doubleToStringWithZeroAsEmptyString(lastRecordedLocation.coordinate.latitude)
        let longitude = doubleToStringWithZeroAsEmptyString(lastRecordedLocation.coordinate.longitude)

        httpPostStreams(session_id, latitude: latitude, longitude: longitude) { (data, error) -> Void in
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

    func postStreamsSuccess(_ data: Data, session_id: NSNumber) {
        do {

            let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)

            if let dict = json as? [String: AnyObject] {
                if let stream_url = dict["stream_url"] as? String {
                    self.streamURL = URL(string: stream_url)! as NSURL as URL
                    if let stream_id = dict["stream_id"] as? NSNumber {
                        self.streamID = stream_id.intValue
                        self.createPlayer()
                        self.requestStreamSucceeded = true
                    }
                }

                // TODO: can we still expect this here?
                func requestStreamDisplayUserMessage(_ userMessage: String?) {
                    if (userMessage != nil && userMessage!.lengthOfBytes(using: String.Encoding.utf8) > 0) {
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
    func apiPatchStreamsIdWithLocation(_ newLocation: CLLocation?, streamPatchOptions: Dictionary<String, Any>) {
        if (requestStreamSucceeded == false) { return }
        if (self.streamID == 0) { return }
        if (newLocation == nil) { return }

        let latitude = doubleToStringWithZeroAsEmptyString(newLocation!.coordinate.latitude)
        let longitude = doubleToStringWithZeroAsEmptyString(newLocation!.coordinate.longitude)
        httpPatchStreamsId(self.streamID.description, latitude: latitude, longitude: longitude, streamPatchOptions: streamPatchOptions, completion: { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                self.patchStreamsIdSuccess(data!)
                self.rwPatchStreamsIdSuccess(data)
            } else if (error != nil) {
                self.rwPatchStreamsIdFailure(error)
                self.apiProcessError(data, error: error!, caller: "apiPatchStreamsIdWithLocation")
            }
        })
    }

    func apiPatchStreamsIdWithTags(_ tag_ids: String) {
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

    func patchStreamsIdSuccess(_ data: Data) {

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

    func postStreamsIdHeartbeatSuccess(_ data: Data) {

    }

    // MARK: POST streams id replay
    
    func apiPostStreamsIdReplay() {
        if (requestStreamSucceeded == false) { return }
        if (self.streamID == 0) { return }
        
        httpPostStreamsIdReplay(self.streamID.description, completion: { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                self.postStreamsIdReplaySuccess(data!)
                self.rwPostStreamsIdReplaySuccess(data)
            } else if (error != nil) {
                self.rwPostStreamsIdReplayFailure(error)
                self.apiProcessError(data, error: error!, caller: "apiPostStreamsIdReplay")
            }
        })
    }
    
    func postStreamsIdReplaySuccess(_ data: Data) {
        
    }

    // MARK: POST streams id skip
    
    func apiPostStreamsIdSkip() {
        if (requestStreamSucceeded == false) { return }
        if (self.streamID == 0) { return }
        
        httpPostStreamsIdSkip(self.streamID.description, completion: { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                self.postStreamsIdSkipSuccess(data!)
                self.rwPostStreamsIdSkipSuccess(data)
            } else if (error != nil) {
                self.rwPostStreamsIdSkipFailure(error)
                self.apiProcessError(data, error: error!, caller: "apiPostStreamsIdSkip")
            }
        })
    }
    
    func postStreamsIdSkipSuccess(_ data: Data) {
        
    }

// MARK: POST envelopes

    func apiPostEnvelopes(_ success:@escaping (_ envelopeID: Int) -> Void) {
        let session_id = RWFrameworkConfig.getConfigValueAsNumber("session_id", group: RWFrameworkConfig.ConfigGroup.client)

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

    func postEnvelopesSuccess(_ data: Data, session_id: NSNumber, success:(_ envelopeID: Int) -> Void) {

        do {
            let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)
            if let dict = json as? [String: AnyObject] {
                if let envelope_id = dict["id"] as? NSNumber {
                    success(envelope_id.intValue)
                }
            }
        }
        catch {
            print(error)
        }

    }

// MARK: PATCH envelopes id

    func apiPatchEnvelopesId(_ media: Media, success:@escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let session_id = RWFrameworkConfig.getConfigValueAsNumber("session_id", group: RWFrameworkConfig.ConfigGroup.client)

        httpPatchEnvelopesId(media, session_id: session_id) { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                success()
                self.rwPatchEnvelopesIdSuccess(data)
            } else if (error != nil) {
                failure(error!)
                self.rwPatchEnvelopesIdFailure(error)
                self.apiProcessError(data, error: error!, caller: "apiPatchEnvelopesId")
            }
        }
    }

// MARK: POST assets

    // Not needed on client - not implementing for now

// MARK: GET assets PUBLIC

    public func apiGetAssets(_ dict: [String:String], success:@escaping (_ data: Data?) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        httpGetAssets(dict) { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                success(data)
                self.rwGetAssetsSuccess(data)
            } else if (error != nil) {
                failure(error!)
                self.rwGetAssetsFailure(error)
                self.apiProcessError(data, error: error!, caller: "apiGetAssets")
            }
        }
    }

// MARK: GET assets id PUBLIC

    public func apiGetAssetsId(_ asset_id: String, success:@escaping (_ data: Data?) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        httpGetAssetsId(asset_id) { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                success(data)
                self.rwGetAssetsIdSuccess(data)
            } else if (error != nil) {
                failure(error!)
                self.rwGetAssetsIdFailure(error)
                self.apiProcessError(data, error: error!, caller: "apiGetAssetsId")
            }
        }
    }

// MARK: POST assets id votes

    public func apiPostAssetsIdVotes(_ asset_id: String, vote_type: String, value: NSNumber = 0, success:@escaping (_ data: Data?) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let session_id = RWFrameworkConfig.getConfigValueAsNumber("session_id", group: RWFrameworkConfig.ConfigGroup.client)

        httpPostAssetsIdVotes(asset_id, session_id: session_id, vote_type: vote_type, value: value) { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                success(data)
                self.rwPostAssetsIdVotesSuccess(data)
            } else if (error != nil) {
                failure(error!)
                self.rwPostAssetsIdVotesFailure(error)
                self.apiProcessError(data, error: error!, caller: "apiPostAssetsIdVotes")
            }
        }
    }

// MARK: GET assets id votes

    public func apiGetAssetsIdVotes(_ asset_id: String, success:@escaping (_ data: Data?) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        httpGetAssetsIdVotes(asset_id) { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                success(data)
                self.rwGetAssetsIdVotesSuccess(data)
            } else if (error != nil) {
                failure(error!)
                self.rwGetAssetsIdVotesFailure(error)
                self.apiProcessError(data, error: error!, caller: "apiGetAssetsIdVotes")
            }
        }
    }

// MARK: POST events

    func apiPostEvents(_ event_type: String, data: String?, success:@escaping (_ data: Data?) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let session_id = RWFrameworkConfig.getConfigValueAsNumber("session_id", group: RWFrameworkConfig.ConfigGroup.client)
        let latitude = doubleToStringWithZeroAsEmptyString(lastRecordedLocation.coordinate.latitude)
        let longitude = doubleToStringWithZeroAsEmptyString(lastRecordedLocation.coordinate.longitude)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss" // 2015-03-13T13:00:09
        let client_time = dateFormatter.string(from: Date())
        let tag_ids = getSubmittableListenIDsSetAsTags() + "," + getSubmittableSpeakIDsSetAsTags()

        httpPostEvents(session_id, event_type: event_type, data: data, latitude: latitude, longitude: longitude, client_time: client_time, tag_ids: tag_ids) { (data, error) -> Void in
            if (data != nil) && (error == nil) {
                success(data)
                self.rwPostEventsSuccess(data)
            } else if (error != nil) {
                failure(error!)
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

    func apiProcessError(_ data: Data?, error: NSError, caller: String) {
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

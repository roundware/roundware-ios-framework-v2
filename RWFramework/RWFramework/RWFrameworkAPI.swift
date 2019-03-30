//
//  RWFrameworkAPI.swift
//  RWFramework
//
//  Created by Joe Zobkiw on 2/17/15.
//  Copyright (c) 2015 Roundware. All rights reserved.
//

import Foundation
import CoreLocation
import Promises
import SwiftyJSON

extension RWFramework {

    func apiStartForClientMixing() -> Promise<Project> {
        let device_id = UIDevice().identifierForVendor!.uuidString
        let client_type = UIDevice().model
        let client_system = clientSystem()
        return apiPostUsers(device_id, client_type: client_type, client_system: client_system)
            // start a session
            .then { _ in self.apiPostSessions() }
            .then { data in try self.setupClientSession(data) }
    }
    
    func apiStartUp(_ device_id: String, client_type: String, client_system: String) {
        // Create new user for the session and save its info
        apiPostUsers(device_id, client_type: client_type, client_system: client_system)
            // start a session
            .then { _ in self.apiPostSessions() }
            // initialize all info associated with a session (UI config, tags, etc.)
            .then { data in try self.setupSession(data) }
    }

    /// MARK: POST users
    func apiPostUsers(_ device_id: String, client_type: String, client_system: String) -> Promise<Void> {
        let token = RWFrameworkConfig.getConfigValueAsString("token", group: RWFrameworkConfig.ConfigGroup.client)
        
        if (token.lengthOfBytes(using: String.Encoding.utf8) > 0) {
            // postUsersSucceeded = true
            print("using token \(token)")
            return Promise(())
        } else {
            return httpPostUsers(
                device_id,
                client_type: client_type,
                client_system: client_system
            ).then { data -> Void in
                // save our user info for future operations
                try self.saveUserInfo(data)
                self.rwPostUsersSuccess(data)
                return ()
            }.catch { error in
                self.rwPostUsersFailure(error)
                self.apiProcessError(nil, error: error, caller: "apiPostUsers")
            }
        }
    }

    private func saveUserInfo(_ data: Data) throws {
        print("got new user")
        print(data)
        if let dict = try JSON(data: data).dictionary {
            if let username = dict["username"]?.string {
                RWFrameworkConfig.setConfigValue("username", value: username, group: RWFrameworkConfig.ConfigGroup.client)
            } // TODO: Handle missing value
            if let token = dict["token"]?.string {
                RWFrameworkConfig.setConfigValue("token", value: token, group: RWFrameworkConfig.ConfigGroup.client)
            } // TODO: Handle missing value
        }

        // postUsersSucceeded = true
    }


    /// MARK: POST sessions
    func apiPostSessions() -> Promise<Data> {
        let project_id = RWFrameworkConfig.getConfigValueAsNumber("project_id")
        let client_system = clientSystem()
        let language = preferredLanguage()

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "ZZZ"
        let timezone = dateFormatter.string(from: Date())

        return httpPostSessions(
            project_id,
            timezone: timezone,
            client_system: client_system,
            language: language
        ).then { data -> Data in
            self.postSessionsSucceeded = true
            self.rwPostSessionsSuccess(data)
            return data
        }.catch { error in
            self.rwPostSessionsFailure(error)
            self.apiProcessError(nil, error: error, caller: "apiPostSessions")
        }
    }

    private func setupClientSession(_ data: Data) throws -> Promise<Project> {
        var session_id : NSNumber = 0
        if let dict = try JSON(data: data).dictionary {
            if let _session_id = dict["id"]?.number {
                session_id = _session_id
                RWFrameworkConfig.setConfigValue("session_id", value: session_id, group: RWFrameworkConfig.ConfigGroup.client)
            } // TODO: Handle missing value
        }

        let project_id = RWFrameworkConfig.getConfigValueAsNumber("project_id")
        self.apiGetProjectsIdTags(project_id, session_id: session_id)
        self.apiGetUIConfig(project_id, session_id: session_id)
        self.apiGetProjectsIdUIGroups(project_id, session_id: session_id)
        self.apiGetTagCategories()
        return self.apiGetProjectsId(project_id, session_id: session_id).then { data -> Project in
            RWFrameworkConfig.setConfigDataAsDictionary(data, key: "project")
            self.setupRecording()
            return try JSONDecoder().decode(Project.self, from: data)
        }
    }

    private func setupSession(_ data: Data) throws {
        var session_id : NSNumber = 0
        if let dict = try JSON(data: data).dictionary {
            if let _session_id = dict["id"]?.number {
                session_id = _session_id
                RWFrameworkConfig.setConfigValue("session_id", value: session_id, group: RWFrameworkConfig.ConfigGroup.client)
            } // TODO: Handle missing value
        }

        let project_id = RWFrameworkConfig.getConfigValueAsNumber("project_id")
        
        apiGetProjectsId(project_id, session_id: session_id)
            .then { data in try self.setupStream(data, project_id: project_id, session_id: session_id) }
            .then { self.apiGetProjectsIdTags(project_id, session_id: session_id) }
            .then { _ in self.apiGetUIConfig(project_id, session_id: session_id) }
            .then { _ in self.apiGetProjectsIdUIGroups(project_id, session_id: session_id) }
            .then { _ in self.apiGetTagCategories() }
    }


    /// MARK: GET projects id
    func apiGetProjectsId(_ project_id: NSNumber, session_id: NSNumber) -> Promise<Data> {
        return httpGetProjectsId(project_id, session_id: session_id).then { data -> Data in
            self.rwGetProjectsIdSuccess(data)
            return data
        }.catch { error in
            self.rwGetProjectsIdFailure(error)
            self.apiProcessError(nil, error: error, caller: "apiGetProjectsId")
        }
    }

    private func setupStream(_ data: Data, project_id: NSNumber, session_id: NSNumber) throws {
        if let dict = try JSON(data: data).dictionary {
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

            setupRecording()

            // getProjectsIdSucceeded = true
            
//                apiGetProjectsIdTags(project_id, session_id: session_id)
            
            // a simpler alternative to apiGetProjectsIdTags and it's subsequent calls but needs
            // to be properly vetted before turning off the more complex calls
//                apiGetUIConfig(project_id, session_id: session_id)
        }
    }
    
    func setupRecording() {
        let speak_enabled = RWFrameworkConfig.getConfigValueAsBool("speak_enabled")
        if (speak_enabled) {
            startAudioTimer()
            startUploadTimer()
            rwReadyToRecord()
        }
    }

    /// MARK: GET ui config
    func apiGetUIConfig(_ project_id: NSNumber, session_id: NSNumber) {
        httpGetUIConfig(project_id, session_id: session_id).then { data in
            // Save data to UserDefaults for later access
            UserDefaults.standard.set(data, forKey: "uiconfig")
            self.getUIConfigSucceeded = true
            
            self.rwGetUIConfigSuccess(data)
        }.catch { error in
            self.rwGetUIConfigFailure(error)
            self.apiProcessError(nil, error: error, caller: "apiGetUIConfig")
        }
    }


    /// MARK: GET projects id tags
    func apiGetProjectsIdTags(_ project_id: NSNumber, session_id: NSNumber) -> Promise<Data> {
        return httpGetProjectsIdTags(project_id, session_id: session_id).then { data -> Data in
            // Save data to UserDefaults for later access
            UserDefaults.standard.set(data, forKey: "tags")
            self.getProjectsIdTagsSucceeded = true
            
            self.rwGetProjectsIdTagsSuccess(data)
            return data
        }.catch { error in
            self.rwGetProjectsIdTagsFailure(error)
            self.apiProcessError(nil, error: error, caller: "apiGetProjectsIdTags")
        }
    }

    /// MARK: GET projects id uigroups
    func apiGetProjectsIdUIGroups(_ project_id: NSNumber, session_id: NSNumber) -> Promise<Data> {
        return httpGetProjectsIdUIGroups(project_id, session_id: session_id).then { data -> Data in
            // Save data to UserDefaults for later access
            UserDefaults.standard.set(data, forKey: "ui_groups")
            
            let reset_tag_defaults_on_startup = RWFrameworkConfig.getConfigValueAsBool("reset_tag_defaults_on_startup")
            self.println("TODO: honor reset_tag_defaults_on_startup = \(reset_tag_defaults_on_startup.description)")
            
            self.getProjectsIdUIGroupsSucceeded = true
            
            self.rwGetProjectsIdUIGroupsSuccess(data)
            return data
        }.catch { error in
            self.rwGetProjectsIdUIGroupsFailure(error)
            self.apiProcessError(nil, error: error, caller: "apiGetProjectsIdUIGroups")
        }
    }
    
    /// MARK: GET tagcategories
    func apiGetTagCategories() -> Promise<Data> {
        return httpGetTagCategories().then { data -> Data in
            UserDefaults.standard.set(data, forKey: "tagcategories")
            self.getTagCategoriesSucceeded = true
            self.rwGetTagCategoriesSuccess(data)
            return data
        }.catch { error in
            self.rwGetTagCategoriesFailure(error)
            self.apiProcessError(nil, error: error, caller: "apiGetTagCategories")
        }
    }

    /// MARK: POST streams
    public func apiPostStreams(at location: CLLocation? = nil) {
        if requestStreamInProgress
            || requestStreamSucceeded
            || !postSessionsSucceeded { return }

        requestStreamInProgress = true
        lastRecordedLocation = locationManager.location!

        let session_id = RWFrameworkConfig.getConfigValueAsNumber("session_id", group: RWFrameworkConfig.ConfigGroup.client)
        
        var lat: String = "0.1", lng: String = "0.1"
        if let loc = location?.coordinate {
            lat = doubleToStringWithZeroAsEmptyString(loc.latitude)
            lng = doubleToStringWithZeroAsEmptyString(loc.longitude)
        }

        httpPostStreams(session_id, latitude: lat, longitude: lng).always {
            self.requestStreamInProgress = false
        }.then { data -> Data in
            try self.postStreamsSuccess(data, session_id: session_id)
            self.rwPostStreamsSuccess(data)
            return data
        }.catch { error in 
            self.rwPostStreamsFailure(error)
            self.apiProcessError(nil, error: error, caller: "apiPostStreams")
        }
    }

    private func postStreamsSuccess(_ data: Data, session_id: NSNumber) throws {
        if let dict = try JSON(data: data).dictionary {
            if let stream_url = dict["stream_url"]?.string {
                self.streamURL = URL(string: stream_url)!
                if let stream_id = dict["stream_id"]?.int {
                    self.streamID = stream_id
//                    self.createPlayer()
                    self.requestStreamSucceeded = true
                    // pause stream on server so that assets aren't added until user is actually listening
                    apiPostStreamsIdPause()
                }
            }

            // TODO: can we still expect this here?
            func requestStreamDisplayUserMessage(_ userMessage: String?) {
                if (userMessage != nil && userMessage!.lengthOfBytes(using: String.Encoding.utf8) > 0) {
                    self.rwUpdateStatus(userMessage!, title: "Out of Range!")
                }
            }
            requestStreamDisplayUserMessage(dict["user_message"]?.string)
        }
    }

    /// MARK: PATCH streams id
    public func apiPatchStreamsIdWithLocation(
        _ newLocation: CLLocation,
        tagIds: String? = nil,
        streamPatchOptions: [String: Any] = [:]
    ) {
        if (requestStreamSucceeded == false || self.streamID == 0) { return }

        let latitude = doubleToStringWithZeroAsEmptyString(newLocation.coordinate.latitude)
        let longitude = doubleToStringWithZeroAsEmptyString(newLocation.coordinate.longitude)
        httpPatchStreamsId(
            self.streamID.description,
            tagIds: tagIds,
            latitude: latitude,
            longitude: longitude,
            streamPatchOptions: streamPatchOptions
        ).then { data in
            self.rwPatchStreamsIdSuccess(data)
        }.catch { error in 
            self.rwPatchStreamsIdFailure(error)
            self.apiProcessError(nil, error: error, caller: "apiPatchStreamsIdWithLocation")
        }
    }

    func apiPatchStreamsIdWithTags(_ tag_ids: String, streamPatchOptions: [String: Any] = [:]) {
        if (requestStreamSucceeded == false) { return }
        if (self.streamID == 0) { return }

        httpPatchStreamsId(self.streamID.description, tagIds: tag_ids).then { data in
//            self.patchStreamsIdSuccess(data!)
            self.rwPatchStreamsIdSuccess(data)
        }.catch { error in
            self.rwPatchStreamsIdFailure(error)
            self.apiProcessError(nil, error: error, caller: "apiPatchStreamsIdWithTags")
        }
    }

    /// MARK: POST streams id heartbeat
    func apiPostStreamsIdHeartbeat() {
        if (requestStreamSucceeded == false) { return }
        if (self.streamID == 0) { return }

        httpPostStreamsIdHeartbeat(self.streamID.description).then { data in
            self.rwPostStreamsIdHeartbeatSuccess(data)
        }.catch { error in
            self.rwPostStreamsIdHeartbeatFailure(error)
            self.apiProcessError(nil, error: error, caller: "apiPostStreamsIdHeartbeat")  
        }
    }

    /// MARK: POST streams id replay
    func apiPostStreamsIdReplay() {
        if (requestStreamSucceeded == false) { return }
        if (self.streamID == 0) { return }
        
        httpPostStreamsIdReplay(self.streamID.description).then { data in
            self.rwPostStreamsIdReplaySuccess(data)
        }.catch { error in
            self.rwPostStreamsIdReplayFailure(error)
            self.apiProcessError(nil, error: error, caller: "apiPostStreamsIdReplay")
        }
    }

    /// MARK: POST streams id skip
    func apiPostStreamsIdSkip() {
        if (requestStreamSucceeded == false) { return }
        if (self.streamID == 0) { return }
        
        httpPostStreamsIdSkip(self.streamID.description).then { data in
            self.rwPostStreamsIdSkipSuccess(data)
        }.catch { error in
            self.rwPostStreamsIdSkipFailure(error)
            self.apiProcessError(nil, error: error, caller: "apiPostStreamsIdSkip")     
        }
    }
    
    
    /// MARK: POST streams id pause
    func apiPostStreamsIdPause() {
        if (requestStreamSucceeded == false) { return }
        if (self.streamID == 0) { return }
        
        httpPostStreamsIdPause(self.streamID.description).then { data in
            self.rwPostStreamsIdPauseSuccess(data)
        }.catch { error in
            self.rwPostStreamsIdPauseFailure(error)
            self.apiProcessError(nil, error: error, caller: "apiPostStreamsIdPause")
        }
    }
    
    
    /// MARK: POST streams id resume
    func apiPostStreamsIdResume() {
        if (requestStreamSucceeded == false) { return }
        if (self.streamID == 0) { return }
        
        httpPostStreamsIdResume(self.streamID.description).then { data in
            self.rwPostStreamsIdResumeSuccess(data)
        }.catch { error in
            self.rwPostStreamsIdResumeFailure(error)
            self.apiProcessError(nil, error: error, caller: "apiPostStreamsIdResume")
        }
    }
    
    
    /// MARK: GET streams id isactive
    func apiGetStreamsIdIsActive() {
        if (requestStreamSucceeded == false) { return }
        if (self.streamID == 0) { return }
        
        httpGetStreamsIdIsActive(self.streamID.description).then { data in
            self.rwGetStreamsIdIsActiveSuccess(data)
        }.catch { error in
            self.rwGetStreamsIdIsActiveFailure(error)
            self.apiProcessError(nil, error: error, caller: "apiGetStreamsIdIsActive")
        }
    }
    

    /// MARK: POST envelopes
    func apiPostEnvelopes() -> Promise<Int> {
        let session_id = RWFrameworkConfig.getConfigValueAsNumber("session_id", group: RWFrameworkConfig.ConfigGroup.client)

        return httpPostEnvelopes(session_id).then { data -> Int in
            self.rwPostEnvelopesSuccess(data)
            
            // return the id of the created envelope
            let dict = try JSON(data: data)
            return dict["id"].int!
        }.catch { error in
            self.rwPostEnvelopesFailure(error)
            self.apiProcessError(nil, error: error, caller: "apiPostEnvelopes")
        }
    }

    /// MARK: PATCH envelopes id
    func apiPatchEnvelopesId(_ media: Media) -> Promise<Void> {
        let session_id = RWFrameworkConfig.getConfigValueAsNumber("session_id", group: RWFrameworkConfig.ConfigGroup.client)

        return httpPatchEnvelopesId(media, session_id: session_id).then { data -> Void in
//            self.patchEnvelopesSuccess(data!)
            self.rwPatchEnvelopesIdSuccess(data)
        }.catch { error in
            self.rwPatchEnvelopesIdFailure(error)
            self.apiProcessError(nil, error: error, caller: "apiPatchEnvelopesId")
        }
    }
    
    func patchEnvelopesSuccess(_ data: Data) {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)
            
            if let dict = json as? [String:AnyObject] {
                if let assetId = dict["id"] as? NSNumber {
                    // only set config value for audio assets
                    let assetMediaType = dict["media_type"] as? String
                    if (assetMediaType == "audio") {
                        RWFrameworkConfig.setConfigValue("most_recent_audio_asset_id", value: assetId, group: RWFrameworkConfig.ConfigGroup.client)
                    }
                }
            }
        }
        catch {
            print(error)
        }
    }

// MARK: POST assets

    // Not needed on client - not implementing for now
    
    
    public func apiGetAudioTracks(_ dict: [String:String]) -> Promise<[AudioTrack]> {
        return httpGetAudioTracks(dict).then { data in
            try AudioTrack.from(data: data)
        }.catch { error in
            self.apiProcessError(nil, error: error, caller: "apiGetAudioTracks")
        }
    }

    /// MARK: GET assets PUBLIC
    public func apiGetAssets(_ dict: [String:String]) -> Promise<[Asset]> {
        return httpGetAssets(dict).then { data -> [Asset] in
            self.rwGetAssetsSuccess(data)
            return try Asset.from(data: data)
        }.catch { error in
            self.rwGetAssetsFailure(error)
            self.apiProcessError(nil, error: error, caller: "apiGetAssets")
        }
    }

    public func apiGetTimedAssets(_ dict: [String:String]) -> Promise<[TimedAsset]> {
        return httpGetTimedAssets(dict).then { data -> [TimedAsset] in
            return try JSONDecoder().decode([TimedAsset].self, from: data)
        }.catch { error in
            self.apiProcessError(nil, error: error, caller: "apiGetTimedAssets")
        }
    }
    
// MARK: PATCH assets id PUBLIC
    
    public func apiPatchAssetsId(_ asset_id: String, postData: [String: Any] = [:]) -> Promise<Data> {
        
        return httpPatchAssetsId(asset_id, postData: postData).then { data -> Data in
            self.rwPatchAssetsIdSuccess(data)
            return data
            }.catch { error in
                self.rwPatchAssetsIdFailure(error)
                self.apiProcessError(nil, error: error, caller: "apiPatchAssetsId")
        }
    }

    /// MARK: GET assets id PUBLIC
    public func apiGetAssetsId(_ asset_id: String) -> Promise<Data> {
        return httpGetAssetsId(asset_id).then { data -> Data in
            self.rwGetAssetsIdSuccess(data)
            return data
        }.catch { error in
            self.rwGetAssetsIdFailure(error)
            self.apiProcessError(nil, error: error, caller: "apiGetAssetsId")
        }
    }

    /// MARK: POST assets id votes
    public func apiPostAssetsIdVotes(_ asset_id: String, vote_type: String, value: NSNumber = 0) -> Promise<Data> {
        let session_id = RWFrameworkConfig.getConfigValueAsNumber("session_id", group: RWFrameworkConfig.ConfigGroup.client)

        return httpPostAssetsIdVotes(asset_id, session_id: session_id, vote_type: vote_type, value: value).then { data -> Data in
            self.rwPostAssetsIdVotesSuccess(data)
            return data
        }.catch { error in
            self.rwPostAssetsIdVotesFailure(error)
            self.apiProcessError(nil, error: error, caller: "apiPostAssetsIdVotes")
            
        }
    }

    /// MARK: GET assets id votes
    public func apiGetAssetsIdVotes(_ asset_id: String) -> Promise<Data> {
        return httpGetAssetsIdVotes(asset_id).then { data -> Data in
            self.rwGetAssetsIdVotesSuccess(data)
            return data
        }.catch { error in
            self.rwGetAssetsIdVotesFailure(error)
            self.apiProcessError(nil, error: error, caller: "apiGetAssetsIdVotes")
        }
    }
    
    public func apiGetSpeakers(_ dict: [String:String]) -> Promise<[Speaker]> {
        return httpGetSpeakers(dict).then { data -> [Speaker] in
            self.rwGetSpeakersSuccess(data)
            return try Speaker.from(data: data)
        }.catch { error in
            self.rwGetSpeakersFailure(error)
            self.apiProcessError(nil, error: error, caller: "apiGetAssets")
        }
    }

    /// MARK: POST events
    func apiPostEvents(_ event_type: String, data: String?) -> Promise<Data> {
        let session_id = RWFrameworkConfig.getConfigValueAsNumber("session_id", group: RWFrameworkConfig.ConfigGroup.client)
        let latitude = doubleToStringWithZeroAsEmptyString(lastRecordedLocation.coordinate.latitude)
        let longitude = doubleToStringWithZeroAsEmptyString(lastRecordedLocation.coordinate.longitude)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss" // 2015-03-13T13:00:09
        let client_time = dateFormatter.string(from: Date())
        let tag_ids = getSubmittableListenIDsSetAsTags() + "," + getSubmittableSpeakIDsSetAsTags()

        return httpPostEvents(session_id, event_type: event_type, data: data, latitude: latitude, longitude: longitude, client_time: client_time, tag_ids: tag_ids).then { data -> Data in
            self.rwPostEventsSuccess(data)
            return data
        }.catch { error in
            self.rwPostEventsFailure(error)
            self.apiProcessError(nil, error: error, caller: "apiPostEvents")
            
        }
    }

    // MARK: GET events id
    // Not needed on client - not implementing for now

    // MARK: GET listenevents
    // Not needed on client - not implementing for now

    // MARK: GET listenevents id
    // Not needed on client - not implementing for now

    // MARK: utilities

    private func apiProcessError(_ data: Data?, error: Error, caller: String) {
        let error = error as NSError
        let detailStringValue = ""
//        if (data != nil) {
//            let dict = JSON(data: data)
//            let detail = dict["detail"]
//            detailStringValue = detail.stringValue
//            self.println("API ERROR: \(caller): \(detailStringValue) NSError = \(error.code) \(error.description)")
//        }
        if (caller != "apiPostEvents") { // Don't log errors that occur while reporting errors
            logToServer("client_error", data: "\(caller): \(detailStringValue) NSError = \(error.code) \(error.description)")
        }
    }
}

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

    /// MARK: POST users
    private func apiPostUsers(_ device_id: String, client_type: String, client_system: String) -> Promise<Void> {
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
        if let user = try? RWFramework.decoder.decode(User.self, from: data) {
            if let user_id = user.id {
                RWFrameworkConfig.setConfigValue("user_id", value: NSNumber(value: user_id), group: RWFrameworkConfig.ConfigGroup.client)
            } // TODO: Handle missing value
            if let username = user.username {
                RWFrameworkConfig.setConfigValue("username", value: username, group: RWFrameworkConfig.ConfigGroup.client)
            } // TODO: Handle missing value
            if let token = user.token {
                RWFrameworkConfig.setConfigValue("token", value: token, group: RWFrameworkConfig.ConfigGroup.client)
            } // TODO: Handle missing value
        }

        // postUsersSucceeded = true
    }


    /// MARK: POST sessions
    private func apiPostSessions() -> Promise<Data> {
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
        if let dict = try? RWFramework.decoder.decode(Session.self, from: data) {
            if let _session_id = dict.id {
                session_id = NSNumber(value: _session_id)
                RWFrameworkConfig.setConfigValue("session_id", value: session_id, group: RWFrameworkConfig.ConfigGroup.client)
            } // TODO: Handle missing value
            
            if let timeZone = dict.timezone {
                // timezone format: -0800 => (-|+)(HH)(MM)
                let sign = timeZone.first! == "+" ? 1 : -1
                let hoursStart = timeZone.index(after: timeZone.startIndex)
                let hoursEnd = timeZone.index(hoursStart, offsetBy: 2)
                let hours = Int(timeZone[hoursStart..<hoursEnd])!
                let minutes = Int(timeZone[hoursEnd...])!
                
                // convert timezone hours to seconds
                let seconds = (hours * 60 + minutes) * 60 * sign
                
                RWFrameworkConfig.setConfigValue("session_timezone", value: NSNumber(value: seconds), group: .session)
            }
        }

        let project_id = RWFrameworkConfig.getConfigValueAsNumber("project_id")
        self.apiGetProjectsIdTags(project_id, session_id: session_id)
        self.apiGetUIConfig(project_id, session_id: session_id)
        self.apiGetProjectsIdUIGroups(project_id, session_id: session_id)
        self.apiGetTagCategories()
        return self.apiGetProjectsId(project_id, session_id: session_id).then { data -> Project in
            RWFrameworkConfig.setConfigDataAsDictionary(data, key: "project")
            self.setupRecording()
            return try RWFramework.decoder.decode(Project.self, from: data)
        }
    }

    /// MARK: GET projects id
    private func apiGetProjectsId(_ project_id: NSNumber, session_id: NSNumber) -> Promise<Data> {
        return httpGetProjectsId(project_id, session_id: session_id).then { data -> Data in
            self.rwGetProjectsIdSuccess(data)
            return data
        }.catch { error in
            self.rwGetProjectsIdFailure(error)
            self.apiProcessError(nil, error: error, caller: "apiGetProjectsId")
        }
    }

    private func setupRecording() {
        let speak_enabled = RWFrameworkConfig.getConfigValueAsBool("speak_enabled")
        if (speak_enabled) {
            startAudioTimer()
            startUploadTimer()
            rwReadyToRecord()
        }
    }

    /// MARK: GET ui config
    private func apiGetUIConfig(_ project_id: NSNumber, session_id: NSNumber) {
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
    private func apiGetProjectsIdTags(_ project_id: NSNumber, session_id: NSNumber) -> Promise<Data> {
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
    private func apiGetProjectsIdUIGroups(_ project_id: NSNumber, session_id: NSNumber) -> Promise<Data> {
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
    private func apiGetTagCategories() -> Promise<Data> {
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

    /// MARK: POST envelopes
    func apiPostEnvelopes() -> Promise<Int> {
        let session_id = RWFrameworkConfig.getConfigValueAsNumber("session_id", group: RWFrameworkConfig.ConfigGroup.client)

        return httpPostEnvelopes(session_id).then { data -> Int in
            self.rwPostEnvelopesSuccess(data)
            
            // return the id of the created envelope
            let dict = try RWFramework.decoder.decode(Envelope.self, from: data)
            return dict.id
        }.catch { error in
            self.rwPostEnvelopesFailure(error)
            self.apiProcessError(nil, error: error, caller: "apiPostEnvelopes")
        }
    }

    /// MARK: PATCH envelopes id
    func apiPatchEnvelopesId(_ media: Media) -> Promise<Void> {
        let session_id = RWFrameworkConfig.getConfigValueAsNumber("session_id", group: RWFrameworkConfig.ConfigGroup.client)

        return httpPatchEnvelopesId(media, session_id: session_id).then { data -> Void in
            self.patchEnvelopesSuccess(data)
            self.rwPatchEnvelopesIdSuccess(data)
        }.catch { error in
            self.rwPatchEnvelopesIdFailure(error)
            self.apiProcessError(nil, error: error, caller: "apiPatchEnvelopesId")
        }
    }
    
    private func patchEnvelopesSuccess(_ data: Data) {
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
    
    func apiGetAudioTracks(_ dict: [String:String]) -> Promise<[AudioTrack]> {
        return httpGetAudioTracks(dict).then { data in
            try RWFramework.decoder.decode([AudioTrack].self, from: data)
        }.catch { error in
            self.apiProcessError(nil, error: error, caller: "apiGetAudioTracks")
        }
    }

    /// MARK: GET assets PUBLIC
    func apiGetAssets(_ dict: [String:String]) -> Promise<[Asset]> {
        return httpGetAssets(dict).then { data -> [Asset] in
            self.rwGetAssetsSuccess(data)
            return try RWFramework.decoder.decode([Asset].self, from: data)
        }.catch { error in
            self.rwGetAssetsFailure(error)
            self.apiProcessError(nil, error: error, caller: "apiGetAssets")
        }
    }
    
    func apiGetTimedAssets(_ dict: [String:String]) -> Promise<[TimedAsset]> {
        return httpGetTimedAssets(dict).then { data -> [TimedAsset] in
            return try RWFramework.decoder.decode([TimedAsset].self, from: data)
        }.catch { error in
            self.apiProcessError(nil, error: error, caller: "apiGetTimedAssets")
        }
    }

    func apiGetBlockedAssets() -> Promise<Data> {
        let session_id = RWFrameworkConfig.getConfigValueAsNumber("session_id", group: RWFrameworkConfig.ConfigGroup.client)
        let project_id = RWFrameworkConfig.getConfigValueAsNumber("project_id")

        return httpGetBlockedAssets(project_id, session_id: session_id)
    }
    
    /// MARK: PATCH assets id PUBLIC
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

    func apiGetVotesSummary(type: String? = nil, projectId: String? = nil, assetId: String? = nil) -> Promise<Data> {
        return httpGetVotesSummary(type: type, projectId: projectId, assetId: assetId)
    }
    
    func apiGetSpeakers(_ dict: [String:String]) -> Promise<[Speaker]> {
        return httpGetSpeakers(dict).then { data -> [Speaker] in
            self.rwGetSpeakersSuccess(data)
            return try RWFramework.decoder.decode([Speaker].self, from: data)
        }.catch { error in
            self.rwGetSpeakersFailure(error)
            self.apiProcessError(nil, error: error, caller: "apiGetSpeakers")
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

// Data models corresponding to server responses
private struct Session: Codable {
    let id: Int?
    let timezone: String?
}

private struct User: Codable {
    let id: Int?
    let username: String?
    let token: String?
}

private struct Stream: Codable {
    let id: Int?
    let url: String?
    let userMessage: String?
    enum CodingKeys: String, CodingKey {
        case id = "stream_id"
        case url = "stream_url"
        case userMessage = "user_message"
    }
}

private struct Envelope: Codable {
    let id: Int
}
//
//  RWFrameworkURLFactory.swift
//  RWFramework
//
//  Created by Joe Zobkiw on 2/2/15.
//  Copyright (c) 2015 Roundware. All rights reserved.
//

import Foundation
import CoreLocation

public class RWFrameworkURLFactory {

    private class func api2() -> String {
        return "api/2/"
    }

    class func postUsersURL() -> String {
        return RWFrameworkConfig.getConfigValueAsString(key: "base_url") + api2() + "users/"
    }

    class func postSessionsURL() -> String {
        return RWFrameworkConfig.getConfigValueAsString(key: "base_url") + api2() + "sessions/"
    }

    class func getProjectsIdURL(project_id: String, session_id: String) -> String {
        return RWFrameworkConfig.getConfigValueAsString(key: "base_url") + api2() + "projects/" + project_id + "/?session_id=" + session_id
    }

    class func getProjectsIdTagsURL(project_id: String, session_id: String) -> String {
        return RWFrameworkConfig.getConfigValueAsString(key: "base_url") + api2() + "projects/" + project_id + "/tags/?session_id=" + session_id
    }
    
    class func getProjectsIdUIGroupsURL(project_id: String, session_id: String) -> String {
        return RWFrameworkConfig.getConfigValueAsString(key: "base_url") + api2() + "projects/" + project_id + "/uigroups/?session_id=" + session_id
    }

    class func postStreamsURL() -> String {
        return RWFrameworkConfig.getConfigValueAsString(key: "base_url") + api2() + "streams/"
    }

    class func patchStreamsIdURL(stream_id: String) -> String {
        return RWFrameworkConfig.getConfigValueAsString(key: "base_url") + api2() + "streams/" + stream_id + "/"
    }

    class func postStreamsIdHeartbeatURL(stream_id: String) -> String {
        return RWFrameworkConfig.getConfigValueAsString(key: "base_url") + api2() + "streams/" + stream_id + "/heartbeat/"
    }

    class func postStreamsIdSkipURL(stream_id: String) -> String {
        return RWFrameworkConfig.getConfigValueAsString(key: "base_url") + api2() + "streams/" + stream_id + "/skip/"
    }

    class func postStreamsIdPlayAssetURL(stream_id: String) -> String {
        return RWFrameworkConfig.getConfigValueAsString(key: "base_url") + api2() + "streams/" + stream_id + "/playasset/"
    }

    class func postStreamsIdReplayAssetURL(stream_id: String) -> String {
        return RWFrameworkConfig.getConfigValueAsString(key: "base_url") + api2() + "streams/" + stream_id + "/replayasset/"
    }

    class func postStreamsIdPauseURL(stream_id: String) -> String {
        return RWFrameworkConfig.getConfigValueAsString(key: "base_url") + api2() + "streams/" + stream_id + "/pause/"
    }

    class func postStreamsIdResumeURL(stream_id: String) -> String {
        return RWFrameworkConfig.getConfigValueAsString(key: "base_url") + api2() + "streams/" + stream_id + "/resume/"
    }

    class func getStreamsIdCurrentURL(stream_id: String) -> String {
        return RWFrameworkConfig.getConfigValueAsString(key: "base_url") + api2() + "streams/" + stream_id + "/current/"
    }

    class func postEnvelopesURL() -> String {
        return RWFrameworkConfig.getConfigValueAsString(key: "base_url") + api2() + "envelopes/"
    }

    class func patchEnvelopesIdURL(envelope_id: String) -> String {
        return RWFrameworkConfig.getConfigValueAsString(key: "base_url") + api2() + "envelopes/" + envelope_id + "/"
    }

    class func getAssetsURL(dict: [String:String]) -> String {
        var url = RWFrameworkConfig.getConfigValueAsString(key: "base_url") + api2() + "assets/"
        if (dict.count > 0) {
            url += "?"
        }
        for (key, value) in dict {
            url += (key + "=" + value + "&")
        }
        return url
    }

    class func getAssetsIdURL(asset_id: String) -> String {
        return RWFrameworkConfig.getConfigValueAsString(key: "base_url") + api2() + "assets/" + asset_id + "/"
    }

    class func postAssetsIdVotesURL(asset_id: String) -> String {
        return RWFrameworkConfig.getConfigValueAsString(key: "base_url") + api2() + "assets/" + asset_id + "/votes/"
    }

    class func getAssetsIdVotesURL(asset_id: String) -> String {
        return RWFrameworkConfig.getConfigValueAsString(key: "base_url") + api2() + "assets/" + asset_id + "/votes/"
    }

    class func postEventsURL() -> String {
        return RWFrameworkConfig.getConfigValueAsString(key: "base_url") + api2() + "events/"
    }

}

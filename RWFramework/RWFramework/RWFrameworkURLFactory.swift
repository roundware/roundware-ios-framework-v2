//
//  RWFrameworkURLFactory.swift
//  RWFramework
//
//  Created by Joe Zobkiw on 2/2/15.
//  Copyright (c) 2015 Roundware. All rights reserved.
//

import Foundation
import CoreLocation

open class RWFrameworkURLFactory {
    class func api() -> String {
        return RWFrameworkConfig.getConfigValueAsString("base_url") + "api/2"
    }

    class func postUsersURL() -> String {
        return "\(api())/users/"
    }

    class func postSessionsURL() -> String {
        return "\(api())/sessions/"
    }

    class func getProjectsIdURL(_ project_id: NSNumber, session_id: NSNumber) -> String {
        return "\(api())/projects/\(project_id.stringValue)/?session_id=\(session_id.stringValue)"
    }

    class func getProjectsIdTagsURL(_ project_id: NSNumber, session_id: NSNumber) -> String {
        return "\(api())/projects/\(project_id.stringValue)/tags/?session_id=\(session_id.stringValue)"
    }

    class func getProjectsIdUIGroupsURL(_ project_id: NSNumber, session_id: NSNumber) -> String {
        return "\(api())/projects/\(project_id.stringValue)/uigroups/?session_id=\(session_id.stringValue)"
    }

    class func getTagCategoriesURL() -> String {
        return "\(api())/tagcategories/"
    }

    class func getUIConfigURL(_ project_id: NSNumber, session_id: NSNumber) -> String {
        return "\(api())/projects/\(project_id.stringValue)/uiconfig/?session_id=\(session_id.stringValue)"
    }

    class func postEnvelopesURL() -> String {
        return "\(api())/envelopes/"
    }

    class func patchEnvelopesIdURL(_ envelope_id: String) -> String {
        return "\(api())/envelopes/\(envelope_id)/"
    }

    class func getTimedAssetsURL(_ dict: [String:String]) -> String {
        return "\(api())/timedassets/\(dict.toUrlQuery())"
    }

    class func getAssetsURL(_ dict: [String:String]) -> String {
        return "\(api())/assets/\(dict.toUrlQuery())"
    }

    class func getBlockedAssetsURL(_ project_id: NSNumber, session_id: NSNumber) -> String {
        return "\(api())/assets/blocked/?project_id=\(project_id)&session_id=\(session_id)"
    }

    class func getAudioTracksURL(_ dict: [String:String]) -> String {
        return "\(api())/audiotracks/\(dict.toUrlQuery())"
    }

    class func getAssetsIdURL(_ asset_id: String) -> String {
        return "\(api())/assets/\(asset_id)/"
    }
    
    class func patchAssetsIdURL(_ asset_id: String) -> String {
        return "\(api())/assets/\(asset_id)/"
    }

    class func postAssetsIdVotesURL(_ asset_id: String) -> String {
        return "\(api())/assets/\(asset_id)/votes/"
    }

    class func getAssetsIdVotesURL(_ asset_id: String) -> String {
        return "\(api())/assets/\(asset_id)/votes/"
    }

    class func getVotesSummaryURL(_ dict: [String:String]) -> String {
        return "\(api())/votes/summary/\(dict.toUrlQuery())"
    }

    class func postEventsURL() -> String {
        return "\(api())/events/"
    }

    class func getSpeakersURL(_ dict: [String:String]) -> String {
        return "\(api())/speakers/\(dict.toUrlQuery())"
    }
}

fileprivate extension Dictionary where Key == String, Value == String {
    func toUrlQuery() -> String {
        var result = ""
        if self.count > 0 {
            result += "?"
        }
        for (key, value) in self {
            if !value.isEmpty {
                result += (key + "=" + value + "&")
            }
        }
        return result
    }
}

//
//  ProjectConfig.swift
//  Roundware
//
//  Created by Taylor Snead on 10/23/18.
//

import Foundation


struct Project: Codable {
    let id: Int
    let name: String
    let recording_radius: Int
    let out_of_range_url: String
    let demo_stream_url: String
    let geo_listen_enabled: Bool
    let repeat_mode: String
}

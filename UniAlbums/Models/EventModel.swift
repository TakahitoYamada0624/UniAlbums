//
//  AlbumModel.swift
//  UniAlbums
//
//  Created by Takahito Yamada on 2021/03/14.
//

import Foundation

class EventModel {
    let thumbnailString: String
    let event: String
    let date: String
    let picturesString: [String]
    
    init(data: [String: Any]) {
        self.thumbnailString = data["thumbnailString"] as? String ?? ""
        self.event = data["event"] as? String ?? ""
        self.date = data["date"] as? String ?? ""
        self.picturesString = data["picturesString"] as? [String] ?? [String]()
    }
}

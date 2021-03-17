//
//  GroupIds.swift
//  UniAlbums
//
//  Created by Takahito Yamada on 2021/03/17.
//

import Foundation

class GroupId {
    let groupId: String
    
    init(data: [String: Any]) {
        self.groupId = data["groupId"] as? String ?? ""
    }
}

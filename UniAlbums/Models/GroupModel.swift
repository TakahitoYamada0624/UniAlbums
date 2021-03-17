//
//  GroupModel.swift
//  UniAlbums
//
//  Created by Takahito Yamada on 2021/03/17.
//

import UIKit
import FirebaseStorage

class GroupModel {
    let groupId: String
    let name: String
    var topImageString: String
    let members: [String]
    
    init(data: [String: Any]) {
        self.groupId = data["groupId"] as? String ?? ""
        self.name = data["name"] as? String ?? ""
        self.topImageString = data["topImageString"] as? String ?? ""
        self.members = data["members"] as? [String] ?? [String]()
    }
}

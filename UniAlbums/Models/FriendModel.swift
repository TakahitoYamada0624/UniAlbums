//
//  FriendInfoModel.swift
//  UniAlbums
//
//  Created by Takahito Yamada on 2021/03/17.
//

import Foundation

class FriendModel {
    let uid: String
    let name: String
    var selected: Bool = false
    
    init(data: [String: Any]) {
        self.uid = data["uid"] as? String ?? ""
        self.name = data["name"] as? String ?? ""
    }
}

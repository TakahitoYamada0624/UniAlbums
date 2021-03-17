//
//  FriendId.swift
//  UniAlbums
//
//  Created by Takahito Yamada on 2021/03/17.
//

import Foundation

class FriendId {
    let friendId: String
    
    init(data: [String: Any]) {
        self.friendId = data["uid"] as? String ?? ""
    }
}

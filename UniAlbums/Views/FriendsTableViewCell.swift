//
//  FriendsTableViewCell.swift
//  UniAlbums
//
//  Created by Takahito Yamada on 2021/03/13.
//

import UIKit

class FriendsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var selectedButton: UIButton!
    
    var selectedFriend: Bool? {
        didSet {
            if selectedFriend == true {
                selectedButton.isHidden = false
                selectedButton.backgroundColor = UIColor.rgba(red: 255, green: 153, blue: 0, alpha: 1)
                selectedButton.layer.cornerRadius = 10
            }else{
                selectedButton.isHidden = true
            }
        }
    }
    
    var name: String? {
        didSet {
            nameLabel.text = name
        }
    }
}

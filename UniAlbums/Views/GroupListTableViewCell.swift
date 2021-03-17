//
//  GroupListTableViewCell.swift
//  UniAlbums
//
//  Created by Takahito Yamada on 2021/03/13.
//

import UIKit
import Nuke

class GroupListTableViewCell: UITableViewCell {
    
    @IBOutlet weak var groupImageView: UIImageView!
    @IBOutlet weak var groupNameLabel: UILabel!
    
    var groupString: String? {
        didSet {
            guard let url = URL(string: groupString ?? "") else {return}
            Nuke.loadImage(with: url, into: groupImageView)
            groupImageView.layer.cornerRadius = 25
        }
    }
    
    var groupName: String? {
        didSet {
            groupNameLabel.text = groupName
        }
    }
}

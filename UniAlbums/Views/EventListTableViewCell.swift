//
//  EventListTableViewCell.swift
//  UniAlbums
//
//  Created by Takahito Yamada on 2021/03/13.
//

import UIKit
import Nuke

class EventListTableViewCell: UITableViewCell {
    
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var eventLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    var thumbnailString: String? {
        didSet {
            guard let url = URL(string: thumbnailString ?? "") else {return}
            Nuke.loadImage(with: url, into: thumbnailImageView)
        }
    }
    
    var event: String? {
        didSet {
            eventLabel.text = event
        }
    }
    
    var date: String? {
        didSet {
            dateLabel.text = date
        }
    }
    
}



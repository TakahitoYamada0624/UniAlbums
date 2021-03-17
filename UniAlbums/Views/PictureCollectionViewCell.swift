//
//  PictureCollectionViewCell.swift
//  UniAlbums
//
//  Created by Takahito Yamada on 2021/03/14.
//

import UIKit
import Nuke

class PictureCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var pictureImageView: UIImageView!
    
    var image: UIImage? {
        didSet {
            pictureImageView.image = image
            pictureImageView.contentMode = .scaleAspectFill
        }
    }
    
    var imageString: String? {
        didSet {
            guard let url = URL(string: imageString ?? "") else {return}
            Nuke.loadImage(with: url, into: pictureImageView)
            pictureImageView.contentMode = .scaleAspectFill
        }
    }
    
}



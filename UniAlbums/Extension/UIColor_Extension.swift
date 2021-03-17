//
//  UIColor_Extension.swift
//  UniAlbums
//
//  Created by Takahito Yamada on 2021/03/17.
//

import UIKit

extension UIColor {
    static func rgba(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) -> UIColor {
        return UIColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
    }
}

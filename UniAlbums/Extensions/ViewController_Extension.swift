//
//  ViewController_Extension.swift
//  UniAlbums
//
//  Created by Takahito Yamada on 2021/03/20.
//

import UIKit

extension UIViewController {
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}

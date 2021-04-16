//
//  RandomString.swift
//  UniAlbums
//
//  Created by Takahito Yamada on 2021/04/05.
//

import Foundation

class RandomString {
    
    func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in
            letters.randomElement()!
        })
    }
    
}

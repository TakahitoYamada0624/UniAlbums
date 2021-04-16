//
//  SignOutViewController.swift
//  UniAlbums
//
//  Created by Takahito Yamada on 2021/03/13.
//

import UIKit
import FirebaseAuth

class SignOutViewController: UIViewController {
    
    @IBOutlet weak var signOutButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func signOut(_ sender: Any) {
        do {
            try Auth.auth().signOut()
            let storyboard = UIStoryboard(name: "SignUp", bundle: nil)
            let signUp = storyboard.instantiateViewController(withIdentifier: "SignUp")
            signUp.modalPresentationStyle = .fullScreen
            present(signUp, animated: false, completion: nil)
        } catch {
            print("サインアウトに失敗しました。")
        }
    }
}

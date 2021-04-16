//
//  AddFriendViewController.swift
//  UniAlbums
//
//  Created by Takahito Yamada on 2021/03/13.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class AddFriendViewController: UIViewController {
    
    @IBOutlet weak var uidLabel: UILabel!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchTextField.delegate = self
        showUserNumber()
    }
    
    func showUserNumber() {
        guard let uid = Auth.auth().currentUser?.uid else {return}
        Firestore.firestore().collection("Users").document(uid)
            .getDocument { (snapshot, err) in
                if let err = err {
                    print("ユーザーナンバーを取得できませんでした。",err)
                    return
                }
                guard let data = snapshot?.data() else {return}
                let uid = data["userNumber"] as? String
                self.uidLabel.text = uid
            }
    }
    
    @IBAction func searchUser(_ sender: Any) {
        guard let userNumber = searchTextField.text else {return}
        if userNumber.count == 0 {
            return
        }
        Firestore.firestore().collection("UserNumbers").document(userNumber)
            .getDocument { (snapshot, err) in
                if let err = err {
                    print("ユーザ情報の取得に失敗しました。", err)
                    return
                }
                if let document = snapshot?.data() {
                    guard let data = snapshot?.data() else {return}
                    guard let name = data["name"] as? String else {return}
                    guard let uid = data["uid"] as? String else {return}
                    self.showAddAlert(name: name, uid: uid)
                }
            }
    }
    
    func showAddAlert(name: String, uid: String) {
        let alert = UIAlertController(title: "\(name)さんを", message: "友達に追加しますか？", preferredStyle: .alert)
        let ok = UIAlertAction(title: "追加", style: .default) { (action) in
            self.getFriendInfo(uid: uid, name: name)
        }
        
        let cancel = UIAlertAction(title: "キャンセル", style: .cancel) { (action) in
            self.dismiss(animated: true, completion: nil)
        }
        alert.addAction(ok)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }
    
    func getFriendInfo(uid: String, name: String) {
        Firestore.firestore().collection("Users").document(uid)
            .getDocument { (snapshot, err) in
                if let err = err {
                    print("ユーザ情報の取得に失敗しました。", err)
                    return
                }
                guard let data = snapshot?.data() else {return}
                let friendProfile = FriendModel(data: data)
                let friendUid = friendProfile.uid
                guard let userId = Auth.auth().currentUser?.uid else {return}
                Firestore.firestore().collection("Users").document(userId)
                    .collection("Friends").document(friendUid)
                    .setData(["uid": uid, "name": name], completion: nil)
                self.dismiss(animated: true, completion: nil)
            }
        
    }
    
    func showNotFoundAlert() {
        let alert = UIAlertController(title: "ユーザーが見つかりませんでした。", message: "", preferredStyle: .alert)
        let ok = UIAlertAction(title: "ok", style: .default) { (action) in
            self.dismiss(animated: true, completion: nil)
        }
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
}

extension AddFriendViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

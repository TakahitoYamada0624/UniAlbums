//
//  MakeGroupViewController.swift
//  UniAlbums
//
//  Created by Takahito Yamada on 2021/03/14.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class MakeGroupViewController: UIViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let pickerController = UIImagePickerController()
    var selectedFriends = [String]()
    
    @IBOutlet weak var topImageButton: UIButton!
    @IBOutlet weak var groupNameTextField: UITextField!
    @IBOutlet weak var makeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        groupNameTextField.delegate = self
    }
    
    @IBAction func selectTopImage(_ sender: Any) {
        pickerController.delegate = self
        pickerController.allowsEditing = true
        present(pickerController, animated: true, completion: nil)
    }
    
    @IBAction func makeGroup(_ sender: Any) {
        guard let topImage = topImageButton.imageView?.image else {return}
        guard let uplaodImage = topImage.jpegData(compressionQuality: 0.8) else {return}
        let fileName = NSUUID().uuidString
        let storageRef = Storage.storage().reference().child("profile_image").child(fileName)
        
        storageRef.putData(uplaodImage, metadata: nil) { (metadata, err) in
            if let err = err {
                print("ストレージへの保存に失敗しました。", err)
                return
            }
            storageRef.downloadURL { (url, err) in
                if let err = err {
                    print("urlの取得に失敗しました。", err)
                    return
                }
                guard let urlString = url?.absoluteString else { return }
                self.setDataToFirestore(url: urlString)
            }
        }
    }
    
    func setDataToFirestore(url: String) {
        guard let uid = Auth.auth().currentUser?.uid else {return}
        selectedFriends.append(uid)
        let groupId = randomString(length: 10)
        let data = [
            "name": groupNameTextField.text,
            "topImageString": url,
            "groupId": groupId,
            "members": selectedFriends,
            "createdAt": Timestamp()
        ] as [String : Any]
        Firestore.firestore().collection("Groups").document(groupId)
            .setData(data) { (err) in
                if let err = err {
                    print("グループ情報の保存に失敗しました。", err)
                    return
                }
                self.addGroupToUsers(members: self.selectedFriends, groupId: groupId)
            }
    }
    
    func addGroupToUsers(members: [String], groupId: String){
        for (num, member) in members.enumerated() {
            Firestore.firestore().collection("Users").document(member)
                .collection("Groups").document(groupId)
                .setData(["groupId": groupId]) { (err) in
                    if let err = err {
                        print("グループ情報の保存に失敗しました。", err)
                        return
                    }
                    if (num == members.count - 1) {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func randomString(length: Int) -> String{
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editImage = info[.editedImage] as? UIImage{
            topImageButton.setImage(editImage.withRenderingMode(.alwaysOriginal), for: .normal)
        }else if let originalImage = info[.originalImage] as? UIImage{
            topImageButton.setImage(originalImage.withRenderingMode(.alwaysOriginal), for: .normal)
        }
        topImageButton.imageView?.contentMode = .scaleAspectFill
        dismiss(animated: true, completion: nil)
    }
}

extension MakeGroupViewController: UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

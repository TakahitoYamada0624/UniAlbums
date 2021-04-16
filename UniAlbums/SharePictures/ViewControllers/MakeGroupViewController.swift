//
//  SelectFriendsViewController.swift
//  UniAlbums
//
//  Created by Takahito Yamada on 2021/03/13.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class MakeGroupViewController: UIViewController {
    
    let indicator = UIActivityIndicatorView()
    let randomString = RandomString()
    var selectedFriends = [String]()
    let imagePicker = UIImagePickerController()
    var friends = [FriendModel]()
    let sectionTitle = ["メンバーを選択"]
    
    @IBOutlet weak var friendsTableView: UITableView!
    @IBOutlet weak var topImageButton: UIButton!
    @IBOutlet weak var groupNameTextField: UITextField!
    @IBOutlet weak var makeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        friendsTableView.dataSource = self
        friendsTableView.delegate = self
        friendsTableView.register(UINib(nibName: "FriendsTableViewCell", bundle: nil), forCellReuseIdentifier: "FriendsTableViewCell")
        
        setupView()
        setupIndicator()
        getFriendList()
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
    }
    
    func setupView() {
        topImageButton.layer.cornerRadius = 25
    }
    
    func setupIndicator() {
        indicator.center = view.center
        indicator.color = UIColor.rgba(red: 255, green: 153, blue: 0, alpha: 1)
        indicator.style = .large
        view.addSubview(indicator)
    }
    
    func getFriendList() {
        friends.removeAll()
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let friendsRef = Firestore.firestore().collection("Users").document(uid)
            .collection("Friends")
        friendsRef.getDocuments { (snapshots, err) in
            if let err = err {
                print("フレンドリストの取得に失敗しました。", err)
                return
            }
            snapshots?.documents.forEach({ (document) in
                let data = document.data()
                let friend = FriendModel(data: data)
                self.friends.append(friend)
                self.friendsTableView.reloadData()
            })
        }
    }
    
    @IBAction func selectTopImage(_ sender: Any) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: グループ作成ボタンをタップ時
    @IBAction func registerGroup(_ sender: Any) {
        saveTopImageToStorage()
    }
    
    func saveTopImageToStorage() {
        indicator.startAnimating()
        let topImage = topImageButton.imageView?.image
        guard let uploadImage = topImage?.jpegData(compressionQuality: 0.8) else {return}
        let fileName = NSUUID().uuidString
        let storageRef = Storage.storage().reference().child("profile_image").child(fileName)
        storageRef.putData(uploadImage, metadata: nil) { (metadata, err) in
            if let err = err {
                print("プロフィール情報を保存できませんでした。", err)
                return
            }
            storageRef.downloadURL { (url, err) in
                if let err = err {
                    print("urlを取得できませんでした。", err)
                    return
                }
                guard let imageString = url?.absoluteString else {return}
                self.saveGroupDataToFS(imageString: imageString)
            }
        }
    }
    
    func saveGroupDataToFS(imageString: String) {
        guard let uid = Auth.auth().currentUser?.uid else {return}
        selectedFriends = [uid]
        let name = groupNameTextField.text
        let groupId = randomString.randomString(length: 10)
        let data = [
            "groupId": groupId,
            "name": name,
            "topImageString": imageString,
            "members": selectedFriends,
            "createdAt": Timestamp()
        ] as [String : Any]
        
        let groupRef = Firestore.firestore().collection("Groups").document(groupId)
        groupRef.setData(data) { (err) in
            if let err = err {
                print("グループの情報の保存に失敗しました。", err)
                return
            }
            self.navigationController?.popViewController(animated: true)
            self.addGroupToUsers(groupId: groupId)
        }
    }
   
    func addGroupToUsers(groupId: String){
        for (num, member) in selectedFriends.enumerated() {
            Firestore.firestore().collection("Users").document(member)
                .collection("Groups").document(groupId)
                .setData(["groupId": groupId]) { (err) in
                    if let err = err {
                        print("グループ情報の保存に失敗しました。", err)
                        return
                    }
                    if (num == self.selectedFriends.count - 1) {
                        self.indicator.stopAnimating()
                        self.navigationController?.popViewController(animated: true)
                    }
                }
        }
    }
}

extension MakeGroupViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitle.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitle[section] 
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friends.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FriendsTableViewCell") as! FriendsTableViewCell
        cell.selectedFriend = friends[indexPath.row].selected
        cell.name = friends[indexPath.row].name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var selected: Bool = friends[indexPath.row].selected as? Bool ?? false
        let uid = friends[indexPath.row].uid
        if  selected == true {
            friends[indexPath.row].selected = false
            if let index = selectedFriends.firstIndex(of: uid) {
                selectedFriends.remove(at: index)
            }
            friendsTableView.reloadData()
        }else{
            friends[indexPath.row].selected = true
            selectedFriends.append(uid)
            friendsTableView.reloadData()
        }
    }
}

extension MakeGroupViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editImage = info[.editedImage] as? UIImage {
            topImageButton.setImage(editImage.withRenderingMode(.alwaysOriginal), for: .normal)
        } else if let originalImage = info[.originalImage] as? UIImage {
            topImageButton.setImage(originalImage.withRenderingMode(.alwaysOriginal), for: .normal)
        }
        topImageButton.imageView?.contentMode = .scaleAspectFill
        topImageButton.clipsToBounds = true
        dismiss(animated: true, completion: nil)
    }
}

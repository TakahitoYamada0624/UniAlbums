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
    
    let firebase = Firebase()
    let storage = Storage_com()
    let indicator = UIActivityIndicatorView()
    let randomString = RandomString()
    var selectedFriends = [String]()
    let imagePicker = UIImagePickerController()
    var friends = [FriendModel]()
    let sectionTitle = ["メンバーを選択"]
    var topImageDidSet: Bool = true
    private var topImageDidNotSet: Bool = true
    
    @IBOutlet weak var friendsTableView: UITableView!
    @IBOutlet weak var topImageButton: UIButton!
    @IBOutlet weak var groupNameTextField: UITextField!
    @IBOutlet weak var makeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        friendsTableView.dataSource = self
        friendsTableView.delegate = self
        friendsTableView.register(UINib(nibName: "FriendsTableViewCell", bundle: nil), forCellReuseIdentifier: "FriendsTableViewCell")
        
        groupNameTextField.delegate = self
        
        setupView()
        setupIndicator()
        getFriendList()
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
    }
    
    func setupView() {
        topImageButton.layer.cornerRadius = 25
        makeButton.isEnabled = false
        makeButton.backgroundColor = UIColor.rgba(red: 255, green: 153, blue: 0, alpha: 0.3)
    }
    
    func setupIndicator() {
        indicator.center = view.center
        indicator.color = UIColor.rgba(red: 255, green: 153, blue: 0, alpha: 1)
        indicator.style = .large
        view.addSubview(indicator)
    }
    
    func getFriendList() {
        firebase.fetchUserMembers { (friendsID) in
            
            self.firebase.fetchMembers(membersID: friendsID) { (friends) in
                self.friends = friends
                self.friendsTableView.reloadData()
            }
        }
    }
    
    @IBAction func selectTopImage(_ sender: Any) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func registerGroup(_ sender: Any) {
        saveTopImageToStorage()
    }
    
    func saveTopImageToStorage() {
        indicator.startAnimating()
        guard let topImage = topImageButton.imageView?.image else {return}
        guard let name = groupNameTextField.text else {return}
        let members = selectedFriends
        storage.saveImage(image: topImage, childName: "group_image") { (urlString) in
            
            self.firebase.saveGroup(name: name, topImageStr: urlString, members: members) { (bool) in
                if bool == true {
                    //MARK: 各ユーザへの追加をCloudFunctionで行う
                    //さらにグループ作成できた旨をalertで出す
                    self.indicator.stopAnimating()
                }
            }
        }
    }
    
    func checkMakeButtonIsEnabled() {
        let groupNameIsEmpty = groupNameTextField.text?.isEmpty ?? false
        let selectedFriendsArrIsEmpty = selectedFriends.count <= 0
        
        if groupNameIsEmpty || topImageDidNotSet || selectedFriendsArrIsEmpty {
            makeButton.isEnabled = false
            makeButton.backgroundColor = UIColor.rgba(red: 255, green: 153, blue: 0, alpha: 0.3)
        }else{
            makeButton.isEnabled = true
            makeButton.backgroundColor = UIColor.rgba(red: 255, green: 153, blue: 0, alpha: 1)
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
        var selected = friends[indexPath.row].selected as? Bool ?? false
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
        checkMakeButtonIsEnabled()
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
        topImageDidNotSet = false
        checkMakeButtonIsEnabled()
        dismiss(animated: true, completion: nil)
    }
}

extension MakeGroupViewController: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        checkMakeButtonIsEnabled()
    }
}

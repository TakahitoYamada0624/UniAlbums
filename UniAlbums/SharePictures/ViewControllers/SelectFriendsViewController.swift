//
//  SelectFriendsViewController.swift
//  UniAlbums
//
//  Created by Takahito Yamada on 2021/03/13.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class SelectFriendsViewController: UIViewController {
    
    var friends = [FriendModel]()
    var selectedFriends = [String]()

    @IBOutlet weak var friendsTableView: UITableView!
    @IBOutlet weak var nextButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        friendsTableView.dataSource = self
        friendsTableView.delegate = self
        friendsTableView.register(UINib(nibName: "FriendsTableViewCell", bundle: nil), forCellReuseIdentifier: "FriendsTableViewCell")
        
        fetchFriendList()
    }
    
    func fetchFriendList() {
        friends.removeAll()
        guard let uid = Auth.auth().currentUser?.uid else {return}
        Firestore.firestore().collection("Users").document(uid)
            .collection("Friends")
            .getDocuments { (snapshots, err) in
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
    
    @IBAction func moveToMakeGroupVC(_ sender: Any) {
        let storyboard = UIStoryboard(name: "MakeGroup", bundle: nil)
        let makeGroup = storyboard.instantiateViewController(withIdentifier: "MakeGroup") as! MakeGroupViewController
        makeGroup.selectedFriends = selectedFriends
        navigationController?.pushViewController(makeGroup, animated: true)
    }
}

extension SelectFriendsViewController: UITableViewDataSource, UITableViewDelegate {
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

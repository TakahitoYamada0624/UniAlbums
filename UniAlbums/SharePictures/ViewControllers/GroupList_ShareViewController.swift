//
//  GroupList_ShareViewController.swift
//  UniAlbums
//
//  Created by Takahito Yamada on 2021/03/13.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class GroupList_ShareViewController: UIViewController {
    
    var groupIds = [GroupId]()
    var groupModels = [GroupModel]()
    
    @IBOutlet weak var groupListTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        groupListTableView.dataSource = self
        groupListTableView.delegate = self
        groupListTableView.register(UINib(nibName: "GroupListTableViewCell", bundle: nil), forCellReuseIdentifier: "GroupListTableViewCell")
        
        fetchGroups()
    }
    
    @IBAction func makeGroup(_ sender: Any) {
        let storyboard = UIStoryboard(name: "SelectFriends", bundle: nil)
        let selectFriends = storyboard.instantiateViewController(withIdentifier: "SelectFriends")
        navigationController?.pushViewController(selectFriends, animated: true)
    }
    
    func fetchGroups() {
        groupIds.removeAll()
        guard let uid = Auth.auth().currentUser?.uid else {return}
        Firestore.firestore().collection("Users").document(uid)
            .collection("Groups")
            .getDocuments { (snapshots, err) in
                if let err = err {
                    print("グループ情報の取得に失敗しました。\(err)")
                    return
                }
                guard let documents = snapshots?.documents else {return}
                for (num, document) in documents.enumerated() {
                    let data = document.data()
                    let groupId = GroupId(data: data)
                    self.groupIds.append(groupId)
                    if num == documents.count - 1 {
                        self.fetchGroupInfo()
                    }
                }
            }
    }
    
    func fetchGroupInfo() {
        groupModels.removeAll()
        for (num, groupID) in groupIds.enumerated() {
            let groupId = groupID.groupId
            Firestore.firestore().collection("Groups").document(groupId)
                .getDocument { (snapshot, err) in
                    if let err = err {
                        print("グループ情報の取得に失敗しました。", err)
                        return
                    }
                    guard let data = snapshot?.data() else {return}
                    let group = GroupModel(data: data)
                    self.groupModels.append(group)
                    if num == self.groupIds.count - 1 {
                        self.groupListTableView.reloadData()
                    }
                }
        }
    }
}

extension GroupList_ShareViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupModels.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupListTableViewCell") as! GroupListTableViewCell
        cell.groupString = groupModels[indexPath.row].topImageString
        cell.groupName = groupModels[indexPath.row].name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "SharePictures", bundle: nil)
        let sharePictures = storyboard.instantiateViewController(withIdentifier: "SharePictures") as! SharePicturesViewController
        sharePictures.groupId = groupModels[indexPath.row].groupId
        navigationController?.pushViewController(sharePictures, animated: true)
    }
}

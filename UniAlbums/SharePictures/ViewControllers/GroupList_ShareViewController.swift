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
    let refreshControl = UIRefreshControl()
    
    @IBOutlet weak var groupListTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        groupListTableView.dataSource = self
        groupListTableView.delegate = self
        groupListTableView.register(UINib(nibName: "GroupListTableViewCell", bundle: nil), forCellReuseIdentifier: "GroupListTableViewCell")
        groupListTableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshTableView), for: .valueChanged)
        
        fetchGroups()
    }
    
    @objc func refreshTableView() {
        fetchGroups()
    }
    
    @IBAction func makeGroup(_ sender: Any) {
        let storyboard = UIStoryboard(name: "MakeGroup", bundle: nil)
        let makeGroup = storyboard.instantiateViewController(withIdentifier: "MakeGroup")
        makeGroup.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(makeGroup, animated: true)
    }
    
    func fetchGroups() {
        groupModels.removeAll()
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let groupsRef = Firestore.firestore().collection("Users").document(uid)
            .collection("Groups")
        groupsRef.getDocuments { (snapshot, err) in
            if let err = err {
                print("グループIDの取得に失敗しました。", err)
                return
            }
            let dispatchGroup = DispatchGroup()
            let dispatchQueue = DispatchQueue(label: "queue")
            snapshot?.documents.forEach({ (document) in
                dispatchGroup.enter()
                dispatchQueue.async(group: dispatchGroup) {  [weak self] in
                    let data = document.data()
                    guard let groupId = data["groupId"] as? String else {return}
                    self?.fetchGroupInfo(groupId: groupId, dispatchGroup: dispatchGroup)
                }
            })
            dispatchGroup.notify(queue: .main) {
                self.groupListTableView.reloadData()
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    func fetchGroupInfo(groupId: String, dispatchGroup: DispatchGroup) {
        let groupRef = Firestore.firestore().collection("Groups").document(groupId)
        groupRef.getDocument { (snapshot, err) in
            if let err = err {
                print("グループ情報の取得に失敗しました。", err)
                return
            }
            guard let data = snapshot?.data() else {return}
            let group = GroupModel(data: data)
            self.groupModels.append(group)
            dispatchGroup.leave()
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

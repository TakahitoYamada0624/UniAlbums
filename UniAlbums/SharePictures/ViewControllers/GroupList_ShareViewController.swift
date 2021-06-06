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
    
    let firebase = Firebase()
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
        
        groupListTableView.backgroundColor = UIColor.rgba(red: 197, green: 149, blue: 107, alpha: 0.3)
        
        fetchGroups()
    }
    
    @objc func refreshTableView() {
        refetchGroups()
    }
    
    @IBAction func makeGroup(_ sender: Any) {
        let storyboard = UIStoryboard(name: "MakeGroup", bundle: nil)
        let makeGroup = storyboard.instantiateViewController(withIdentifier: "MakeGroup")
        makeGroup.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(makeGroup, animated: true)
    }
    
    func fetchGroups() {
        firebase.fetchUserGroups { (groups) in
            self.groupModels = groups
            self.groupListTableView.reloadData()
        }
    }
    
    func refetchGroups() {
        firebase.fetchUserGroups { (groups) in
            self.groupModels = groups
            self.groupListTableView.reloadData()
            self.refreshControl.endRefreshing()
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
        let group = groupModels[indexPath.row]
        cell.groupString = group.topImageString
        cell.groupName = group.name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "SharePictures", bundle: nil)
        let sharePictures = storyboard.instantiateViewController(withIdentifier: "SharePictures") as! SharePicturesViewController
        sharePictures.groupId = groupModels[indexPath.row].groupId
        sharePictures.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(sharePictures, animated: true)
    }
}

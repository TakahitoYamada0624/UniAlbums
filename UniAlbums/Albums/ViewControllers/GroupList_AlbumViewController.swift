//
//  GroupList_AlbumViewController.swift
//  UniAlbums
//
//  Created by Takahito Yamada on 2021/03/13.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class GroupList_AlbumViewController: UIViewController {
    
    var indicator = UIActivityIndicatorView()
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
        
        showSignUpVC()
        setupIndicator()
        fetchGroups()
    }
    
    @objc func refreshTableView() {
        fetchGroups()
    }
    
    func showSignUpVC() {
        guard let uid = Auth.auth().currentUser?.uid else {
            let storyboard = UIStoryboard(name: "SignUp", bundle: nil)
            let signUpVC = storyboard.instantiateViewController(withIdentifier: "SignUp") as! SignUpViewController
            signUpVC.modalPresentationStyle = .fullScreen
            present(signUpVC, animated: true, completion: nil)
            return
        }
    }
    
    
    func setupIndicator() {
        indicator.center = view.center
        indicator.color = UIColor.rgba(red: 255, green: 153, blue: 0, alpha: 1)
//        indicator.style =
        view.addSubview(indicator)
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
                dispatchQueue.async(group: dispatchGroup) { [weak self] in
                    let data = document.data()
                    guard let groupId = data["groupId"] as? String else {return}
                    self?.fetchGroupsInfo(groupId: groupId, dispatch: dispatchGroup)
                }
            })
            
            dispatchGroup.notify(queue: .main) {
                self.groupListTableView.reloadData()
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    func fetchGroupsInfo(groupId: String, dispatch: DispatchGroup) {
        let groupRef = Firestore.firestore().collection("Groups").document(groupId)
        groupRef.getDocument { (snapshot, err) in
            if let err = err {
                print("グループ情報の取得に失敗しました。", err)
                return
            }
            guard let data = snapshot?.data() else {return}
            let group = GroupModel(data: data)
            self.groupModels.append(group)
            dispatch.leave()
        }
    }
}

extension GroupList_AlbumViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupModels.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupListTableViewCell", for: indexPath) as! GroupListTableViewCell
        cell.groupString = groupModels[indexPath.row].topImageString
        cell.groupName = groupModels[indexPath.row].name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "EventList", bundle: nil)
        let eventList = storyboard.instantiateViewController(withIdentifier: "EventList") as! EventListViewController
        eventList.groupId = groupModels[indexPath.row].groupId
        navigationController?.pushViewController(eventList, animated: true)
    }
    
}

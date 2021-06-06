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
    
    let firebase = Firebase()
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
        
        groupListTableView.backgroundColor = UIColor.rgba(red: 197, green: 149, blue: 107, alpha: 0.3)
        
        showSignUpVC()
        setupIndicator()
        fetchGroups()
    }
    
    func showSignUpVC() {
        guard let _ = UID.uid else {
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
        view.addSubview(indicator)
    }
    
    func fetchGroups() {
        firebase.fetchUserGroups { (groupModels) in
            self.groupModels = groupModels
            self.groupListTableView.reloadData()
        }
    }
    
    @objc func refreshTableView() {
        refetchGroups()
    }
    
    func refetchGroups() {
        firebase.fetchUserGroups { (groupModels) in
            self.groupModels = groupModels
            self.groupListTableView.reloadData()
            self.refreshControl.endRefreshing()
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
        let groupModel = groupModels[indexPath.row]
        cell.groupString = groupModel.topImageString
        cell.groupName = groupModel.name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "EventList", bundle: nil)
        let eventList = storyboard.instantiateViewController(withIdentifier: "EventList") as! EventListViewController
        eventList.groupId = groupModels[indexPath.row].groupId
        navigationController?.pushViewController(eventList, animated: true)
    }
    
}

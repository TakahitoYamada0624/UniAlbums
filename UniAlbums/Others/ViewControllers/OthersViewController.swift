//
//  OthersViewController.swift
//  UniAlbums
//
//  Created by Takahito Yamada on 2021/03/13.
//

import UIKit

class OthersViewController: UIViewController {
    
    let menu = [
        "友達追加", "サインアウト"
    ]
    
    @IBOutlet weak var othersTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        othersTableView.dataSource = self
        othersTableView.delegate = self
        othersTableView.register(UINib(nibName: "OthersTableViewCell", bundle: nil), forCellReuseIdentifier: "OthersTableViewCell")
        
    }
}

extension OthersViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menu.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "OthersTableViewCell") as! OthersTableViewCell
        cell.menuName.text = menu[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            let storyboard = UIStoryboard(name: "AddFriend", bundle: nil)
            let addFriend = storyboard.instantiateViewController(withIdentifier: "AddFriend")
            navigationController?.pushViewController(addFriend, animated: true)
        }else{
            let storyboard = UIStoryboard(name: "SignOut", bundle: nil)
            let signOut = storyboard.instantiateViewController(withIdentifier: "SignOut")
            navigationController?.pushViewController(signOut, animated: true)
        }
    }
}

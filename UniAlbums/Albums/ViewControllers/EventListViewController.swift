//
//  EventListViewController.swift
//  UniAlbums
//
//  Created by Takahito Yamada on 2021/03/13.
//

import UIKit
import FirebaseFirestore

class EventListViewController: UIViewController {
    
    var groupId: String = ""
    var events = [EventModel]()
    
    @IBOutlet weak var eventListTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        eventListTableView.dataSource = self
        eventListTableView.delegate = self
        eventListTableView.register(UINib(nibName: "EventListTableViewCell", bundle: nil), forCellReuseIdentifier: "EventListTableViewCell")
        
        fetchAlbum()
    }
    
    func fetchAlbum() {
        events.removeAll()
        Firestore.firestore().collection("Groups").document(groupId)
            .collection("Albums")
            .getDocuments { (snapshots, err) in
                if let err = err {
                    print("アルバムの取得に失敗しました。", err)
                    return
                }
                guard let documents = snapshots?.documents else {return}
                for (num, document) in documents.enumerated() {
                    let data = document.data()
                    let event = EventModel(data: data)
                    self.events.append(event)
                    if num == documents.count - 1 {
                        self.eventListTableView.reloadData()
                    }
                }
            }
    }
}

extension EventListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EventListTableViewCell", for: indexPath) as!EventListTableViewCell
        cell.thumbnailString = events[indexPath.row].thumbnailString
        cell.event = events[indexPath.row].event
        cell.date = events[indexPath.row].date
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Pictures", bundle: nil)
        let pictures = storyboard.instantiateViewController(withIdentifier: "Pictures") as! PicturesViewController
        pictures.picturesString = events[indexPath.row].picturesString
        navigationController?.pushViewController(pictures, animated: true)
    }
    
}

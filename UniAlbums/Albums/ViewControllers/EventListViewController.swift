//
//  EventListViewController.swift
//  UniAlbums
//
//  Created by Takahito Yamada on 2021/03/13.
//

import UIKit
import FirebaseFirestore

class EventListViewController: UIViewController {
    
    let firebase = Firebase()
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
        firebase.fetchAlbums(groupId: groupId) { (events) in
            self.events = events
            self.eventListTableView.reloadData()
        }
    }
    
    func refetchAlbum() {
        firebase.fetchAlbums(groupId: groupId) { (events) in
            self.events = events
            self.eventListTableView.reloadData()
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
        let event = events[indexPath.row]
        cell.thumbnailString = event.thumbnailString
        cell.event = event.event
        cell.date = event.date
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Pictures", bundle: nil)
        let pictures = storyboard.instantiateViewController(withIdentifier: "Pictures") as! PicturesViewController
        let event = events[indexPath.row]
        pictures.event = event.event
        pictures.picturesString = event.picturesString
        navigationController?.pushViewController(pictures, animated: true)
    }
    
}

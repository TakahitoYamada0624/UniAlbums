//
//  Firebase.swift
//  UniAlbums
//
//  Created by Takahito Yamada on 2021/05/28.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct UID {
    static let uid = Auth.auth().currentUser?.uid
}

class Firebase {
    
    let firestore = Firestore.firestore()
    let randomString = RandomString()
    
    func fetchUserGroups(completion: @escaping ([GroupModel]) -> Void) {
        var groupModels = [GroupModel]()
        guard let uid = UID.uid else {return}
        let userGroupsRef = firestore.collection("Users").document(uid)
            .collection("Groups")
        userGroupsRef.getDocuments { (snapshot, err) in
            if let err = err {
                print("ユーザのグループ取得に失敗しました。", err)
                return
            }
            let dispatchGroup = DispatchGroup()
            guard let documents = snapshot?.documents else {return}
            for document in documents {
                dispatchGroup.enter()
                let data = document.data()
                guard let groupId = data["groupId"] as? String else {return}
                let groupsRef = self.firestore.collection("Groups").document(groupId)
                groupsRef.getDocument { (snapshot, err) in
                    if let err = err {
                        print("グループ情報の取得に失敗しました。", err)
                        return
                    }
                    guard let data2 = snapshot?.data() else {return}
                    let group = GroupModel(data: data2)
                    groupModels.append(group)
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                completion(groupModels)
            }
            
        }
    }
    
    func fetchAlbums(groupId: String, completion: @escaping ([EventModel]) -> Void) {
        firestore.collection("Groups").document(groupId).collection("Albums")
            .getDocuments { (snapshot, err) in
                if let err = err {
                    print("アルバムの取得に失敗しました。", err)
                    return
                }
                guard let events = snapshot?.documents.map({ (document) -> EventModel in
                    let data = document.data()
                    let event = EventModel(data: data)
                    return event
                }) else {return}
                
                completion(events)
                
            }
    }
    
    func fetchUserMembers(completion: @escaping ([FriendId]) -> Void) {
        guard let uid = UID.uid else {return}
        firestore.collection("Users").document(uid).collection("Friends")
            .getDocuments { (snapshot, err) in
                if let err = err {
                    print("メンバーIDの取得に失敗しました。", err)
                    return
                }
                let documents = snapshot?.documents
                let membersID = documents?.map({ (document) -> FriendId in
                    let data = document.data()
                    let friendID = FriendId(data: data)
                    return friendID
                })
                
                completion(membersID ?? [FriendId]())
                
            }
    }
    
    //MARK: CloudFunctionsでの処理にする
    func fetchMembers(membersID: [FriendId],
                      completion: @escaping ([FriendModel]) -> Void) {
        var members = [FriendModel]()
        let dispatchGroup = DispatchGroup()
        for memberID in membersID {
            dispatchGroup.enter()
            let memberUID = memberID.friendId
            firestore.collection("Users").document(memberUID)
                .getDocument { (snapshot, err) in
                    if let err = err {
                        print("メンバー情報の取得に失敗しました。", err)
                        return
                    }
                    
                    guard let data = snapshot?.data() else {return}
                    let member = FriendModel(data: data)
                    members.append(member)
                    dispatchGroup.leave()
                }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(members)
        }
        
    }
    
    func saveAlbum(groupID: String, event: String, date: String,
                   topImageStr: String, imagesStr: [String],
                   completion: @escaping (Bool) -> Void) {
        
        let albumID = randomString.randomString(length: 10)
        let data = [
            "groupID": groupID,
            "albumID": albumID,
            "event": event,
            "date": date,
            "topImage": topImageStr,
            "Images": imagesStr
        ] as [String : Any]
        
        firestore.collection("Groups").document(groupID)
            .collection("Albums").document(albumID)
            .setData(data) { (err) in
                if let err = err {
                    print("アルバム情報を保存できませんでした。", err)
                    return
                }
                completion(true)
            }
    }
    
    //membersを辞書型にする
    func saveGroup(name: String, topImageStr: String, members: [String],
                   completion: @escaping (Bool) -> Void) {
        
        let groupID = randomString.randomString(length: 6)
        let data = [
            "groupID": groupID,
            "name": name,
            "topImage": topImageStr,
            "members": members,
            "createdAt": Timestamp()
        ] as [String : Any]
        
        firestore.collection("Groups").document(groupID)
            .setData(data) { (err) in
                if let err = err {
                    print("グループの保存に失敗しました。", err)
                    return
                }
                
                completion(true)
                
            }
    }
    
}

class  Storage_com {
    
    let randomString = RandomString()
    let storage = Storage.storage().reference()
    
    func saveImage(image: UIImage, childName: String,
                   completion: @escaping (String) -> Void) {
        guard let uploadImage = image.jpegData(compressionQuality: 0.7) else {return}
        let fileName = randomString.randomString(length: 10)
        let storageRef = storage.child(childName).child(fileName)
        storageRef.putData(uploadImage, metadata: nil) { (metadata, err) in
            if let err = err {
                print("画像の保存に失敗しました。", err)
                return
            }
            storageRef.downloadURL { (url, err) in
                if let err = err {
                    print("画像のダウンロードに失敗しました。", err)
                    return
                }
                
                guard let urlString = url?.absoluteString else {return}
                completion(urlString)
                
            }
        }
    }
    
    func saveImages(images: [UIImage], completion: @escaping ([String]) -> Void) {
        var urlStrings = [String]()
        let dispatchGroup = DispatchGroup()
        
        for image in images {
            dispatchGroup.enter()
            guard let uploadImage = image.jpegData(compressionQuality: 0.8) else {return}
            let fileName = randomString.randomString(length: 20)
            let storageRef = storage.child("album_images").child(fileName)
            storageRef.putData(uploadImage, metadata: nil) { (metadata, err) in
                if let err = err {
                    print("画像の保存に失敗しました。", err)
                    return
                }
                storageRef.downloadURL { (url, err) in
                    if let err = err {
                        print("画像のダウンロードに失敗しました。", err)
                        return
                    }
                    guard let urlString = url?.absoluteString else {return}
                    urlStrings.append(urlString)
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(urlStrings)
        }
        
    }
    
}

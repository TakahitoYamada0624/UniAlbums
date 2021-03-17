//
//  SharePicturesViewController.swift
//  UniAlbums
//
//  Created by Takahito Yamada on 2021/03/13.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import DKImagePickerController

class SharePicturesViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    let imagePickerController = UIImagePickerController()
    let dkPickerController = DKImagePickerController()
    let datePicker = UIDatePicker()
    let scrollView = UIScrollView()
    var imageArr: [UIImage] = []
    var imageUrl = [String]()
    var groupId: String = ""
    
    @IBOutlet weak var selectThumbnailButton: UIButton!
    @IBOutlet weak var thumbnaimImageView: UIImageView!
    @IBOutlet weak var selectPicturesButton: UIButton!
    @IBOutlet weak var picturesCollectionView: UICollectionView!
    @IBOutlet weak var dateTextField: UITextField!
    @IBOutlet weak var eventTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        picturesCollectionView.dataSource = self
        picturesCollectionView.delegate = self
        eventTextField.delegate = self
        picturesCollectionView.register(UINib(nibName: "PictureCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "PictureCollectionViewCell")
        
        setToolBar()
        collectionViewLayout()
        
        NotificationCenter.default.addObserver(self, selector: #selector(showKeyboard(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(hideKeyboard(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    func setToolBar() {
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 35))
        let doneButton = UIBarButtonItem(title: "完了", style: .done, target: self, action: #selector(saveDate))
        let cancelButton = UIBarButtonItem(title: "キャンセル", style: .plain, target: self, action: #selector(cancel))
        toolBar.setItems([cancelButton, doneButton], animated: true)
        dateTextField.inputView = datePicker
        dateTextField.inputAccessoryView = toolBar
        datePicker.datePickerMode = .date
        datePicker.locale = NSLocale(localeIdentifier: "ja_JP") as Locale
        datePicker.preferredDatePickerStyle = .wheels
    }
    
    @objc func showKeyboard(_ notification: Notification) {
        let userInfo = notification.userInfo
        let keyboardSize = (userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseIn, animations: {self.view.frame = CGRect(x: 0, y: -(keyboardSize.height), width: self.view.bounds.width, height: self.view.bounds.height)}, completion: nil)
    }
    
    @objc func hideKeyboard(_ notification: Notification) {
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseIn, animations: {self.view.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)}, completion: nil)
    }
    
    func collectionViewLayout() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        picturesCollectionView.collectionViewLayout = layout
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func selectThumbnail(_ sender: Any) {
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func selectPictures(_ sender: Any) {
        selectPic { (image) in
            self.picturesCollectionView.reloadData()
        }
    }
    
    func selectPic(completion: @escaping (UIImage) -> ()) {
        imageArr.removeAll()
        dkPickerController.maxSelectableCount = 50
        dkPickerController.sourceType = .photo
        dkPickerController.showsCancelButton = true
        present(dkPickerController, animated: true, completion: nil)
        dkPickerController.didSelectAssets = { (assets: [DKAsset]) in
            for asset in assets {
                asset.fetchOriginalImage { (image, info) in
                    if let image = image {
                        self.imageArr.append(image)
                        completion(image)
                        
                    }
                }
            }
        }
    }
    
    @objc func saveDate() {
        dateTextField.endEditing(true)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = NSLocale(localeIdentifier: "ja_JP") as Locale
        dateFormatter.dateStyle = DateFormatter.Style.medium
        dateTextField.text = dateFormatter.string(from: datePicker.date)
    }
    
    @objc func cancel() {
        dateTextField.endEditing(true)
        dateTextField.text = ""
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editImage = info[.editedImage] as? UIImage{
            thumbnaimImageView.setImage(editImage)
        }else if let originalImage = info[.originalImage] as? UIImage{
            thumbnaimImageView.setImage(originalImage)
        }
        thumbnaimImageView.contentMode = .scaleAspectFill
        dismiss(animated: true, completion: nil)
        
    }
    
    @IBAction func addPicturesToAlbum(_ sender: Any) {
        guard let image = thumbnaimImageView.image else {return}
        if imageArr.count == 0 {return}
        if dateTextField.text?.count == 0 {return}
        if eventTextField.text?.count == 0 {return}
        saveThumbnail(image: image)
    }
    
    func saveThumbnail(image: UIImage) {
        let fileName = NSUUID().uuidString
        guard let uploadImage = image.jpegData(compressionQuality: 0.8) else {return}
        let storageRef = Storage.storage().reference().child("thumbnail").child(fileName)
        storageRef.putData(uploadImage, metadata: nil) { (metadata, err) in
            if let err = err {
                print("画像の保存に失敗しました。", err)
                return
            }
            storageRef.downloadURL { (url, err) in
                if let err = err {
                    print("urlの取得に失敗しました。", err)
                    return
                }
                guard let urlString = url?.absoluteString else { return }
                self.savePictures(thumbnailUrl: urlString)
            }
        }
    }
    
    func savePictures(thumbnailUrl: String) {
        imageUrl.removeAll()
        for (num, image) in imageArr.enumerated() {
            let fileName = NSUUID().uuidString
            guard let uploadImage = image.jpegData(compressionQuality: 0.8) else {return}
            let storageRef = Storage.storage().reference().child("albums").child(fileName)
            storageRef.putData(uploadImage, metadata: nil) { (metadata, err) in
                if let err = err {
                    print("画像の保存に失敗しました。", err)
                    return
                }
                storageRef.downloadURL { (url, err) in
                    if let err = err {
                        print("urlの取得に失敗しました。", err)
                        return
                    }
                    guard let urlString = url?.absoluteString else { return }
                    self.imageUrl.append(urlString)
                    if num == self.imageArr.count - 1{
                        self.saveAlbumToFirestore(thumbnailUrl: thumbnailUrl)
                    }
                }
            }
        }
    }
    
    func saveAlbumToFirestore(thumbnailUrl: String) {
        let albumId = randomString(length: 10)
        let data = [
            "albumId": albumId,
            "date": dateTextField.text,
            "event": eventTextField.text,
            "thumbnailString": thumbnailUrl,
            "picturesString": imageUrl
        ] as [String : Any]
        Firestore.firestore().collection("Groups").document(groupId)
            .collection("Albums").document(albumId)
            .setData(data) { (err) in
                if let err = err {
                    print("アルバム情報の保存に失敗しました。", err)
                    return
                }
                self.navigationController?.popViewController(animated: true)
            }
    }
    
    func randomString(length: Int) -> String{
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
}

extension SharePicturesViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageArr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: 100)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PictureCollectionViewCell", for: indexPath) as! PictureCollectionViewCell
        cell.image = imageArr[indexPath.row]
        return cell
    }
    
}





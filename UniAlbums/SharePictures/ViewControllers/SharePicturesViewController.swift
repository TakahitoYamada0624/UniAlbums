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

class SharePicturesViewController: UIViewController, UITextFieldDelegate {
    
    let imagePickerController = UIImagePickerController()
    let dkPickerController = DKImagePickerController()
    let datePicker = UIDatePicker()
    let scrollView = UIScrollView()
    var imageArr = [UIImage]()
    var imageStrings = [String]()
    var groupId: String = ""
    let imagePicker = UIImagePickerController()
    let randomString = RandomString()
    var topImageString: String?
    let indicator = UIActivityIndicatorView()
    
    @IBOutlet weak var thumbnailButton: UIButton!
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
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        
        setToolBar()
        collectionViewLayout()
        setupView()
        setupIndicator()
    }
    
    func setupView() {
        thumbnailButton.layer.cornerRadius = 30
    }
    
    func setToolBar() {
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 35))
        let doneButton = UIBarButtonItem(title: "完了", style: .done, target: self, action: #selector(setDate))
        let cancelButton = UIBarButtonItem(title: "キャンセル", style: .plain, target: self, action: #selector(cancel))
        toolBar.setItems([cancelButton, doneButton], animated: true)
        dateTextField.inputView = datePicker
        dateTextField.inputAccessoryView = toolBar
        datePicker.datePickerMode = .date
        datePicker.locale = NSLocale(localeIdentifier: "ja_JP") as Locale
        datePicker.preferredDatePickerStyle = .wheels
    }
    
    func collectionViewLayout() {
        let layout = UICollectionViewFlowLayout()
//        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        picturesCollectionView.collectionViewLayout = layout
    }
    
    func setupIndicator() {
        indicator.center = view.center
        indicator.color = UIColor.rgba(red: 255, green: 153, blue: 0, alpha: 1)
        indicator.style = .large
        view.addSubview(indicator)
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
                        self.picturesCollectionView.reloadData()
                    }
                }
            }
        }
    }
    
    @objc func setDate() {
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
    
    @IBAction func saveDataToFS(_ sender: Any) {
        saveTopImage()
    }
    
    func saveTopImage() {
        indicator.startAnimating()
        let image = thumbnailButton.imageView?.image
        guard let uploadImage = image?.jpegData(compressionQuality: 0.7) else {return}
        let fileName = randomString.randomString(length: 20)
        let storageRef = Storage.storage().reference().child("group_image").child(fileName)
        storageRef.putData(uploadImage, metadata: nil) { (metadata, err) in
            if let err = err {
                print("トプ画の保存に失敗しました。", err)
                return
            }
            storageRef.downloadURL { (url, err) in
                if let err = err {
                    print("urlのダウンロードに失敗しました。", err)
                    return
                }
                guard let imageString = url?.absoluteString else {return}
                self.topImageString = imageString
                self.savePictures()
            }
        }
    }
    
    func savePictures() {
        let dispatchGroup = DispatchGroup()
        let dispatchQueue = DispatchQueue(label: "queue")
        
        for image in imageArr {
            dispatchGroup.enter()
            dispatchQueue.async(group: dispatchGroup) { [weak self] in
                
                guard let fileName = self?.randomString.randomString(length: 20) else {return}
                guard let uploadImage = image.jpegData(compressionQuality: 0.8) else {return}
                let storageRef = Storage.storage().reference().child("album_images").child(fileName)
                storageRef.putData(uploadImage, metadata: nil) { (metadata, err) in
                    if let err = err {
                        print("写真の保存に失敗しました。",err)
                        return
                    }
                    storageRef.downloadURL { (url, err) in
                        if let err = err {
                            print("urlのダウンロードに失敗しました。", err)
                            return
                        }
                        guard let imageString = url?.absoluteString else {return}
                        self?.imageStrings.append(imageString)
                        dispatchGroup.leave()
                    }
                }
            }
        }
        dispatchGroup.notify(queue: .main) {
            self.saveAlbumToFS()
            self.indicator.stopAnimating()
        }
    }
    
    func saveAlbumToFS() {
        let albumId = randomString.randomString(length: 10)
        let topImage = self.topImageString
        let event = eventTextField.text
        let date = dateTextField.text
        
        let albumRef = Firestore.firestore().collection("Groups").document(groupId)
            .collection("Albums").document(albumId)
        
        let data = [
            "albumId": albumId,
            "thumbnailString": topImage,
            "picturesString": imageStrings,
            "event": event,
            "date": date
        ] as [String : Any]
        albumRef.setData(data) { (err) in
            if let err = err {
                print("アルバムの保存に失敗しました。", err)
                return
            }
            self.navigationController?.popViewController(animated: true)
        }
    }
}

extension SharePicturesViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageArr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = view.bounds.size.width / 3 - 20
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PictureCollectionViewCell", for: indexPath) as! PictureCollectionViewCell
        cell.image = imageArr[indexPath.row]
        return cell
    }
}

extension SharePicturesViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editImage = info[.editedImage] as? UIImage {
            thumbnailButton.setImage(editImage.withRenderingMode(.alwaysOriginal), for: .normal)
        } else if let originalImage = info[.originalImage] as? UIImage {
            thumbnailButton.setImage(originalImage.withRenderingMode(.alwaysOriginal), for: .normal)
        }
        thumbnailButton.imageView?.contentMode = .scaleAspectFill
        thumbnailButton.clipsToBounds = true
        dismiss(animated: true, completion: nil)
    }
}

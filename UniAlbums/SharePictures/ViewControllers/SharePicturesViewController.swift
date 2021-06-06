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

class SharePicturesViewController: UIViewController {
    
    var groupId: String = ""
    let imagePickerController = UIImagePickerController()
    let dkPickerController = DKImagePickerController()
    let datePicker = UIDatePicker()
    let scrollView = UIScrollView()
    var imageArr = [UIImage]()
    var imageStrings = [String]()
    let imagePicker = UIImagePickerController()
    let randomString = RandomString()
    var topImageString: String?
    let indicator = UIActivityIndicatorView()
    var topImageDidNotSet:Bool = true
    let storageCom = Storage_com()
    let firebase = Firebase()
    
    @IBOutlet weak var thumbnailButton: UIButton!
    @IBOutlet weak var selectPicturesButton: UIButton!
    @IBOutlet weak var picturesCollectionView: UICollectionView!
    @IBOutlet weak var dateTextField: UITextField!
    @IBOutlet weak var eventTextField: UITextField!
    @IBOutlet weak var addPicturesButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        picturesCollectionView.dataSource = self
        picturesCollectionView.delegate = self
        eventTextField.delegate = self
        picturesCollectionView.register(UINib(nibName: "PictureCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "PictureCollectionViewCell")
        dateTextField.delegate = self
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        
        scrollView.backgroundColor = UIColor.rgba(red: 197, green: 149, blue: 107, alpha: 0.3)
        
        setToolBar()
        collectionViewLayout()
        setupView()
        setupIndicator()
    }
    
    func setupView() {
        thumbnailButton.layer.cornerRadius = 30
        addPicturesButton.isEnabled = false
        addPicturesButton.backgroundColor = UIColor.rgba(red: 255, green: 153, blue: 0, alpha: 0.3)
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
        dkPickerController.maxSelectableCount = 50
        dkPickerController.sourceType = .photo
        dkPickerController.showsCancelButton = true
        present(dkPickerController, animated: true, completion: nil)
        selectPicturess()
    }
    
    private func selectPicturess() {
        let dispatchGroup = DispatchGroup()
        var images = [UIImage]()
        dkPickerController.didSelectAssets = { (assets: [DKAsset]) in
            if assets.count == 0 {
                print("count", assets.count)
                self.picturesCollectionView.reloadData()
                return
            }
            for asset in assets {
                dispatchGroup.enter()
                asset.fetchOriginalImage { (image, info) in
                    if let image = image {
                        images.append(image)
                        print("ok1")
                        dispatchGroup.leave()
                    }
                }
            }
            dispatchGroup.notify(queue: .main) {
                self.imageArr = images
                self.picturesCollectionView.reloadData()
                self.checkButtonIsEnabled()
            }
        }
    }
    
    func checkButtonIsEnabled() {
        let eventIsEmpty = eventTextField.text?.isEmpty ?? false
        let dateIsEmpty = dateTextField.text?.isEmpty ?? false
        let imageArrIsEmpty = imageArr.count <= 0
        
        if eventIsEmpty || dateIsEmpty || imageArrIsEmpty || topImageDidNotSet {
            addPicturesButton.isEnabled = false
            addPicturesButton.backgroundColor = UIColor.rgba(red: 255, green: 153, blue: 0, alpha: 0.3)
        }else{
            addPicturesButton.isEnabled = true
            addPicturesButton.backgroundColor = UIColor.rgba(red: 255, green: 153, blue: 0, alpha: 1)
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
        
        checkButtonIsEnabled()
    }
    
    @objc func cancel() {
        dateTextField.endEditing(true)
        dateTextField.text = ""
    }
    
    @IBAction func saveDataToFS(_ sender: Any) {
        saveAlbumToFS()
    }
    
    func saveAlbumToFS() {
        guard let image = thumbnailButton.imageView?.image else {return}
        let groupID = self.groupId
        guard let event = eventTextField.text else {return}
        guard let date = dateTextField.text else {return}
        
        storageCom.saveImage(image: image, childName: "group_images") { (urlString) in
            
            self.storageCom.saveImages(images: self.imageArr) { (urlStrings) in
                
                self.firebase.saveAlbum(groupID: groupID, event: event, date: date, topImageStr: urlString, imagesStr: urlStrings) { (bool) in
                    
                    if bool == true {
                        self.navigationController?.popViewController(animated: true)
                    }else{
                    }
                }
            }
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
        topImageDidNotSet = false
        checkButtonIsEnabled()
        dismiss(animated: true, completion: nil)
    }
}

extension SharePicturesViewController: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        checkButtonIsEnabled()
    }
}

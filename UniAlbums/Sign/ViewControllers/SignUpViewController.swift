//
//  SignUpViewController.swift
//  UniAlbums
//
//  Created by Takahito Yamada on 2021/03/15.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class SignUpViewController: UIViewController {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var signInButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        nameTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        setupView()
    }
    
    func setupView() {
        signUpButton.backgroundColor = UIColor.rgba(red: 255, green: 153, blue: 0, alpha: 1)
        signUpButton.layer.cornerRadius = 10
    }
    
    @IBAction func signUp(_ sender: Any) {
        guard let name = nameTextField.text else {return}
        guard let email = emailTextField.text else {return}
        guard let password = passwordTextField.text else {return}
        Auth.auth().createUser(withEmail: email, password: password) { (result, err) in
            if let err = err {
                print("ユーザ情報の登録に失敗しました。", err)
                return
            }
            guard let uid = Auth.auth().currentUser?.uid else {return}
            let userNumber = self.randomNumber(length: 6)
            
            let data = [
                "name": name,
                "uid": uid,
                "userNumber": userNumber,
                "createdAt": Timestamp()
            ] as [String : Any]
            
            Firestore.firestore().collection("Users").document(uid)
                .setData(data) { (err) in
                    if let err = err {
                        print("ユーザ情報の保存に失敗しました。", err)
                        return
                    }
                    self.setUserNumber(userNumber: userNumber, uid: uid, name: name)
                }
        }
    }
    
    func setUserNumber(userNumber: String, uid: String, name: String) {
        let data = [
            "uid": uid,
            "name": name
        ]
        Firestore.firestore().collection("UserNumbers").document(userNumber)
            .setData(data) { (err) in
                if let err = err {
                    print("ユーザナンバーの保存に失敗しました。", err)
                    return
                }
                self.dismiss(animated: true, completion: nil)
            }
    }
    
    @IBAction func moveToSignIn(_ sender: Any) {
        let storyboard = UIStoryboard(name: "SignIn", bundle: nil)
        let signIn = storyboard.instantiateViewController(withIdentifier: "SignIn")
        signIn.modalPresentationStyle = .fullScreen
        present(signIn, animated: true, completion: nil)
    }
    
    func randomNumber(length: Int) -> String {
        let letters = "0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
}

extension SignUpViewController: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        let nameEmpty = nameTextField.text?.isEmpty ?? false
        let emailEmpty = emailTextField.text?.isEmpty ?? false
        let passwordEmpty = passwordTextField.text?.isEmpty ?? false
        
        if nameEmpty || emailEmpty || passwordEmpty {
            signUpButton.isEnabled = false
            signUpButton.backgroundColor = UIColor.rgba(red: 255, green: 153, blue: 0, alpha: 0.5)
        }else{
            signUpButton.isEnabled = true
            signUpButton.backgroundColor = UIColor.rgba(red: 255, green: 153, blue: 0, alpha: 1)
        }
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

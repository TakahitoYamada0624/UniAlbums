//
//  SignInViewController.swift
//  UniAlbums
//
//  Created by Takahito Yamada on 2021/03/15.
//

import UIKit
import FirebaseAuth

class SignInViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailTextField.delegate = self
        passwordTextField.delegate = self
        setupView()
    }
    
    func setupView() {
        signInButton.backgroundColor = UIColor.rgba(red: 255, green: 153, blue: 0, alpha: 1)
        signInButton.layer.cornerRadius = 10
    }
    
    @IBAction func signInButton(_ sender: Any) {
        guard let email = emailTextField.text else {return}
        guard let password = passwordTextField.text else {return}
        Auth.auth().signIn(withEmail: email, password: password) { (result, err) in
            if let err = err {
                print("サインインに失敗しました。", err)
                return
            }
            self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func moveToSignUp(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

extension SignInViewController: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        let emailEmpty = emailTextField.text?.isEmpty ?? false
        let passwordEmpty = passwordTextField.text?.isEmpty ?? false
        
        if emailEmpty || passwordEmpty {
            signInButton.isEnabled = false
            signInButton.backgroundColor = UIColor.rgba(red: 255, green: 153, blue: 0, alpha: 1)
        }else{
            signInButton.isEnabled = true
            signInButton.backgroundColor = UIColor.rgba(red: 255, green: 153, blue: 0, alpha: 1)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

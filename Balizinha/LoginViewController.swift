//
//  ViewController.swift
// Balizinha
//
//  Created by Bobby Ren on 5/8/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import Firebase

class LoginViewController: UIViewController {
    
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var inputEmail: UITextField!
    @IBOutlet weak var inputPassword: UITextField!
    @IBOutlet weak var buttonLogin: UIButton!
    @IBOutlet weak var buttonFacebook: UIButton!
    @IBOutlet weak var buttonSignup: UIButton!
    var shouldCancelInput: Bool = false
    
    let facebookLogin = FBSDKLoginManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let keyboardNextButtonView = UIToolbar()
        keyboardNextButtonView.sizeToFit()
        keyboardNextButtonView.barStyle = UIBarStyle.black
        keyboardNextButtonView.isTranslucent = true
        keyboardNextButtonView.tintColor = UIColor.white
        let button: UIBarButtonItem = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.done, target: self, action: #selector(cancelInput))
        let flex: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        keyboardNextButtonView.setItems([flex, button], animated: true)

        inputEmail.inputAccessoryView = keyboardNextButtonView
        inputPassword.inputAccessoryView = keyboardNextButtonView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func didClickButton(_ button: UIButton) {
        if button == buttonFacebook {
            handleFacebookUser()
        }
        else if button == buttonSignup {
            performSegue(withIdentifier: "GoToSignup", sender: button)
        }
        else if button == buttonLogin {
            loginUser()
        }
    }
    
    func loginUser() {
        let email = inputEmail.text!
        let password = inputPassword.text!
        
        if email.count == 0 {
            print("Invalid email")
            return
        }
        
        if password.count == 0 {
            print("Invalid password")
            return
        }
        AuthService.shared.loginUser(email: email, password: password) { [weak self] (error) in
            if let error: NSError = error as NSError? {
                print("Error: \(error)")
                if error.code == 17009 {
                    self?.simpleAlert("Could not log in", message: "Invalid password.")
                }
                else if error.code == 17011 {
                    // invalid user. firebase error message is too wordy
                    self?.simpleAlert("User not found", message: "Please sign up to create an account.")
                }
                else {
                    self?.simpleAlert("Could not log in", defaultMessage: nil,  error: error)
                }
            }
            else {
                print("LoginLogout: LoginSuccess from email")
                // let observer handle things
            }
        }
    }
    
    func handleFacebookUser() {
        let permissions = ["email", "public_profile"]
        FBSDKLoginManager().logOut() // in case user has switched accounts
        facebookLogin.logIn(withReadPermissions: permissions, from: self) { (result, error) in
            if error != nil {
                print("Facebook login failed. Error \(String(describing: error))")
            } else if (result?.isCancelled)! {
                print("Facebook login was cancelled.")
            } else {
                print("Facebook login success: \(String(describing: result))")
                let accessToken = FBSDKAccessToken.current().tokenString
                
                let credential = FacebookAuthProvider.credential(withAccessToken: accessToken!)
                firAuth.signIn(with: credential, completion: { [weak self] (user, error) in
                    if let error = error as NSError? {
                        // TODO: handle this. will give an error for facebook email already exists as an email user
                        print("Login failed. \(String(describing: error))")
                        if error.code == 17012 {
                            self?.simpleAlert("Email already in use", message: "There is already an account with the email associated with your Facebook account. Please log in using the email option.")
                        }
                    } else {
                        print("LoginLogout: LoginSuccess from facebook, results: \(String(describing: user))")
                        // let observer handle things
                    }
                })
            }
        }
    }
}

extension LoginViewController: UITextFieldDelegate {
    @objc fileprivate func cancelInput() {
        shouldCancelInput = true
        view.endEditing(true)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        shouldCancelInput = false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard !shouldCancelInput else { return }
        if textField == inputEmail {
            inputPassword.becomeFirstResponder()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}


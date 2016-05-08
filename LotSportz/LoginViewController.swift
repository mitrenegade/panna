//
//  ViewController.swift
//  LotSportz
//
//  Created by Bobby Ren on 5/8/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import FBSDKLoginKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var inputEmail: UITextField!
    @IBOutlet weak var inputPassword: UITextField!
    @IBOutlet weak var buttonLogin: UIButton!
    @IBOutlet weak var buttonFacebook: UIButton!
    @IBOutlet weak var buttonSignup: UIButton!

    let facebookLogin = FBSDKLoginManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func didClickButton(button: UIButton) {
        if button == self.buttonFacebook {
            self.handleFacebookUser()
        }
        else if button == self.buttonSignup {
            self.performSegueWithIdentifier("GoToSignup", sender: button)
        }
        else if button == self.buttonLogin {
            self.loginUser()
        }
    }
    
    func loginUser() {
        let email = self.inputEmail.text!
        let password = self.inputPassword.text!
        
        if email.characters.count == 0 {
            print("Invalid email")
            return
        }
        
        if password.characters.count == 0 {
            print("Invalid password")
            return
        }
        
        firebaseRef.authUser(email, password: password) { (error, results) in
            if (error != nil) {
                print("Error: \(error)")
                self.simpleAlert("Could not log in", defaultMessage: nil,  error: error)
            }
            else {
                print("results: \(results)")
                self.notify("login:success", object: nil, userInfo: nil)
            }
        }
    }
    
    func handleFacebookUser() {
        let permissions = ["email"]
        facebookLogin.logInWithReadPermissions(permissions, fromViewController: self) { (result, error) in
            if error != nil {
                print("Facebook login failed. Error \(error)")
            } else if result.isCancelled {
                print("Facebook login was cancelled.")
            } else {
                let accessToken = FBSDKAccessToken.currentAccessToken().tokenString
                firebaseRef.authWithOAuthProvider("facebook", token: accessToken,
                                                  withCompletionBlock: { error, authData in
                                                    if error != nil {
                                                        print("Login failed. \(error)")
                                                    } else {
                                                        print("Logged in! \(authData)")
                                                    }
                })
            }
        }
    }
}


//
//  ViewController.swift
//  LotSportz
//
//  Created by Bobby Ren on 5/8/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import Firebase

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
        self.navigationController?.navigationBarHidden = true
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
        
        firAuth?.signInWithEmail(email, password: password, completion: { (user, error) in
            if (error != nil) {
                print("Error: \(error)")
                self.simpleAlert("Could not log in", defaultMessage: nil,  error: error)
            }
            else {
                print("results: \(user)")
                self.storeUserInfo(user!)
                
                self.notify("login:success", object: nil, userInfo: nil)
            }
        })
    }
    
    func handleFacebookUser() {
        let permissions = ["email", "public_profile", "user_about_me"]
        facebookLogin.logInWithReadPermissions(permissions, fromViewController: self) { (result, error) in
            if error != nil {
                print("Facebook login failed. Error \(error)")
            } else if result.isCancelled {
                print("Facebook login was cancelled.")
            } else {
                print("Facebook login success: \(result)")
                let accessToken = FBSDKAccessToken.currentAccessToken().tokenString
                
                let credential = FIRFacebookAuthProvider.credentialWithAccessToken(accessToken)
                firAuth!.signInWithCredential(credential, completion: { (user, error) in
                    if error != nil {
                        print("Login failed. \(error)")
                    } else {
                        print("Logged in! \(user)")
                        
                        // store user data
                        self.storeUserInfo(user!)
                        
                        self.notify("login:success", object: nil, userInfo: nil)
                    }
                })
            }
        }
    }
    
    func storeUserInfo(user: FIRUser) {
        /*
        var userInfo = [
            "uid": authData.uid,
            "provider": authData.provider,
        ]
        if let displayName = authData.providerData["displayName"] as? String {
            userInfo["displayName"] = displayName
        }
        if let email = authData.providerData["email"] as? String {
            userInfo["email"] = email
        }

        // Create a child path with a key set to the uid underneath the "users" node
        // This creates a URL path like the following:
        //  - https://<YOUR-FIREBASE-APP>.firebaseio.com/users/<uid>
        firebaseRef.childByAppendingPath("userInfo")
            .childByAppendingPath(authData.uid).setValue(userInfo)
         */
    }
}


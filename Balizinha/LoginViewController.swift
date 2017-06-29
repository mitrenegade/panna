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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.isNavigationBarHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func didClickButton(_ button: UIButton) {
        if button == self.buttonFacebook {
            self.handleFacebookUser()
        }
        else if button == self.buttonSignup {
            self.performSegue(withIdentifier: "GoToSignup", sender: button)
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
        
        firAuth.signIn(withEmail: email, password: password, completion: { (user, error) in
            if (error != nil) {
                print("Error: \(error)")
                self.simpleAlert("Could not log in", defaultMessage: nil,  error: error as? NSError)
            }
            else {
                print("results: \(user)")
                // do not store userInfo on login. should be created on signup.
                //self.storeUserInfo(user!)
                
                PlayerService.shared.current // invoke listener
                self.notify(NotificationType.LoginSuccess, object: nil, userInfo: nil)
            }
        })
    }
    
    func handleFacebookUser() {
        let permissions = ["email", "public_profile", "user_about_me"]
        FBSDKLoginManager().logOut() // in case user has switched accounts
        facebookLogin.logIn(withReadPermissions: permissions, from: self) { (result, error) in
            if error != nil {
                print("Facebook login failed. Error \(error)")
            } else if (result?.isCancelled)! {
                print("Facebook login was cancelled.")
            } else {
                print("Facebook login success: \(result)")
                let accessToken = FBSDKAccessToken.current().tokenString
                
                let credential = FacebookAuthProvider.credential(withAccessToken: accessToken!)
                firAuth.signIn(with: credential, completion: { (user, error) in
                    if error != nil {
                        print("Login failed. \(error)")
                    } else {
                        print("Logged in! \(user)")
                        
                        // store user data
                        self.storeUserInfo(user!)
                        self.notify(NotificationType.LoginSuccess, object: nil, userInfo: nil)
                    }
                })
            }
        }
    }
    
    func storeUserInfo(_ user: User) {
        print("signIn results: \(user) profile \(user.photoURL) \(user.displayName)")
        PlayerService.shared.createPlayer(name: user.displayName, email: user.email, city: nil, info: nil, photoUrl: user.photoURL?.absoluteString, completion: { (player, error) in
            PlayerService.shared.current // invoke listener
        })
    }
}


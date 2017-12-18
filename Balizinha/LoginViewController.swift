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
        
        firAuth.signIn(withEmail: email, password: password, completion: { [weak self] (user, error) in
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
                print("results: \(String(describing: user))")
                // do not store userInfo on login. should be created on signup.
                //self.storeUserInfo(user!)
                
                let _ = PlayerService.shared.current // invoke listener
                self?.notify(NotificationType.LoginSuccess, object: nil, userInfo: nil)
            }
        })
    }
    
    func handleFacebookUser() {
        let permissions = ["email", "public_profile", "user_about_me"]
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
                        print("Logged in! \(String(describing: user))")
                        guard let user = user else { return }
                        // store user data
                        self?.storeUserInfo(user)
                        self?.downloadFacebookPhoto(user)
                        self?.notify(NotificationType.LoginSuccess, object: nil, userInfo: nil)
                    }
                })
            }
        }
    }
    
    func storeUserInfo(_ user: User) {
        print("signIn results: \(user) profile \(String(describing: user.photoURL)) \(String(describing: user.displayName))")
        PlayerService.shared.createPlayer(name: user.displayName, email: user.email, city: nil, info: nil, photoUrl: user.photoURL?.absoluteString, completion: { (player, error) in
            let _ = PlayerService.shared.current // invoke listener
        })
    }
    
    fileprivate func downloadFacebookPhoto(_ user: User) {
        guard let photoUrl = user.photoURL else { return }
        guard let player = PlayerService.shared.current else { return }
        DispatchQueue.global().async {
            guard let data = try? Data(contentsOf: photoUrl) else { return }
            guard let image = UIImage(data: data) else { return }
            FirebaseImageService.uploadImage(image: image, type: "player", uid: user.uid, completion: { (url) in
                if let url = url {
                    player.photoUrl = url
                }
            })
        }
    }
}


//
//  SignupViewController.swift
// Balizinha
//
//  Created by Bobby Ren on 5/8/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit

class SignupViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var inputEmail: UITextField!
    @IBOutlet weak var inputPassword: UITextField!
    @IBOutlet weak var inputConfirmation: UITextField!
    @IBOutlet weak var buttonSignup: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didClickButton(_ button: UIButton) {
        if button == self.buttonSignup {
            self.createEmailUser()
        }
    }
    
    func createEmailUser() {
        let email = self.inputEmail.text!
        let password = self.inputPassword.text!
        let confirmation = self.inputConfirmation.text!
        
        if email.characters.count == 0 {
            print("Invalid email")
            return
        }
        
        if password.characters.count == 0 {
            print("Invalid password")
            return
        }
        
        if confirmation.characters.count == 0 {
            print("Password and confirmation do not match")
            return
        }
        
        firAuth?.createUser(withEmail: email, password: password, completion: { (user, error) in
            if (error != nil) {
                print("Error: \(error)")
                self.simpleAlert("Could not sign up", defaultMessage: nil, error: error as? NSError)
            }
            else {
                print("results: \(user)")
                self.loginUser()
            }
        })
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
        
        firAuth?.signIn(withEmail: email, password: password, completion: { (user, error) in
            if (error != nil) {
                print("Error: \(error)")
                self.simpleAlert("Could not log in", defaultMessage: nil, error: error as? NSError)
            }
            else {
                print("results: \(user)")
                self.notify("login:success", object: nil, userInfo: nil)
            }
        })
    }
}

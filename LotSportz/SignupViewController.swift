//
//  SignupViewController.swift
//  LotSportz
//
//  Created by Bobby Ren on 5/8/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Firebase

class SignupViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var inputEmail: UITextField!
    @IBOutlet weak var inputPassword: UITextField!
    @IBOutlet weak var inputConfirmation: UITextField!
    @IBOutlet weak var buttonFacebook: UIButton!
    @IBOutlet weak var buttonSignup: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didClickButton(button: UIButton) {
        if button == self.buttonFacebook {
            
        }
        else if button == self.buttonSignup {
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
        
        firebaseRef.createUser(email, password: password) { (error, results) in
            if (error != nil) {
                print("Error: \(error)")
            }
            else {
                print("results: \(results)")
            }
        }
    }
}

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
    
    var newPlayer: Player?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.isNavigationBarHidden = false
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
                print("createUser results: \(user)")
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
                print("signIn results: \(user) profile \(user?.photoURL) \(user?.displayName)")
                PlayerService.shared.createPlayer(name: nil, email: email, city: nil, info: nil, photoUrl: nil, completion: { (player, error) in
                    if let error = error {
                        self.simpleAlert("Could not sign up", defaultMessage: nil, error: error as? NSError)
                    }
                    else {
                        self.newPlayer = player
                        self.performSegue(withIdentifier: "ToEditPlayer", sender: nil)
                    }
                })
            }
        })
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ToEditPlayer" {
            if let controller = segue.destination as? PlayerInfoViewController {
                controller.player = self.newPlayer
                controller.isCreatingPlayer = true
            }
        }
    }
}

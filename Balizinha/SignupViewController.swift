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
        guard let email = self.inputEmail.text, !email.isEmpty else {
            self.simpleAlert("Please enter your email", message: nil)
            return
        }
        guard let password = self.inputPassword.text, !password.isEmpty else {
            self.simpleAlert("Please enter your password", message: nil)
            return
        }
        guard let confirmation = self.inputConfirmation.text, confirmation == password else {
            self.simpleAlert("Password and confirmation must match", message: nil)
            return
        }
        
        firAuth.createUser(withEmail: email, password: password, completion: { (user, error) in
            if let error = error as? NSError {
                print("Error: \(error)")
                self.simpleAlert("Could not sign up", defaultMessage: nil, error: error)
            }
            else {
                print("createUser results: \(user)")
                self.loginUser()
            }
        })
    }
        
    func loginUser() {
        guard let email = self.inputEmail.text, !email.isEmpty else {
            self.simpleAlert("Please enter your email", message: nil)
            return
        }
        guard let password = self.inputPassword.text, !password.isEmpty else {
            self.simpleAlert("Please enter your password", message: nil)
            return
        }
        
        firAuth.signIn(withEmail: email, password: password, completion: { (user, error) in
            if let error = error as? NSError {
                print("Error: \(error)")
                self.simpleAlert("Could not log in", defaultMessage: nil, error: error)
            }
            else {
                print("signIn results: \(user) profile \(user?.photoURL) \(user?.displayName)")
                PlayerService.shared.createPlayer(name: nil, email: email, city: nil, info: nil, photoUrl: nil, completion: { (player, error) in
                    PlayerService.shared.current // invoke listener
                    if let player = player {
                        self.goToEditPlayer(player)
                    }
                    else {
                        self.simpleAlert("Could not sign up", defaultMessage: "There was an error creating your player profile.", error: error)
                    }
                })
            }
        })
    }

    func goToEditPlayer(_ player: Player?) {
        if let controller = UIStoryboard.init(name: "Account", bundle: nil).instantiateViewController(withIdentifier: "PlayerInfoViewController") as? PlayerInfoViewController {
            controller.player = player
            controller.isCreatingPlayer = true
            
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
}

//
//  AuthService.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 2/3/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

import UIKit
import FirebaseAuth
import RxSwift
import FBSDKLoginKit

enum LoginState {
    case loggedOut
    case loggedIn
}

class AuthService: NSObject {
    static var shared: AuthService = AuthService()
    
    class func startup() {
        if UserDefaults.standard.value(forKey: "appFirstTimeOpened") == nil {
            //if app is first time opened, make sure no auth exists in keychain from previously deleted app
            UserDefaults.standard.setValue(true, forKey: "appFirstTimeOpened")
            // signOut from FIRAuth
            try! firAuth.signOut()
        }
    }

    var loginState: Observable<LoginState> = Observable.create { (observer) -> Disposable in
        print("LoginLogout: start listening for user")
        firAuth.addStateDidChangeListener({ (auth, user) in
            print("LoginLogout: auth state changed: \(auth)")
            if let user = user, !user.isAnonymous {
                // already logged in, don't do anything
                print("FirAuth: user logged in")
                observer.onNext(.loggedIn)
            }
            else {
                print("Need to display login")
                observer.onNext(.loggedOut)
            }
        })
        return Disposables.create()
    }

    func loginUser(email: String, password: String, completion: ((Error?)->Void)?) {
        firAuth.signIn(withEmail: email, password: password, completion: { (user, error) in
            if let error: NSError = error as NSError? {
                print("Error: \(error)")
                // let observer handle things
                completion?(error)
            }
            else {
                print("LoginLogout: LoginSuccess from email, results: \(String(describing: user))")
                // let observer handle things
                completion?(nil)
            }
        })
    }
    
    func logout() {
        print("LoginLogout: logout called, trying firAuth.signout")
        try! firAuth.signOut()
        EventService.resetOnLogout() // force new listeners
        PlayerService.resetOnLogout()
        OrganizerService.resetOnLogout()
        FBSDKLoginManager().logOut()
    }
}

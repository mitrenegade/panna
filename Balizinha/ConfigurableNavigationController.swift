//
//  ConfigurableNavigationController.swift
//  BondVoyage
//
//  Created by Bobby Ren on 11/21/16.
//  Copyright © 2016 RenderApps. All rights reserved.
//

import UIKit

class ConfigurableNavigationController: UINavigationController {

    var rootStoryboardName: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.loadDefaultRootViewController()
    }
    
    func loadDefaultRootViewController() {
        // Do any additional setup after loading the view.
        if let storyboardName = rootStoryboardName {
            let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
            if let controller = storyboard.instantiateInitialViewController() {
                self.setViewControllers([controller], animated: false)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

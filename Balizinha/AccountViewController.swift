//
//  AccountViewController.swift
//  Balizinha
//
//  Created by Tom Strissel on 5/19/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit

class AccountViewController: UITableViewController {
    
    let menuOptions = ["Edit profile", "Push Notifications", "Logout"]
    var service = EventService.sharedInstance()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Account"

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuOptions.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        switch indexPath.row {
        case 1:
            let cell : PushTableViewCell = tableView.dequeueReusableCell(withIdentifier: "push", for: indexPath) as! PushTableViewCell
            cell.labelPush.text = menuOptions[indexPath.row]
            cell.selectionStyle = .none
            cell.refresh()
            return cell
            
        case 0, 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.textLabel?.text = menuOptions[indexPath.row]
            return cell
            
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
       
        switch indexPath.row {
        case 0:
            self.performSegue(withIdentifier: "ToEditPlayerInfo", sender: nil)
        case 1:
            break
        case 2:
            try! firAuth?.signOut()
            self.notify(.LogoutSuccess, object: nil, userInfo: nil)
        default:
            break
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ToEditPlayerInfo" {
            if let nav = segue.destination as? UINavigationController, let controller = nav.viewControllers[0] as? PlayerInfoViewController {
                controller.player = PlayerService.shared.current
                controller.isCreatingPlayer = false
            }
        }
    }
}

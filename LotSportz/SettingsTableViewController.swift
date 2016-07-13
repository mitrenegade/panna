//
//  SettingsTableViewController.swift
//  LotSportz
//
//  Created by Tom Strissel on 5/19/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import SWRevealViewController

class SettingsTableViewController: UITableViewController {
    
    let menuOptions = ["Push Notifications", "Logout"]
    var service = EventService.sharedInstance()

    @IBOutlet var menuButton: UIBarButtonItem!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
        }
        
        self.navigationItem.title = "Settings"

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuOptions.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        switch indexPath.row {
        case 0:
            let cell : PushTableViewCell = tableView.dequeueReusableCellWithIdentifier("push", forIndexPath: indexPath) as! PushTableViewCell
            cell.labelPush.text = menuOptions[indexPath.row]
            cell.selectionStyle = .None
            cell.refresh()
            return cell
            
        case 1:
            let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
            cell.textLabel?.text = menuOptions[indexPath.row]
            return cell
            
        default:
            let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
       
        switch indexPath.row {
        case 0:
            self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
            break
        case 1:
            try! firAuth?.signOut()
            self.notify("logout:success", object: nil, userInfo: nil)
        default:
            break
        }
    }
}

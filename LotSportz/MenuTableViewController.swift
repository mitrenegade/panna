//
//  MenuTableViewController.swift
//  LotSportz
//
//  Created by Tom Strissel on 5/17/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit

class MenuTableViewController: UITableViewController {
    
    var MENU_LIST : [String] = ["My Events","Join events", "Create event", "Settings"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation helpers
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "toCreateEvent" {
            // add a reference to menuTableViewController to navigate back
            let nav: UINavigationController = segue.destinationViewController as! UINavigationController
            let controller: CreateEventViewController = nav.viewControllers[0] as! CreateEventViewController
            controller.menuController = self
        }
    }
    
    func goToMyEvents() {
        self.performSegueWithIdentifier("toMyEvents", sender: self)
    }

    func goToJoinEvents() {
        self.performSegueWithIdentifier("toJoinEvents", sender: self)
    }

    func goToCreateEvent() {
        self.performSegueWithIdentifier("toCreateEvent", sender: self)
    }

    func goToSettings() {
        self.performSegueWithIdentifier("toSettings", sender: self)
    }

    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func viewWillAppear(animated: Bool) {
        self.tableView.reloadData()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section{
        case 0:
            return 1
        case 1:
            return MENU_LIST.count
        default:
            break
        }
        return 0 //Never reached
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // Configure the cell...
        let row = indexPath.row
        let section = indexPath.section
        
        switch section
        {
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier("option", forIndexPath: indexPath)
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            
            let logo : UIImageView = UIImageView(image: UIImage(named: "lotsports_logo_white"))
            logo.frame = CGRectMake(cell.contentView.bounds.size.width/5.5, cell.contentView.bounds.size.height/4, 150, 70)
            
            cell.addSubview(logo)
            return cell
        case 1:
            let cell = tableView.dequeueReusableCellWithIdentifier("option", forIndexPath: indexPath)
            cell.textLabel?.textColor = UIColor.whiteColor()
            switch row
            {
            case 0...4: //My Events
                cell.textLabel?.text = MENU_LIST[row]
                return cell
            default:
                break
            }
        default:
            break
        }
        let cell = tableView.dequeueReusableCellWithIdentifier("option", forIndexPath: indexPath)
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // Configure the cell...
        let row = indexPath.row
        let section = indexPath.section
        
        switch section
        {
        case 0:
            break
        //TODO: segue to home
        case 1:
            switch row
            {
            case 0: //My Events
                self.performSegueWithIdentifier("toMyEvents", sender: self)
            case 1:
                self.performSegueWithIdentifier("toJoinEvents", sender: self)
            case 2:
                self.performSegueWithIdentifier("toCreateEvent", sender: self)
            case 3:
                self.performSegueWithIdentifier("toSettings", sender: self)
            default:
                break
            }
        default:
            break
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 150.0
        default:
            return 60.0
        }
    }
    
    
}

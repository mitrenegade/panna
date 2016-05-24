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

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
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
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)

        // Configure the cell...
        let row = indexPath.row
        let section = indexPath.section
        
        switch section
        {
        case 0:
            break
            //TODO: segue to home
            cell.textLabel?.text = "Home Logo"
        case 1:
            switch row
            {
            case 0...4: //My Events
                cell.textLabel?.text = MENU_LIST[row]
            default:
                break
            }
        default:
            break
        }
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
            case 1: //Join Events
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
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

//
//  CreateEventTableViewController.swift
//  LotSportz
//
//  Created by Tom Strissel on 5/19/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import SWRevealViewController

class CreateEventViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    
    let options = ["Sport Type", "City", "Location", "Day", "Start Time", "End Time", "Max Players"]
    var sportTypes = ["Soccer", "Basketball", "Flag Football"]
    let maxPlayers = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
    var pickerData = []

    @IBOutlet var pickerView: UIPickerView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var menuButton: UIBarButtonItem!
    @IBOutlet var saveButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
        }
        
        self.navigationItem.title = "Create Event"
        pickerView = UIPickerView(frame: CGRectMake(0, 200, view.frame.width, 300))
        pickerView.backgroundColor = .whiteColor()
        
        pickerView.showsSelectionIndicator = true
        pickerView.delegate = self
        pickerView.dataSource = self
        tableView.delegate = self
        tableView.dataSource = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didClickSave(sender: AnyObject) {
        // create a generic event
        let displayName = firAuth?.currentUser!.email
        let info = "created by \(displayName!)"
        EventService.sharedInstance().createEvent("Basketball", place: "Braden Field", time: NSDate(), max_players: 10, info: info)
        //To-Do: Add Start/End times for createEvent call
    }

    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 2
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return options.count
        case 1:
            return 1
        default:
            return 0
        }
    }

    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        print("Reloaded rows of table")
        switch indexPath.section {
        case 0:
            let cell : DetailCell = tableView.dequeueReusableCellWithIdentifier("detailCell", forIndexPath: indexPath) as! DetailCell
            
            cell.labelAttribute.text = options[indexPath.row]
            cell.labelValue.text = ""
            
            return cell

        case 1:
            let cell : DescriptionCell = tableView.dequeueReusableCellWithIdentifier("descriptionCell", forIndexPath: indexPath) as! DescriptionCell

            return cell
        default:
            let cell = tableView.dequeueReusableCellWithIdentifier("detailCell", forIndexPath: indexPath)
            return cell
            
        }

    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        switch section {
        case 0:
            return "Details"
        case 1:
            return  "Description"
        default:
            return "Noice"
        }
    }
    
    /* - CUSTOM HEADER VIEW IMPLEMENTATION (WIP)
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRectMake(0, 0, tableView.bounds.size.width, 30))
        headerView.backgroundColor = UIColor(red: 183.0/255.0, green: 238.0/255.0, blue: 213.0/255.0, alpha: 1.0)
        let label = UILabel(frame: CGRectMake(10, 5, tableView.bounds.size.width, 20))
        label.font = UIFont.boldSystemFontOfSize(12)
        
        switch section {
        case 0:
            label.text = "Details"
        case 1:
            label.text =  "Description"
        default:
            label.text = "Noice"
        }
        
        headerView.addSubview(label)
        
        return headerView
    }
    */
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        switch indexPath.section {
        case 1:
            return 160.0
        default:
            return 44.0
        }
    
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                print("Tapped sport types")
                //Display sport types
                pickerData = sportTypes
                pickerView.hidden = false
                pickerView.reloadAllComponents()
                view.bringSubviewToFront(pickerView)
    
            default:
                break
            }
        }
    }

    //MARK: - Delegates and data sources
    //MARK: Data Sources
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        print("Reloaded number of rows")
        return pickerData.count
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        print("Reloaded components")
        return pickerData[row] as? String
    }

}

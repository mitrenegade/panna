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
    var sportTypes = ["Select Type", "Soccer", "Basketball", "Flag Football"]
    let maxPlayers = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20"]
    
    var currentCell : DetailCell!
    var pickerData = []
    var pickingStartTime : Bool!
    
    var type : String!
    var city : String!
    var location : String!
    var date : NSDate!
    var startTime : String!
    var endTime : String!
    var numPlayers : Int!
    var info : String!
    
    @IBOutlet var pickerView: UIPickerView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var menuButton: UIBarButtonItem!
    @IBOutlet var saveButton: UIBarButtonItem!
    @IBOutlet var datePickerView: UIDatePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
        }
        
        self.navigationItem.title = "Create Event"
        pickerView = UIPickerView(frame: CGRectMake(0, 200, view.frame.width, 300))
        pickerView.backgroundColor = .whiteColor()
        
        datePickerView = UIDatePicker(frame: CGRectMake(0, 200, view.frame.width, 300))
        datePickerView.backgroundColor = .whiteColor()

        // pickerView.showsSelectionIndicator = true
        pickerView.delegate = self
        pickerView.dataSource = self
        tableView.delegate = self
        tableView.dataSource = self
        pickingStartTime = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func didClickSave(sender: AnyObject) {
        // create a generic event
        let displayName = firAuth?.currentUser!.email //what is the purpose of this?
        
        //get city
        
        let cityCell : DetailCell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0)) as! DetailCell
        self.city = cityCell.valueTextField.text
        let descriptionCell : DescriptionCell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 1)) as! DescriptionCell
        self.info = descriptionCell.DescriptionTextView.text
        
        
        
        
        /* !!!EVENT SERVICE: Create event call should include parameters in commented call below !!! */
        EventService.sharedInstance().createEvent(self.type, place: "Braden Field", time: NSDate(), max_players: 10, info: info)
        //EventService.sharedInstance().createEvent(self.type, city: self.city, place: self.location, time: self.date, startTime: self.startTime, endTime: self.endTime, max_players: self.numPlayers, info: self.info)
        
        let storyboard = UIStoryboard(name: "Menu", bundle: nil)
        let controller = storyboard.instantiateViewControllerWithIdentifier("MyEventsTableViewController") as UIViewController

        
        self.revealViewController().pushFrontViewController(controller, animated: true)
       
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
            cell.valueTextField.userInteractionEnabled = false;

            switch indexPath.row {
            case 0,6:
                cell.valueTextField.inputView = self.pickerView
            case 1,2:
                break
            case 3...5:
                cell.valueTextField.inputView = self.datePickerView

            default:
                break
            }
           
            
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
        print("Tapped Cell")
        if indexPath.section == 0 {
            if currentCell != nil{
                currentCell.valueTextField.resignFirstResponder()
            }

            let cell = tableView.cellForRowAtIndexPath(indexPath) as! DetailCell
            cell.valueTextField.userInteractionEnabled = true
            switch indexPath.row {
            case 0:
                print("Tapped sport types")
                pickerData = sportTypes
                pickerView.reloadAllComponents()
            case 3:
                self.datePickerView.datePickerMode = UIDatePickerMode.Date
                
                datePickerView.addTarget(self, action: #selector(datePickerValueChanged), forControlEvents: UIControlEvents.ValueChanged)
                
            case 4:
                self.datePickerView.datePickerMode = UIDatePickerMode.Time
                datePickerView.addTarget(self, action: #selector(timePickerValueChanged), forControlEvents: UIControlEvents.ValueChanged)
                pickingStartTime = true
            case 5:
                self.datePickerView.datePickerMode = UIDatePickerMode.Time
                datePickerView.addTarget(self, action: #selector(timePickerValueChanged), forControlEvents: UIControlEvents.ValueChanged)
                pickingStartTime = false
            case 6:
                print("Tapped number of players")
                pickerData = maxPlayers
                pickerView.reloadAllComponents()
            default:
                break
            }
            
            currentCell = cell
            cell.valueTextField.becomeFirstResponder()

           
        }
    }
    
    
    
    func updateLabel(){
        currentCell.valueTextField.placeholder = pickerData[pickerView.selectedRowInComponent(0)] as? String
        if (pickerData == sportTypes) { //selected a sport type
            self.type = pickerData[pickerView.selectedRowInComponent(0)] as? String
        } else if (pickerData == maxPlayers) { //selected max players
            self.numPlayers = pickerData[pickerView.selectedRowInComponent(0)] as? Int
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
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if row > 0 {
            updateLabel()
            //self.pickerView.hidden = true
            currentCell.valueTextField.userInteractionEnabled = false
            currentCell.resignFirstResponder()
            pickerData = []
        }
        
    }
    
    func datePickerValueChanged(sender:UIDatePicker) {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.NoStyle
        currentCell.valueTextField.placeholder = dateFormatter.stringFromDate(sender.date)
        
        date = sender.date
    }
    
    func timePickerValueChanged(sender:UIDatePicker) {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.NoStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
        currentCell.valueTextField.placeholder = dateFormatter.stringFromDate(sender.date)
        if (pickingStartTime != nil) {
            self.startTime = dateFormatter.stringFromDate(sender.date)
        } else {
            self.endTime = dateFormatter.stringFromDate(sender.date)
        }
        
    }

}

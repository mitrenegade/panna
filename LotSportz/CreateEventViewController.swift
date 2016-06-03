//
//  CreateEventTableViewController.swift
//  LotSportz
//
//  Created by Tom Strissel on 5/19/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import SWRevealViewController

class CreateEventViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate, SWRevealViewControllerDelegate, UITextFieldDelegate {
    
    let options = ["Sport Type", "Location", "City", "Day", "Start Time", "End Time", "Max Players"]
    var sportTypes = ["Select Type", "Soccer", "Basketball", "Flag Football"]
    let maxPlayers = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
    
    var currentCell : DetailCell!
    var pickerData = []
    var pickingStartTime : Bool!
    
    var type : String!
    var city : String!
    var location : String!
    var date : NSDate!
    var startTimeString : String!
    var endTimeString : String!
    var startTime: NSDate!
    var endTime: NSDate!
    var numPlayers : UInt!
    var info : String!
   
    var cityField: UITextField?
    var locationField: UITextField?
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var menuButton: UIBarButtonItem!
    @IBOutlet var saveButton: UIBarButtonItem!
    var datePickerView: UIDatePicker!
    var pickerView: UIPickerView!

    var menuController: MenuTableViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Create Event"
        pickerView = UIPickerView(frame: CGRectMake(0, 200, view.frame.width, 300))
        pickerView.backgroundColor = .whiteColor()
        
        datePickerView = UIDatePicker(frame: CGRectMake(0, 200, view.frame.width, 300))
        datePickerView.backgroundColor = .whiteColor()
        datePickerView.minimumDate = NSDate()
        
        // pickerView.showsSelectionIndicator = true
        pickerView.delegate = self
        pickerView.dataSource = self
        pickingStartTime = false

        if self.revealViewController() != nil {
            self.revealViewController().delegate = self
            
        }
    
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didClickMenu(sender: AnyObject) {
        if self.revealViewController() != nil {
            self.revealViewController().revealToggle(self)
        }
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
        if type != nil && city != nil && location != nil && date != nil && startTime != nil && endTime != nil && numPlayers != nil && info != nil  {
            EventService.sharedInstance().createEvent(self.type, city: self.city, place: self.location, startTime: self.startTime, endTime: self.endTime, max_players: self.numPlayers, info: self.info)
            
            // TODO: create some sort of activity indicator
            self.revealViewController().revealToggle(nil)
            self.menuController!.goToMyEvents()

        } else {
            let alert = UIAlertController(title: "Alert", message: "Pleae enter all required fields.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
            
            self.presentViewController(alert, animated: true, completion: nil)
        }
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
            let cell : DetailCell
            if indexPath.row == 1 || indexPath.row == 2 {
                cell = tableView.dequeueReusableCellWithIdentifier("cityCell", forIndexPath: indexPath) as! DetailCell
                
                if indexPath.row == 2 {
                    cell.valueTextField.placeholder = "Boston"
                    self.cityField = cell.valueTextField
                } else{
                    cell.valueTextField.placeholder = "Braden Field"
                    self.locationField = cell.valueTextField
                }
                cell.valueTextField.delegate = self
            }
            else {
                cell = tableView.dequeueReusableCellWithIdentifier("detailCell", forIndexPath: indexPath) as! DetailCell
                
                switch indexPath.row {
                case 0,6:
                    cell.valueTextField.inputView = self.pickerView
                case 1,2:
                    cell.valueTextField.inputView = nil
                    break
                case 3...5:
                    cell.valueTextField.inputView = self.datePickerView
                    
                default:
                    break
                }
                
                cell.valueTextField.userInteractionEnabled = false;
            }
            cell.labelAttribute.text = options[indexPath.row]

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
                pickerData = maxPlayers.map
                {
                        String($0)
                }
                pickerView.reloadAllComponents()
            default:
                break
            }
            
            currentCell = cell
            cell.valueTextField.becomeFirstResponder()
        }
    }
    
    func updateLabel(){
        currentCell.valueTextField.text = pickerData[pickerView.selectedRowInComponent(0)] as? String
        if (pickerData == sportTypes) { //selected a sport type
            self.type = pickerData[pickerView.selectedRowInComponent(0)] as? String
        } else if (pickerData == maxPlayers) { //selected max players
            self.numPlayers = pickerData[pickerView.selectedRowInComponent(0)] as? UInt
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
        currentCell.valueTextField.text = dateFormatter.stringFromDate(sender.date)
        
        date = sender.date
    }
    
    func timePickerValueChanged(sender:UIDatePicker) {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.NoStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
        currentCell.valueTextField.text = dateFormatter.stringFromDate(sender.date)
        if (pickingStartTime != nil) {
            self.startTime = sender.date
            self.startTimeString = dateFormatter.stringFromDate(sender.date)
        } else {
            self.endTime = sender.date
            self.endTimeString = dateFormatter.stringFromDate(sender.date)
        }
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldDidEndEditing(textField: UITextField) {
        if textField == self.cityField {
            self.city = textField.text
        }
        else if textField == self.locationField {
            self.location = textField.text
        }
    }

}

//
//  CreateEventTableViewController.swift
//  LotSportz
//
//  Created by Tom Strissel on 5/19/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import SWRevealViewController

class CreateEventViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate, SWRevealViewControllerDelegate, UITextFieldDelegate, UITextViewDelegate {
    
    let options = ["Sport Type", "Location", "City", "Day", "Start Time", "End Time", "Max Players"]
    var sportTypes = ["Select Type", "Soccer", "Basketball", "Flag Football"]
    let maxPlayers = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
    
    var currentField : UITextField?
    var currentTextView : UITextView?
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
   
    var typeField: UITextField?
    var cityField: UITextField?
    var locationField: UITextField?
    var dayField: UITextField?
    var startField: UITextField?
    var endField: UITextField?
    var maxPlayersField: UITextField?
    var descriptionTextView : UITextView?
    var keyboardDoneButtonView: UIToolbar!
    var keyboardHeight : CGFloat!
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var menuButton: UIBarButtonItem!
    @IBOutlet var saveButton: UIBarButtonItem!
    var datePickerView: UIDatePicker!
    var pickerView: UIPickerView!

    var menuController: MenuTableViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Create Event"
        pickerView = UIPickerView()
        pickerView.sizeToFit()
        pickerView.backgroundColor = .whiteColor()
        
        datePickerView = UIDatePicker()
        datePickerView.sizeToFit()
        datePickerView.backgroundColor = .whiteColor()
        datePickerView.minimumDate = NSDate()
        
        // pickerView.showsSelectionIndicator = true
        pickerView.delegate = self
        pickerView.dataSource = self
        pickingStartTime = false

        if self.revealViewController() != nil {
            self.revealViewController().delegate = self
        }

        self.keyboardDoneButtonView = UIToolbar()
        keyboardDoneButtonView.sizeToFit()
        keyboardDoneButtonView.barStyle = UIBarStyle.Default
        keyboardDoneButtonView.tintColor = UIColor.whiteColor()
        let save: UIBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Done, target: self.view, action: #selector(UIView.endEditing(_:)))
        save.tintColor = self.view.tintColor
        
        let flex: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        
        keyboardDoneButtonView.setItems([flex, save], animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
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
        self.city = self.cityField!.text
        self.info = self.descriptionTextView!.text
        
        print(info)
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
                
                cell.valueTextField.userInteractionEnabled = false;
                
                switch indexPath.row {
                case 0:
                    self.typeField = cell.valueTextField
                    self.typeField?.inputView = self.pickerView
                case 3:
                    self.dayField = cell.valueTextField
                    self.dayField?.inputView = self.datePickerView
                case 4:
                    self.startField = cell.valueTextField
                    self.startField?.inputView = self.datePickerView
                case 5:
                    self.endField = cell.valueTextField
                    self.endField?.inputView = self.datePickerView
                case 6:
                    self.maxPlayersField = cell.valueTextField
                    self.maxPlayersField?.inputView = self.pickerView
                default:
                    break
                }

            }
            cell.labelAttribute.text = options[indexPath.row]
            cell.valueTextField.inputAccessoryView = self.keyboardDoneButtonView

            return cell

        case 1:
            let cell : DescriptionCell = tableView.dequeueReusableCellWithIdentifier("descriptionCell", forIndexPath: indexPath) as! DescriptionCell
            self.descriptionTextView = cell.descriptionTextView
            cell.descriptionTextView.delegate = self
            
            cell.descriptionTextView.inputAccessoryView = self.keyboardDoneButtonView

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
        print("Tapped Cell \(indexPath)")
        switch indexPath.section {
        case 0:
            if currentField != nil{
                currentField!.resignFirstResponder()
            }
            
            var textField: UITextField!
            switch indexPath.row {
            case 0:
                print("Tapped sport types")
                textField = self.typeField!
                pickerData = sportTypes
                pickerView.reloadAllComponents()
            case 1:
                textField = self.locationField!
            case 2:
                textField = self.cityField!
            case 3:
                textField = self.dayField!
                self.datePickerView.datePickerMode = UIDatePickerMode.Date
                
                datePickerView.addTarget(self, action: #selector(datePickerValueChanged), forControlEvents: UIControlEvents.ValueChanged)
                
            case 4:
                textField = self.startField!
                self.datePickerView.datePickerMode = UIDatePickerMode.Time
                datePickerView.addTarget(self, action: #selector(timePickerValueChanged), forControlEvents: UIControlEvents.ValueChanged)
                pickingStartTime = true
            case 5:
                textField = self.endField!
                self.datePickerView.datePickerMode = UIDatePickerMode.Time
                datePickerView.addTarget(self, action: #selector(timePickerValueChanged), forControlEvents: UIControlEvents.ValueChanged)
                pickingStartTime = false
            case 6:
                textField = self.maxPlayersField!
                print("Tapped number of players")
                pickerData = maxPlayers.map
                    {
                        String($0)
                }
                pickerView.reloadAllComponents()
            default:
                break
            }
            currentField = textField
            textField.userInteractionEnabled = true
            textField.becomeFirstResponder()
        
        case 1:
            
            break
        default:
            break
        }
        
    }
    
    func updateLabel(){
        currentField!.text = pickerData[pickerView.selectedRowInComponent(0)] as? String
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
            currentField!.userInteractionEnabled = false
            currentField!.resignFirstResponder()
            pickerData = []
        }
        
    }
    
    func datePickerValueChanged(sender:UIDatePicker) {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.NoStyle
        currentField!.text = dateFormatter.stringFromDate(sender.date)
        
        date = sender.date
    }
    
    func timePickerValueChanged(sender:UIDatePicker) {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.NoStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
        currentField!.text = dateFormatter.stringFromDate(sender.date)
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
    
    // MARK: -UITextViewDelegate
    func textViewDidBeginEditing(textView: UITextView) {
       self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: self.keyboardHeight, right: 0)
        
        let indexPath = NSIndexPath(forRow: 0, inSection: 1)
        self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        self.tableView.contentInset = UIEdgeInsetsZero
        
    }
    
    // MARK - Keyboard
    func keyboardWillShow(notification: NSNotification) {
        let userInfo:NSDictionary = notification.userInfo!
        let keyboardFrame:NSValue = userInfo.valueForKey(UIKeyboardFrameEndUserInfoKey) as! NSValue
        let keyboardRectangle = keyboardFrame.CGRectValue()
        let keyboardHeight = keyboardRectangle.height
        
        self.keyboardHeight = keyboardHeight
    }

}

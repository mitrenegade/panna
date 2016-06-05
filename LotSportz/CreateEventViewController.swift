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
    
    var type : String!
    var city : String!
    var location : String!
    var date : NSDate!
    var dateString: String!
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
    var keyboardDoneButtonView2: UIToolbar!
    var keyboardHeight : CGFloat!
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var menuButton: UIBarButtonItem!
    @IBOutlet var saveButton: UIBarButtonItem!
    var datePickerView: UIDatePicker = UIDatePicker()
    var startTimePickerView: UIDatePicker = UIDatePicker()
    var endTimePickerView: UIDatePicker = UIDatePicker()
    var pickerView: UIPickerView = UIPickerView()

    var menuController: MenuTableViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Create Event"
        
        self.setupPickers()

        if self.revealViewController() != nil {
            self.revealViewController().delegate = self
        }

        // textfield keyboard
        self.keyboardDoneButtonView = UIToolbar()
        keyboardDoneButtonView.sizeToFit()
        keyboardDoneButtonView.barStyle = UIBarStyle.Default
        keyboardDoneButtonView.tintColor = UIColor.whiteColor()
        let save: UIBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Done, target: self, action: #selector(CreateEventViewController.done))
        save.tintColor = self.view.tintColor
        
        let flex: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        
        keyboardDoneButtonView.setItems([flex, save], animated: true)

        // textview keyboard
        self.keyboardDoneButtonView2 = UIToolbar()
        keyboardDoneButtonView2.sizeToFit()
        keyboardDoneButtonView2.barStyle = UIBarStyle.Default
        keyboardDoneButtonView2.tintColor = UIColor.whiteColor()
        let save2: UIBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Done, target: self.view, action: #selector(UIView.endEditing(_:)))
        save2.tintColor = self.view.tintColor
        keyboardDoneButtonView2.setItems([flex, save2], animated: true)
    
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
    
    func setupPickers() {
        
        pickerView.sizeToFit()
        pickerView.backgroundColor = .whiteColor()
        pickerView.delegate = self
        pickerView.dataSource = self
        
        for picker in [startTimePickerView, endTimePickerView, datePickerView] {
            picker.sizeToFit()
            picker.backgroundColor = .whiteColor()
            picker.minimumDate = NSDate()
        }
        
        self.datePickerView.datePickerMode = UIDatePickerMode.Date
        self.datePickerView.addTarget(self, action: #selector(datePickerValueChanged), forControlEvents: UIControlEvents.ValueChanged)
        
        self.startTimePickerView.datePickerMode = UIDatePickerMode.Time
        self.startTimePickerView.addTarget(self, action: #selector(timePickerValueChanged), forControlEvents: UIControlEvents.ValueChanged)
        
        self.endTimePickerView.datePickerMode = UIDatePickerMode.Time
        self.endTimePickerView.addTarget(self, action: #selector(timePickerValueChanged), forControlEvents: UIControlEvents.ValueChanged)
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
                cell.valueTextField.delegate = self
                cell.valueTextField.inputAccessoryView = nil
                
                if indexPath.row == 2 {
                    cell.valueTextField.placeholder = "Boston"
                    self.cityField = cell.valueTextField
                } else{
                    cell.valueTextField.placeholder = "Braden Field"
                    self.locationField = cell.valueTextField
                }
            }
            else {
                cell = tableView.dequeueReusableCellWithIdentifier("detailCell", forIndexPath: indexPath) as! DetailCell
                
                cell.valueTextField.userInteractionEnabled = false;
                cell.valueTextField.delegate = self
                
                switch indexPath.row {
                case 0:
                    self.typeField = cell.valueTextField
                    self.typeField?.inputView = self.pickerView
                    cell.valueTextField.inputAccessoryView = nil
                case 3:
                    self.dayField = cell.valueTextField
                    self.dayField?.inputView = self.datePickerView
                    cell.valueTextField.inputAccessoryView = self.keyboardDoneButtonView
                case 4:
                    self.startField = cell.valueTextField
                    self.startField?.inputView = self.startTimePickerView
                    cell.valueTextField.inputAccessoryView = self.keyboardDoneButtonView
                case 5:
                    self.endField = cell.valueTextField
                    self.endField?.inputView = self.endTimePickerView
                    cell.valueTextField.inputAccessoryView = self.keyboardDoneButtonView
                case 6:
                    self.maxPlayersField = cell.valueTextField
                    self.maxPlayersField?.inputView = self.pickerView
                    cell.valueTextField.inputAccessoryView = nil
                default:
                    break
                }

            }
            cell.labelAttribute.text = options[indexPath.row]

            return cell

        case 1:
            let cell : DescriptionCell = tableView.dequeueReusableCellWithIdentifier("descriptionCell", forIndexPath: indexPath) as! DescriptionCell
            self.descriptionTextView = cell.descriptionTextView
            cell.descriptionTextView.delegate = self
            
            cell.descriptionTextView.inputAccessoryView = self.keyboardDoneButtonView2

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
            case 4:
                textField = self.startField!
            case 5:
                textField = self.endField!
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
    
    func done() {
        // on button click on toolbar for day, time pickers
        self.currentField?.resignFirstResponder()
        self.updateLabel()
    }
    
    func updateLabel(){
        if currentField == self.typeField || currentField == self.maxPlayersField {
            currentField!.text = pickerData[pickerView.selectedRowInComponent(0)] as? String
            if (pickerData == sportTypes) { //selected a sport type
                self.type = pickerData[pickerView.selectedRowInComponent(0)] as? String
            } else if (pickerData == maxPlayers) { //selected max players
                self.numPlayers = pickerData[pickerView.selectedRowInComponent(0)] as? UInt
            }
        }
        // comes from clicking on done button. may not have the text yet
        else if currentField == self.dayField {
            self.datePickerValueChanged(self.datePickerView)
        }
        else if currentField == self.startField {
            self.timePickerValueChanged(self.startTimePickerView)
        }
        else if currentField == self.endField {
            self.timePickerValueChanged(self.endTimePickerView)
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
    
    // date picker
    func datePickerValueChanged(sender:UIDatePicker) {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.NoStyle

        date = sender.date
        dateString = dateFormatter.stringFromDate(sender.date)
        currentField!.text = dateString
    }
    
    // start and end time picker
    func timePickerValueChanged(sender:UIDatePicker) {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.NoStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
        currentField!.text = dateFormatter.stringFromDate(sender.date)
        if (sender == startTimePickerView) {
            self.startTime = sender.date
            self.startTimeString = dateFormatter.stringFromDate(sender.date)
        } else {
            self.endTime = sender.date
            self.endTimeString = dateFormatter.stringFromDate(sender.date)
        }
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldDidBeginEditing(textField: UITextField) {
        currentField = textField
    }
    
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

//
//  CreateEventTableViewController.swift
// Balizinha
//
//  Created by Tom Strissel on 5/19/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import SWRevealViewController
import Parse

class CreateEventViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate, SWRevealViewControllerDelegate, UITextFieldDelegate, UITextViewDelegate {
    
    let options = ["Sport Type", "Location", "City", "Day", "Start Time", "End Time", "Max Players"]
    var sportTypes = ["Select Type", "Soccer", "Basketball", "Flag Football"]
    
    var currentField : UITextField?
    var currentTextView : UITextView?
    
    var type : String!
    var city : String!
    var location : String!
    var date : Date!
    var dateString: String!
    var startTime: Date!
    var endTime: Date!
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
    var typePickerView: UIPickerView = UIPickerView()
    var numberPickerView: UIPickerView = UIPickerView()
    var datePickerView: UIDatePicker = UIDatePicker()
    var startTimePickerView: UIDatePicker = UIDatePicker()
    var endTimePickerView: UIDatePicker = UIDatePicker()

    var menuController: MenuTableViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Create Event"
        
        self.setupPickers()
        self.setupTextFields()
        
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))

        }
    
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(CreateEventViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupPickers() {
        
        for picker in [typePickerView, numberPickerView] {
            picker.sizeToFit()
            picker.backgroundColor = .white
            picker.delegate = self
            picker.dataSource = self
        }
        
        for picker in [startTimePickerView, endTimePickerView, datePickerView] {
            picker.sizeToFit()
            picker.backgroundColor = .white
        }
        datePickerView.minimumDate = Date()
        
        self.datePickerView.datePickerMode = UIDatePickerMode.date
        self.datePickerView.addTarget(self, action: #selector(datePickerValueChanged), for: UIControlEvents.valueChanged)
        
        self.startTimePickerView.datePickerMode = UIDatePickerMode.time
        self.startTimePickerView.addTarget(self, action: #selector(timePickerValueChanged), for: UIControlEvents.valueChanged)
        
        self.endTimePickerView.datePickerMode = UIDatePickerMode.time
        self.endTimePickerView.addTarget(self, action: #selector(timePickerValueChanged), for: UIControlEvents.valueChanged)
    }
    
    func setupTextFields() {
        // textfield keyboard
        self.keyboardDoneButtonView = UIToolbar()
        keyboardDoneButtonView.sizeToFit()
        keyboardDoneButtonView.barStyle = UIBarStyle.default
        keyboardDoneButtonView.tintColor = UIColor.white
        let save: UIBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.done, target: self, action: #selector(CreateEventViewController.done))
        save.tintColor = self.view.tintColor
        
        let flex: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        
        keyboardDoneButtonView.setItems([flex, save], animated: true)
        
        // textview keyboard
        self.keyboardDoneButtonView2 = UIToolbar()
        keyboardDoneButtonView2.sizeToFit()
        keyboardDoneButtonView2.barStyle = UIBarStyle.default
        keyboardDoneButtonView2.tintColor = UIColor.white
        let save2: UIBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.done, target: self.view, action: #selector(UIView.endEditing(_:)))
        save2.tintColor = self.view.tintColor
        keyboardDoneButtonView2.setItems([flex, save2], animated: true)
    }
    
    @IBAction func didClickSave(_ sender: AnyObject) {
        // in case user clicks save without clicking done first
        self.info = self.descriptionTextView!.text

        if type != nil && city != nil && location != nil && date != nil && startTime != nil && endTime != nil && numPlayers != nil && info != nil  {
            self.startTime = self.combineDateAndTime(date, time: startTime)
            self.endTime = self.combineDateAndTime(date, time: endTime)
            
            EventService.sharedInstance().createEvent(self.type, city: self.city, place: self.location, startTime: self.startTime, endTime: self.endTime, max_players: self.numPlayers, info: self.info, completion: { (event, error) in
                
                if let event = event {
                    // TODO: create some sort of activity indicator
                    self.revealViewController().revealToggle(nil)
                    self.menuController!.goToMyEvents()
                    self.sendPushForCreatedEvent(event)
                }
                else {
                    if let error = error {
                        self.simpleAlert("Could not create event", defaultMessage: "There was an error creating your event.", error: error)
                    }
                }
            })
        } else {
            let alert = UIAlertController(title: "Alert", message: "Pleae enter all required fields.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            
            self.present(alert, animated: true, completion: nil)
        }
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return options.count
        case 1:
            return 1
        default:
            return 0
        }
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            let cell : DetailCell
            if indexPath.row == 1 || indexPath.row == 2 {
                cell = tableView.dequeueReusableCell(withIdentifier: "cityCell", for: indexPath) as! DetailCell
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
                cell = tableView.dequeueReusableCell(withIdentifier: "detailCell", for: indexPath) as! DetailCell
                
                cell.valueTextField.isUserInteractionEnabled = false;
                cell.valueTextField.delegate = self
                
                switch indexPath.row {
                case 0:
                    self.typeField = cell.valueTextField
                    self.typeField?.inputView = self.typePickerView
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
                    self.maxPlayersField?.inputView = self.numberPickerView
                    cell.valueTextField.inputAccessoryView = nil
                default:
                    break
                }

            }
            cell.labelAttribute.text = options[indexPath.row]

            return cell

        case 1:
            let cell : DescriptionCell = tableView.dequeueReusableCell(withIdentifier: "descriptionCell", for: indexPath) as! DescriptionCell
            self.descriptionTextView = cell.descriptionTextView
            cell.descriptionTextView.delegate = self
            
            cell.descriptionTextView.inputAccessoryView = self.keyboardDoneButtonView2

            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "detailCell", for: indexPath)
            return cell
            
        }

    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        switch section {
        case 0:
            return "Details"
        default:
            return  "Description"
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        switch indexPath.section {
        case 1:
            return 160.0
        default:
            return 44.0
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
                typePickerView.reloadAllComponents()
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
                numberPickerView.reloadAllComponents()
            default:
                break
            }
            currentField = textField
            textField.isUserInteractionEnabled = true
            textField.becomeFirstResponder()
            
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
        if (currentField == self.typeField) {
            self.type = sportTypes[self.typePickerView.selectedRow(inComponent: 0)]
            currentField!.text = self.type
        } else if (currentField == self.maxPlayersField) { //selected max players
            self.numPlayers = UInt(self.pickerView(self.numberPickerView, titleForRow: self.numberPickerView.selectedRow(inComponent: 0), forComponent: 0)!)
            currentField!.text = "\(self.numPlayers!)"
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
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        //print("Reloaded number of rows")
        if pickerView == self.typePickerView {
            return sportTypes.count
        }
        return 30
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        //print("Reloaded components")
        
        if pickerView == self.typePickerView {
            return sportTypes[row]
        }
        if row == 0 {
            return "Select a number"
        }
        return "\(row + 1)"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if row > 0 {
            updateLabel()
            currentField!.isUserInteractionEnabled = false
            currentField!.resignFirstResponder()
        }
        
    }
    
    // date picker
    func datePickerValueChanged(_ sender:UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.medium
        dateFormatter.timeStyle = DateFormatter.Style.none

        date = sender.date
        dateString = dateFormatter.string(from: sender.date)
        currentField!.text = dateString
    }
    
    // start and end time picker
    func timePickerValueChanged(_ sender:UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.none
        dateFormatter.timeStyle = DateFormatter.Style.short
        currentField!.text = dateFormatter.string(from: sender.date)
        if (sender == startTimePickerView) {
            self.startTime = sender.date
        } else {
            self.endTime = sender.date
        }
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        currentField = textField
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == self.cityField {
            self.city = textField.text
        }
        else if textField == self.locationField {
            self.location = textField.text
        }
    }
    
    // MARK: -UITextViewDelegate
    func textViewDidBeginEditing(_ textView: UITextView) {
       self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: self.keyboardHeight, right: 0)
        
        let indexPath = IndexPath(row: 0, section: 1)
        self.tableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.bottom, animated: true)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        self.tableView.contentInset = UIEdgeInsets.zero
        self.info = self.descriptionTextView!.text
    }
    
    // MARK - Keyboard
    func keyboardWillShow(_ notification: Notification) {
        let userInfo:NSDictionary = notification.userInfo! as NSDictionary
        let keyboardFrame:NSValue = userInfo.value(forKey: UIKeyboardFrameEndUserInfoKey) as! NSValue
        let keyboardRectangle = keyboardFrame.cgRectValue
        let keyboardHeight = keyboardRectangle.height
        
        self.keyboardHeight = keyboardHeight
    }
    
    // MARK - Date concatenation
    func combineDateAndTime(_ day: Date, time: Date) -> Date {
        
        let calendar = Calendar.current
        let dateComponents = (calendar as NSCalendar).components([.year, .month, .day], from: day)
        let timeComponents = (calendar as NSCalendar).components([.hour, .minute, .second], from: time)
        
        var components = DateComponents()
        components.year = dateComponents.year
        components.month = dateComponents.month
        components.day = dateComponents.day
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        components.second = timeComponents.second
        
        let newDate = calendar.date(from: components)!
        return newDate
    }

    // MARK: Push notifications
    func sendPushForCreatedEvent(_ event: Event) {
        let userId = firAuth!.currentUser!.uid
        let title = "New event created"
        let message = "A game of \(event.type.rawValue) now available in \(event.place), \(event.city) on \(event.timeString(event.startTime))"
        let params = ["channel": "eventsGlobal", "message": message, "title": title, "sender": userId]
        PFCloud.callFunction(inBackground: "sendPushFromDevice", withParameters: params) { (results, error) in
            print("results \(results) error \(error)")
        }
    }
}

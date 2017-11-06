//
//  CreateEventTableViewController.swift
// Balizinha
//
//  Created by Tom Strissel on 5/19/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import CoreLocation

protocol CreateEventDelegate: class {
    func didCreateEvent()
}

fileprivate enum Sections: Int {
    case photo = 0
    case details = 1
    case notes = 2
    case delete = 3
}

fileprivate var FUTURE_DAYS = 90

class CreateEventViewController: UIViewController, UITextViewDelegate {
    
    var options: [String]!
    var sportTypes = ["Select Type", "3v3", "5v5", "7v7", "11v11"]
    var eventTypes: [EventType] = [.other, .event3v3, .event5v5, .event7v7, .event11v11]
    
    var currentField : UITextField?
    var currentTextView : UITextView?
    
    var name: String?
    var type : EventType?
    var city : String?
    var state: String?
    var place : String?
    var lat: Double?
    var lon: Double?
    var date : Date?
    var dateString: String?
    var startTime: Date?
    var endTime: Date?
    var numPlayers : UInt?
    var info : String?
    var paymentRequired: Bool = false
    var amount: NSNumber?
    
    // organizer cache
    var cachedName: String?
    var cachedPlace: String?
    var cachedCity: String?
    var cachedState: String?
   
    var nameField: UITextField?
    var typeField: UITextField?
    var cityField: UITextField?
    var placeField: UITextField?
    var dayField: UITextField?
    var startField: UITextField?
    var endField: UITextField?
    var maxPlayersField: UITextField?
    var descriptionTextView : UITextView?
    var amountField: UITextField?
    var paymentSwitch: UISwitch?
    
    var keyboardDoneButtonView: UIToolbar!
    var keyboardDoneButtonView2: UIToolbar!
    var keyboardHeight : CGFloat!
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var menuButton: UIBarButtonItem!
    @IBOutlet var saveButton: UIBarButtonItem!

    var typePickerView: UIPickerView = UIPickerView()
    var numberPickerView: UIPickerView = UIPickerView()
    var datePickerView: UIPickerView = UIPickerView()
    var startTimePickerView: UIDatePicker = UIDatePicker()
    var endTimePickerView: UIDatePicker = UIDatePicker()
    var eventImage: UIImage?

    weak var delegate: CreateEventDelegate?
    var cameraController: CameraOverlayViewController?
    
    var eventToEdit: Event?
    var datesForPicker: [Date] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Create Event"
        if let _ = self.eventToEdit {
            self.navigationItem.title = "Edit Event"
        }
        
        options = ["Name", "Event Type", "Location", "Day", "Start Time", "End Time", "Max Players"]
        if SettingsService.paymentRequired() {
            options.append("Payment")
        }
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44
        
        self.setupPickers()
        self.setupTextFields()
        
        if CACHE_ORGANIZER_FAVORITE_LOCATION {
            self.loadCachedOrganizerFavorites()
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
        for picker in [typePickerView, numberPickerView, datePickerView] {
            picker.sizeToFit()
            picker.backgroundColor = .white
            picker.delegate = self
            picker.dataSource = self
        }
        
        self.startTimePickerView.datePickerMode = UIDatePickerMode.time
        self.startTimePickerView.addTarget(self, action: #selector(timePickerValueChanged), for: UIControlEvents.valueChanged)
        
        self.endTimePickerView.datePickerMode = UIDatePickerMode.time
        self.endTimePickerView.addTarget(self, action: #selector(timePickerValueChanged), for: UIControlEvents.valueChanged)

        for picker in [startTimePickerView, endTimePickerView] {
            picker.sizeToFit()
            picker.backgroundColor = .white
            picker.minuteInterval = 15
        }

        self.generatePickerDates()
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
        
//        if TESTING {
//            self.place = "Rittenhouse"
//            self.city = "Philadelphia"
//            self.state = "Pennsylvania"
//            self.date = Date()
//            self.startTime = Date()+1800
//            self.endTime = Date()+3600
//            self.numPlayers = 10
//        }
    }
    
    fileprivate func loadCachedOrganizerFavorites() {
        if let name = UserDefaults.standard.string(forKey: "organizerCachedName") {
            self.name = name
            self.cachedName = name
        }
        if let place = UserDefaults.standard.string(forKey: "organizerCachedPlace") {
            self.place = place
            self.cachedPlace = place
        }
        if let city = UserDefaults.standard.string(forKey: "organizerCachedCity") {
            self.city = city
            self.cachedCity = city
        }
        if let state = UserDefaults.standard.string(forKey: "organizerCachedState") {
            self.state = state
            self.cachedState = state
        }
    }
    
    fileprivate func cacheOrganizerFavorites() {
        UserDefaults.standard.set(self.name, forKey: "organizerCachedName")
        UserDefaults.standard.set(self.place, forKey: "organizerCachedPlace")
        UserDefaults.standard.set(self.city, forKey: "organizerCachedCity")
        UserDefaults.standard.set(self.state, forKey: "organizerCachedState")
    }
    
    @IBAction func didClickSave(_ sender: AnyObject) {
        // in case user clicks save without clicking done first
        self.done()
        
        self.info = self.descriptionTextView?.text ?? eventToEdit?.info
        
        guard let place = self.place else {
            self.simpleAlert("Invalid selection", message: "Please select a place")
            return
        }
        guard let city = self.city else {
            self.simpleAlert("Invalid selection", message: "Please select a city")
            return
        }
        guard let state = self.state else {
            self.simpleAlert("Invalid selection", message: "Please select a state")
            return
        }
        guard let date = self.date else {
            self.simpleAlert("Invalid selection", message: "Please select the event date")
            return
        }
        guard let startTime = self.startTime else {
            self.simpleAlert("Invalid selection", message: "Please select a start time")
            return
        }
        guard let endTime = self.endTime else {
            self.simpleAlert("Invalid selection", message: "Please select an end time")
            return
        }
        guard let numPlayers = self.numPlayers else {
            self.simpleAlert("Invalid selection", message: "Please select the number of players allowed")
            return
        }
        
        if paymentRequired && SettingsService.paymentRequired(){
            guard let amount = self.amount, amount.doubleValue > 0 else {
                self.simpleAlert("Invalid payment amount", message: "Please enter the amount required to play, or turn off the payment requirement.")
                return
            }
        }
        
        if CACHE_ORGANIZER_FAVORITE_LOCATION {
            self.cacheOrganizerFavorites()
        }

        let start = self.combineDateAndTime(date, time: startTime)
        var end = self.combineDateAndTime(date, time: endTime)
        // most like scenario is that endTime is past midnight so it gets interpreted as midnight of the day before.
        if end.timeIntervalSince(start) < 0 {
            end = end.addingTimeInterval(24*3600)
        }
        self.startTime = start
        self.endTime = end
        
        if let event = self.eventToEdit, var dict = event.dict {
            // event already exists: update/edit info
            dict["name"] = self.name ?? "Balizinha"
            dict["type"] = self.type?.rawValue
            dict["city"] = city
            dict["state"] = state
            dict["place"] = place
            dict["lat"] = lat
            dict["lon"] = lon
            dict["maxPlayers"] = numPlayers
            dict["info"] = self.info
            dict["paymentRequired"] = self.paymentRequired
            if paymentRequired {
                dict["amount"] = self.amount
            }
            event.dict = dict
            event.firebaseRef?.updateChildValues(dict) // update all these values without multiple update calls

            // use the built in conversion for dates
            event.startTime = start
            event.endTime = end

            // update photo if it has been changed
            if let photo = self.eventImage {
                FirebaseImageService.uploadImage(image: photo, type: "event", uid: event.id, completion: { (url) in
                    if let url = url {
                        event.photoUrl = url
                    }
                })
            }
            
            self.navigationController?.dismiss(animated: true, completion: {
                // event updated
            })
        }
        else {
            EventService.shared.createEvent(self.name ?? "Balizinha", type: self.type ?? EventType.event3v3, city: city, state: state, lat: lat, lon: lon, place: place, startTime: start, endTime: end, maxPlayers: numPlayers, info: self.info, paymentRequired: self.paymentRequired, amount: self.amount, completion: { (event, error) in
                
                if let event = event {
                    self.sendPushForCreatedEvent(event)
                    
                    if let photo = self.eventImage {
                        FirebaseImageService.uploadImage(image: photo, type: "event", uid: event.id, completion: { (url) in
                            if let url = url {
                                event.photoUrl = url
                            }
                        })
                    }
                    
                    self.navigationController?.dismiss(animated: true, completion: {
                        self.delegate?.didCreateEvent()
                    })
                }
                else {
                    if let error = error {
                        self.simpleAlert("Could not create event", defaultMessage: "There was an error creating your event.", error: error)
                    }
                }
            })
        }
    }

    @IBAction func didClickCancel(_ sender: AnyObject?) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
}

extension CreateEventViewController: UITableViewDataSource, UITableViewDelegate {
    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        if eventToEdit?.userIsOrganizer == true {
            return 4
        }
        return 3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Sections.photo.rawValue: // photo
            return 1
        case Sections.details.rawValue: // details
            return options.count
        case Sections.notes.rawValue: // description
            return 1
        case Sections.delete.rawValue:
            return 1
        default:
            return 0
        }
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case Sections.photo.rawValue:
            let cell: EventPhotoCell = tableView.dequeueReusableCell(withIdentifier: "EventPhotoCell", for: indexPath) as! EventPhotoCell
            if let url = self.eventToEdit?.photoUrl {
                cell.url = url
            }
            else if let photo = self.eventImage {
                cell.photo = photo
            }
            return cell
        case Sections.details.rawValue:
            let cell : DetailCell
            if options[indexPath.row] == "Location" || options[indexPath.row] == "City" || options[indexPath.row] == "Name" {
                cell = tableView.dequeueReusableCell(withIdentifier: "cityCell", for: indexPath) as! DetailCell
                cell.valueTextField.delegate = self
                cell.valueTextField.inputAccessoryView = nil
                
                if options[indexPath.row] == "Location" {
                    cell.valueTextField.placeholder = "Fenway Park"
                    self.placeField = cell.valueTextField
                    if let place = self.eventToEdit?.place {
                        self.place = place
                        self.placeField?.text = place
                    }
                    else if let cachedPlace = self.cachedPlace {
                        self.place = cachedPlace
                        self.placeField?.text = cachedPlace
                    }
                    self.placeField?.isUserInteractionEnabled = false
                } else if options[indexPath.row] == "City" {
                    cell.valueTextField.placeholder = "Boston"
                    self.cityField = cell.valueTextField
                    if let city = self.eventToEdit?.city {
                        self.city = city
                        self.cityField?.text = city
                    }
                    else if let cachedCity = self.cachedCity {
                        self.city = cachedCity
                        self.cityField?.text = cachedCity
                    }
                    self.cityField?.isUserInteractionEnabled = false
                } else if options[indexPath.row] == "Name" {
                    cell.valueTextField.placeholder = "Balizinha"
                    self.nameField = cell.valueTextField
                    if let name = self.eventToEdit?.name {
                        self.name = name
                        self.nameField?.text = name
                    }
                    else if let cachedName = self.cachedName {
                        self.name = cachedName
                        self.nameField?.text = cachedName
                    }
                    self.nameField?.isUserInteractionEnabled = true
                }
                
            }
            else if options[indexPath.row] == "Payment" {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ToggleCell", for: indexPath) as! ToggleCell
                cell.input.inputAccessoryView = keyboardDoneButtonView
                cell.delegate = self
                self.amountField = cell.input
                self.paymentSwitch = cell.switchToggle
                
                if let amount = self.eventToEdit?.amount {
                    self.paymentRequired = self.eventToEdit?.paymentRequired ?? false
                    self.amount = amount
                }
                self.didToggleSwitch(isOn: paymentRequired)
                return cell
            }
            else {
                cell = tableView.dequeueReusableCell(withIdentifier: "detailCell", for: indexPath) as! DetailCell
                
                cell.valueTextField.isUserInteractionEnabled = false;
                cell.valueTextField.delegate = self
                
                switch options[indexPath.row] {
                case "Event Type":
                    self.typeField = cell.valueTextField
                    self.typeField?.inputView = self.typePickerView
                    cell.valueTextField.inputAccessoryView = self.keyboardDoneButtonView2
                    
                    if let event = self.eventToEdit, let index = self.eventTypes.index(of: event.type) {
                        self.type = event.type
                        self.typeField?.text = self.sportTypes[index]
                    }
                case "Day":
                    self.dayField = cell.valueTextField
                    self.dayField?.inputView = self.datePickerView
                    cell.valueTextField.inputAccessoryView = self.keyboardDoneButtonView
                    if let date = self.eventToEdit?.startTime {
                        self.date = date
                        self.dayField?.text = date.dateStringForPicker()
                    }
                case "Start Time":
                    self.startField = cell.valueTextField
                    self.startField?.inputView = self.startTimePickerView
                    cell.valueTextField.inputAccessoryView = self.keyboardDoneButtonView
                    if let date = self.eventToEdit?.startTime {
                        self.startTime = date
                        self.startField?.text = date.timeStringForPicker()
                    }
                case "End Time":
                    self.endField = cell.valueTextField
                    self.endField?.inputView = self.endTimePickerView
                    cell.valueTextField.inputAccessoryView = self.keyboardDoneButtonView
                    if let date = self.eventToEdit?.endTime {
                        self.endTime = date
                        self.endField?.text = date.timeStringForPicker()
                    }
                case "Max Players":
                    self.maxPlayersField = cell.valueTextField
                    self.maxPlayersField?.inputView = self.numberPickerView
                    cell.valueTextField.inputAccessoryView = self.keyboardDoneButtonView2

                    if let max = self.eventToEdit?.maxPlayers {
                        self.numPlayers = UInt(max)
                        self.maxPlayersField?.text = "\(max)"
                    }
                default:
                    break
                }

            }
            cell.labelAttribute.text = options[indexPath.row]

            return cell

        case Sections.notes.rawValue:
            let cell : DescriptionCell = tableView.dequeueReusableCell(withIdentifier: "descriptionCell", for: indexPath) as! DescriptionCell
            self.descriptionTextView = cell.descriptionTextView
            cell.descriptionTextView.delegate = self
            
            cell.descriptionTextView.inputAccessoryView = self.keyboardDoneButtonView2
            
            if let notes = self.eventToEdit?.info {
                self.info = notes
                cell.descriptionTextView.text = notes
            }

            return cell
        case Sections.delete.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: "DeleteCell", for: indexPath)
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "detailCell", for: indexPath)
            return cell
            
        }

    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel(frame: CGRect(x: 20, y: 0, width: self.view.frame.size.width - 20, height: 40))
        let view = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 40))
        view.backgroundColor = UIColor.clear
        label.backgroundColor = UIColor.clear
        switch section {
        case Sections.photo.rawValue:
            return nil
        case Sections.details.rawValue:
            label.text = "Details"
        case Sections.notes.rawValue:
            label.text = "Description"
        case Sections.delete.rawValue:
            view.backgroundColor = .white
            label.text = ""
        default:
            return nil;
        }
        label.textColor = UIColor.white
        view.addSubview(label)
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == Sections.delete.rawValue {
            return 0.1
        }
        return 40
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case Sections.photo.rawValue:
            self.selectPhoto()
        case Sections.details.rawValue:
            if currentField != nil{
                currentField!.resignFirstResponder()
            }
            
            let textField: UITextField?
            switch options[indexPath.row] {
            case "Name":
                textField = self.nameField
            case "Event Type":
                textField = self.typeField
                typePickerView.reloadAllComponents()
            case "Location":
                textField = self.placeField
            case "City":
                textField = self.cityField
            case "Day":
                textField = self.dayField
            case "Start Time":
                textField = self.startField
            case "End Time":
                textField = self.endField
            case "Max Players":
                textField = self.maxPlayersField
                print("Tapped number of players")
                numberPickerView.reloadAllComponents()
            default:
                textField = nil
            }
            textField?.isUserInteractionEnabled = true
            textField?.becomeFirstResponder()
            currentField = textField
            
            if options[indexPath.row] == "Location" {
                performSegue(withIdentifier: "toLocationSearch", sender: nil)
            }
        case Sections.delete.rawValue:
            self.didClickDelete(nil)
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
        guard currentField != nil else { return }
        
        if (currentField == self.typeField) {
            let selectedRow = self.typePickerView.selectedRow(inComponent: 0)
            self.type = eventTypes[selectedRow]
            currentField!.text = self.sportTypes[selectedRow]
        } else if (currentField == self.maxPlayersField) { //selected max players
            self.numPlayers = UInt(self.pickerView(self.numberPickerView, titleForRow: self.numberPickerView.selectedRow(inComponent: 0), forComponent: 0)!)
            if let numPlayers = self.numPlayers {
                currentField!.text = "\(numPlayers)"
            }
        }
        // comes from clicking on done button. may not have the text yet
        else if currentField == self.startField {
            self.timePickerValueChanged(self.startTimePickerView)
        }
        else if currentField == self.endField {
            self.timePickerValueChanged(self.endTimePickerView)
        }
        else if currentField == self.dayField {
            self.datePickerValueChanged(self.datePickerView)
        }
        else if currentField == self.amountField {
            if let formattedAmount = EventService.amountNumber(from: self.amountField?.text) {
                self.amount = formattedAmount
                if let string = EventService.amountString(from: formattedAmount) {
                    self.amountField?.text = string
                }
            }
            else {
                self.revertAmount()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toLocationSearch", let controller = segue.destination as? PlaceSearchViewController {
            controller.delegate = self
        }
    }
}

// MARK: Delete
extension CreateEventViewController {
    func didClickDelete(_ sender: UIButton?) {
        guard let event = eventToEdit else { return }
        let alert = UIAlertController(title: "Are you sure?", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes, delete this event", style: .default, handler: { (action) in
            EventService.shared.deleteEvent(event)
            self.didClickCancel(nil)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: PickerView
extension CreateEventViewController: UIPickerViewDataSource, UIPickerViewDelegate {
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
        else if pickerView == self.numberPickerView {
            return 30
        }
        return FUTURE_DAYS // datePickerView: default 3 months
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        //print("Reloaded components")
        
        if pickerView == self.typePickerView {
            return sportTypes[row]
        }
        else if pickerView == self.datePickerView {
            if row < self.datesForPicker.count {
                return self.datesForPicker[row].dateStringForPicker()
            }
        }
        if row == 0 {
            return "Select a number"
        }
        return "\(row + 1)"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // let user pick more dates and click done
        guard pickerView != self.datePickerView else { return }
        guard let currentField = currentField else { return }
        guard row > 0 else { return }

        updateLabel()
        currentField.isUserInteractionEnabled = false
        currentField.resignFirstResponder()
    }
    
    func datePickerValueChanged(_ sender:UIPickerView) {
        let row = sender.selectedRow(inComponent: 0)
        guard row < self.datesForPicker.count else { return }
        self.date = self.datesForPicker[row]
        self.dateString = self.datesForPicker[row].dateStringForPicker()
        currentField!.text = dateString
    }
    
    func timePickerValueChanged(_ sender:UIDatePicker) {
        currentField!.text = sender.date.timeStringForPicker()
        if (sender == startTimePickerView) {
            self.startTime = sender.clampedDate
        } else {
            self.endTime = sender.clampedDate
        }
    }
}

extension CreateEventViewController: UITextFieldDelegate {
    // MARK: - UITextFieldDelegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        currentField = textField
        
        if currentField == startField {
            startTimePickerView.date = startTime ?? Date()
            startTimePickerView.date = startTimePickerView.futureClampedDate
        }
        else if currentField == endField {
            endTimePickerView.date = Date()
            if let time = startTime {
                endTimePickerView.date = time.addingTimeInterval(3600)
            }
            endTimePickerView.date = endTimePickerView.futureClampedDate
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == self.nameField {
            self.name = textField.text
        }
        else if textField == self.amountField, let newAmount = EventService.amountNumber(from: textField.text) {
            var title = "Payment amount"
            var shouldShow = false
            if newAmount.doubleValue < 1 {
                title = "Low payment amount"
                shouldShow = true
            }
            else if newAmount.doubleValue >= 20 {
                title = "High payment amount"
                shouldShow = true
            }
            if shouldShow, let string = EventService.amountString(from: newAmount) {
                let oldAmount = self.amount
                let alert = UIAlertController(title: title, message: "Are you sure you want the payment per player to be \(string)?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                    self.amount = oldAmount // because of timing issue, self.amount gets set to new amount by now
                    self.revertAmount()
                }))
                alert.addAction(UIAlertAction(title: "Amount is correct", style: .default, handler: { (action) in
                    
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: -UITextViewDelegate
    func textViewDidBeginEditing(_ textView: UITextView) {
       self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: self.keyboardHeight, right: 0)
        
        let indexPath = IndexPath(row: 0, section: Sections.notes.rawValue)
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
        let userId = firAuth.currentUser!.uid
        let title = "New event created"
        var dateString = ""
        if let startTime = event.startTime {
            dateString = " on \(event.timeString(startTime))"
        }
        let message = "A game of \(event.type.rawValue) now available in \(event.place), \(event.city)\(dateString)"
        let params = ["channel": "eventsGlobal", "message": message, "title": title, "sender": userId]
//        PFCloud.callFunction(inBackground: "sendPushFromDevice", withParameters: params) { (results, error) in
//            print("results \(results) error \(error)")
//        }
    }
}

// photo
extension CreateEventViewController: CameraControlsDelegate {
    func selectPhoto() {
        self.view.endEditing(true)
        
        let controller = CameraOverlayViewController(
            nibName:"CameraOverlayViewController",
            bundle: nil
        )
        controller.delegate = self
        controller.view.frame = self.view.frame
        controller.takePhoto(from: self)
        self.cameraController = controller
    }
    
    func didTakePhoto(image: UIImage) {
        self.eventImage = image
        let indexPath = IndexPath(row: 0, section: 0)
        self.tableView.reloadRows(at: [indexPath], with: .automatic)
        self.dismissCamera()
    }
    
    func dismissCamera() {
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: custom weekday pickers
extension CreateEventViewController {
    func generatePickerDates() {
        guard self.datesForPicker.count == 0 else { return }
        
        for var row in 0..<FUTURE_DAYS {
            let date = Date().addingTimeInterval(3600*24*TimeInterval(row))
            datesForPicker.append(date)
        }
    }
}

// MARK: ToggleCell
extension CreateEventViewController: ToggleCellDelegate {
    func didToggleSwitch(isOn: Bool) {
        paymentRequired = isOn
        self.paymentSwitch?.isOn = isOn
        self.amountField?.isEnabled = isOn
        self.amountField?.isHidden = !isOn
        if isOn {
            self.revertAmount()
        }
    }
    
    func revertAmount() {
        self.amountField?.text = EventService.amountString(from: self.amount)
    }
}

// MARK: PlaceSearchDelegate
extension CreateEventViewController: PlaceSelectDelegate {
    func didSelectPlace(name: String?, street: String?, city: String?, state: String?, location: CLLocationCoordinate2D?) {
        if let location = name {
            self.placeField?.text = location
            self.place = location
        }
        else if let street = street {
            self.placeField?.text = street
            self.place = street
        }
        
        if let city = city {
            self.cityField?.text = city
            self.city = city
        }
        
        if let state = state {
            // none
            self.state = state
        }
        
        if let coordinate = location {
            self.lat = coordinate.latitude
            self.lon = coordinate.longitude
        }
        
        self.navigationController?.popToViewController(self, animated: true)
    }
}

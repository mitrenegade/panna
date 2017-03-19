//
//  CreateEventTableViewController.swift
// Balizinha
//
//  Created by Tom Strissel on 5/19/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Parse

protocol CreateEventDelegate {
    func didCreateEvent()
}

fileprivate enum Sections: Int {
    case photo = 0
    case details = 1
    case notes = 2
}

class CreateEventViewController: UIViewController, UITextViewDelegate {
    
    var options = ["Name", "Event Type", "Location", "City", "Day", "Start Time", "End Time", "Max Players"]
    var sportTypes = ["Select Type", "3v3", "5v5", "7v7", "11v11"]
    var eventTypes: [EventType] = [.other, .event3v3, .event5v5, .event7v7, .event11v11]
    
    var currentField : UITextField?
    var currentTextView : UITextView?
    
    var name: String?
    var type : EventType?
    var city : String?
    var location : String?
    var date : Date?
    var dateString: String?
    var startTime: Date?
    var endTime: Date?
    var numPlayers : UInt?
    var info : String?
   
    var nameField: UITextField?
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
    var eventImage: UIImage?

    var delegate: CreateEventDelegate?
    var cameraController: CameraOverlayViewController?
    
    var eventToEdit: Event?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Create Event"
        if let _ = self.eventToEdit {
            self.setupEditEvent()
        }
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44
        
        self.setupPickers()
        self.setupTextFields()
    
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
        
        if TESTING {
            self.location = "Rittenhouse"
            self.city = "Philadelphia"
            self.date = Date()
            self.startTime = Date()+1800
            self.endTime = Date()+3600
            self.numPlayers = 10
        }
    }
    
    @IBAction func didClickSave(_ sender: AnyObject) {
        // in case user clicks save without clicking done first
        self.view.endEditing(true)
        self.info = self.descriptionTextView!.text
        
        guard let location = self.location else {
            self.simpleAlert("Invalid selection", message: "Please select a location")
            return
        }
        guard let city = self.city else {
            self.simpleAlert("Invalid selection", message: "Please select a city")
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

        let start = self.combineDateAndTime(date, time: startTime)
        let end = self.combineDateAndTime(date, time: endTime)
        self.startTime = start
        self.endTime = end
        
        if let event = self.eventToEdit, var dict = event.dict {
            // event already exists: update/edit info
            dict["name"] = self.name ?? "Balizinha"
            dict["type"] = self.type?.rawValue
            dict["city"] = city
            dict["place"] = location
            dict["maxPlayers"] = numPlayers
            dict["info"] = self.info
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
            EventService.shared.createEvent(self.name ?? "Balizinha", type: self.type ?? EventType.event3v3, city: city, place: location, startTime: start, endTime: end, max_players: numPlayers, info: self.info, completion: { (event, error) in
                
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

    @IBAction func didClickCancel(_ sender: AnyObject) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
}

extension CreateEventViewController: UITableViewDataSource, UITableViewDelegate {
    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
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
                    self.locationField = cell.valueTextField
                    if let place = self.eventToEdit?.place {
                        self.location = place
                        self.locationField?.text = place
                    }
                } else if options[indexPath.row] == "City" {
                    cell.valueTextField.placeholder = "Boston"
                    self.cityField = cell.valueTextField
                    if let city = self.eventToEdit?.city {
                        self.city = city
                        self.cityField?.text = city
                    }
                } else if options[indexPath.row] == "Name" {
                    cell.valueTextField.placeholder = "Balizinha"
                    self.nameField = cell.valueTextField
                    if let name = self.eventToEdit?.name {
                        self.name = name
                        self.nameField?.text = name
                    }
                }
                
            }
            else {
                cell = tableView.dequeueReusableCell(withIdentifier: "detailCell", for: indexPath) as! DetailCell
                
                cell.valueTextField.isUserInteractionEnabled = false;
                cell.valueTextField.delegate = self
                
                switch options[indexPath.row] {
                case "Event Type":
                    self.typeField = cell.valueTextField
                    self.typeField?.inputView = self.typePickerView
                    cell.valueTextField.inputAccessoryView = nil
                    
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
                        self.dayField?.text = self.dateStringForDate(date)
                    }
                case "Start Time":
                    self.startField = cell.valueTextField
                    self.startField?.inputView = self.startTimePickerView
                    cell.valueTextField.inputAccessoryView = self.keyboardDoneButtonView
                    if let date = self.eventToEdit?.startTime {
                        self.startTime = date
                        self.startField?.text = self.timeStringForDate(date)
                    }
                case "End Time":
                    self.endField = cell.valueTextField
                    self.endField?.inputView = self.endTimePickerView
                    cell.valueTextField.inputAccessoryView = self.keyboardDoneButtonView
                    if let date = self.eventToEdit?.endTime {
                        self.endTime = date
                        self.endField?.text = self.timeStringForDate(date)
                    }
                case "Max Players":
                    self.maxPlayersField = cell.valueTextField
                    self.maxPlayersField?.inputView = self.numberPickerView
                    cell.valueTextField.inputAccessoryView = nil

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
        default:
            label.text = "Description"
        }
        label.textColor = UIColor.white
        view.addSubview(label)
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
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
            
            var textField: UITextField!
            switch options[indexPath.row] {
            case "Name":
                textField = self.nameField!
            case "Event Type":
                textField = self.typeField!
                typePickerView.reloadAllComponents()
            case "Location":
                textField = self.locationField!
            case "City":
                textField = self.cityField!
            case "Day":
                textField = self.dayField!
            case "Start Time":
                textField = self.startField!
            case "End Time":
                textField = self.endField!
            case "Max Players":
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
            let selectedRow = self.typePickerView.selectedRow(inComponent: 0)
            self.type = eventTypes[selectedRow]
            currentField!.text = self.sportTypes[selectedRow]
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
    func dateStringForDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.medium
        dateFormatter.timeStyle = DateFormatter.Style.none
        return dateFormatter.string(from: date)
    }
    
    func datePickerValueChanged(_ sender:UIDatePicker) {
        self.date = sender.date
        self.dateString = self.dateStringForDate(sender.date)
        currentField!.text = dateString
    }
    
    // start and end time picker
    func timeStringForDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.none
        dateFormatter.timeStyle = DateFormatter.Style.short
        return dateFormatter.string(from: date)
    }
    func timePickerValueChanged(_ sender:UIDatePicker) {
        currentField!.text = timeStringForDate(sender.date)
        if (sender == startTimePickerView) {
            self.startTime = sender.date
        } else {
            self.endTime = sender.date
        }
    }
}

extension CreateEventViewController: UITextFieldDelegate {
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
        else if textField == self.nameField {
            self.name = textField.text
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
        var dateString = ""
        if let startTime = event.startTime {
            dateString = " on \(event.timeString(startTime))"
        }
        let message = "A game of \(event.type.rawValue) now available in \(event.place), \(event.city)\(dateString)"
        let params = ["channel": "eventsGlobal", "message": message, "title": title, "sender": userId]
        PFCloud.callFunction(inBackground: "sendPushFromDevice", withParameters: params) { (results, error) in
            print("results \(results) error \(error)")
        }
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
        
        // add overlayview
        //ParseLog.log(typeString: "AddEventPhoto", title: nil, message: nil, params: nil, error: nil)
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

// MARK: Edit event
extension CreateEventViewController {
    func setupEditEvent() {
        guard let event = self.eventToEdit else { return }
        self.navigationItem.title = "Edit Event"

        self.name = event.name
        self.type = event.type
        self.location = event.place
        self.city = event.city
        
        // day
        
        // start time
        
        // end time
        
        // max players
        self.numPlayers = UInt(event.maxPlayers)
    }
}

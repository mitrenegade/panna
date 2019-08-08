//
//  CreateEventTableViewController.swift
// Balizinha
//
//  Created by Tom Strissel on 5/19/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import CoreLocation
import Balizinha
import RenderCloud

protocol CreateEventDelegate: class {
    func eventsDidChange()
}

fileprivate enum Sections: Int {
    case photo = 0
    case details = 1
    case notes = 2
    case cancel = 3
}

fileprivate var FUTURE_DAYS = 90

class CreateEventViewController: UIViewController, UITextViewDelegate {
    
    var options: [String]!
    var eventTypes: [Balizinha.Event.EventType] = [.other, .event3v3, .event5v5, .event7v7, .event11v11, .group, .social]
    
    var currentField : UITextField?
    var currentTextView : UITextView?
    
    var name: String?
    var type : Balizinha.Event.EventType?
    var venue: Venue?
    var date : Date?
    var dateString: String?
    var startTime: Date?
    var endTime: Date?
    var maxPlayers : UInt?
    var info : String?
    var paymentRequired: Bool = false
    var amount: NSNumber?
    
    var nameField: UITextField?
    var typeField: UITextField?
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

    fileprivate let activityOverlay: ActivityIndicatorOverlay = ActivityIndicatorOverlay()

    var typePickerView: UIPickerView = UIPickerView()
    var numberPickerView: UIPickerView = UIPickerView()
    var datePickerView: UIPickerView = UIPickerView()
    var startTimePickerView: UIDatePicker = UIDatePicker()
    var endTimePickerView: UIDatePicker = UIDatePicker()
    var league: League?

    weak var delegate: CreateEventDelegate?
    
    var newEventImage: UIImage? // if user selects a new image or is cloning
    var currentEventUrl: String? // url used to display existing image
    var eventToEdit: Balizinha.Event? {
        didSet {
            cloneInfo(for: eventToEdit)
        }
    }
    var eventToClone: Balizinha.Event? {
        didSet {
            cloneInfo(for: eventToClone)
        }
    }
    var datesForPicker: [Date] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = league?.name ?? "Create Event"
        if let _ = self.eventToEdit {
            self.navigationItem.title = "Edit Event"
        }
        
        options = ["Name", "Event Type", "Venue", "Day", "Start Time", "End Time", "Max Players"]
        if SettingsService.paymentRequired() {
            options.append("Payment")
        }
        
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 44
        
        self.setupPickers()
        self.setupTextFields()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(didClickSave(_:)))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(didClickCancel(_:)))
        
        if eventToEdit == nil && eventToClone == nil && CACHE_ORGANIZER_FAVORITE_LOCATION {
            self.loadCachedOrganizerFavorites()
        } else if let event = eventToEdit, event.isCancelled {
            // prompt to uncancel event right away
            promptForCancelDeleteEvent(event)
        }
        
        view.addSubview(activityOverlay)
    }

    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(CreateEventViewController.keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        activityOverlay.setup(frame: view.frame)
    }
    
    // used when editing or cloning an existing event
    fileprivate func cloneInfo(for event: Balizinha.Event?) {
        guard let event = event else { return }
        name = event.name
        type = event.type
        if event == eventToEdit {
            // only include date if event is being edited
            date = eventToEdit?.startTime
            startTime = eventToEdit?.startTime
            endTime = eventToEdit?.endTime
        }
        maxPlayers = UInt(event.maxPlayers)
        info = event.info
        paymentRequired = event.paymentRequired
        amount = event.amount
        
        // TODO: replace with event.venue
        if let place = event.place,
            let city = event.city,
            let state = event.state,
            let lat = event.lat,
            let lon = event.lon
        {
            venue = Venue(place, nil, city, state, lat, lon)
        }
        
        if let leagueId = event.leagueId {
            LeagueService.shared.withId(id: leagueId) { [weak self] (league) in
                self?.league = league
                // in case this takes time to load
                self?.refreshLeaguePhoto()
            }
        }
        
        FirebaseImageService().eventPhotoUrl(for: event) { [weak self] (url) in
            if let urlString = url?.absoluteString {
                if event == self?.eventToClone {
                    // load photo and store it in newEventImage since it will get saved as a new image
                    let manager = RAImageManager(imageView: nil)
                    manager.load(imageUrl: urlString, completion: { [weak self] (image) in
                        DispatchQueue.main.async {
                            self?.newEventImage = image
                            let indexPath = IndexPath(row: 0, section: Sections.photo.rawValue)
                            self?.tableView.reloadRows(at: [indexPath], with: .automatic)
                        }
                    })
                } else if event == self?.eventToEdit {
                    // save downloaded url just to display
                    self?.currentEventUrl = urlString
                    let indexPath = IndexPath(row: 0, section: Sections.photo.rawValue)
                    self?.tableView.reloadRows(at: [indexPath], with: .automatic)
                }
            }
        }
    }
    
    func setupPickers() {
        for picker in [typePickerView, numberPickerView, datePickerView] {
            picker.sizeToFit()
            picker.backgroundColor = .white
            picker.delegate = self
            picker.dataSource = self
        }
        
        self.startTimePickerView.datePickerMode = .time
        self.startTimePickerView.addTarget(self, action: #selector(timePickerValueChanged), for: .valueChanged)
        
        self.endTimePickerView.datePickerMode = .time
        self.endTimePickerView.addTarget(self, action: #selector(timePickerValueChanged), for: .valueChanged)

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
        let save: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(CreateEventViewController.done))
        save.tintColor = self.view.tintColor
        
        let flex: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        keyboardDoneButtonView.setItems([flex, save], animated: true)
        
        // textview keyboard
        self.keyboardDoneButtonView2 = UIToolbar()
        keyboardDoneButtonView2.sizeToFit()
        keyboardDoneButtonView2.barStyle = UIBarStyle.default
        keyboardDoneButtonView2.tintColor = UIColor.white
        let save2: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self.view, action: #selector(UIView.endEditing(_:)))
        save2.tintColor = self.view.tintColor
        keyboardDoneButtonView2.setItems([flex, save2], animated: true)
        
        if TESTING, eventToEdit == nil, eventToClone == nil {
            self.date = Date()
            self.startTime = Date()+1800
            self.endTime = Date()+3600
            maxPlayers = 10
        }
    }
    
    fileprivate var leaguePhotoView: RAImageView?
    fileprivate lazy var photoHeaderView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 100))
        view.backgroundColor = UIColor.mediumGreen
        view.clipsToBounds = true
        let photoView = RAImageView(frame: CGRect(x: view.frame.size.width / 2 - 40, y: 10, width: 80, height: 80))
        photoView.layer.cornerRadius = 5
        photoView.backgroundColor = .clear
        photoView.image = nil
        photoView.clipsToBounds = true
        view.addSubview(photoView)
        leaguePhotoView = photoView
        leaguePhotoView?.contentMode = .scaleAspectFill
        
        refreshLeaguePhoto()
        return view
    }()
    
    fileprivate func refreshLeaguePhoto() {
        if let leagueId = league?.id {
            FirebaseImageService().leaguePhotoUrl(with: leagueId) {[weak self] (url) in
                DispatchQueue.main.async {
                    if let url = url {
                        self?.leaguePhotoView?.imageUrl = url.absoluteString
                    } else {
                        self?.leaguePhotoView?.imageUrl = nil
                        self?.leaguePhotoView?.image = UIImage(named: "crest30")?.withRenderingMode(.alwaysTemplate)
                        self?.leaguePhotoView?.tintColor = UIColor.white
                    }
                }
            }
        }
    }

    fileprivate func loadCachedOrganizerFavorites() {
        if let name = UserDefaults.standard.string(forKey: "organizerCachedName") {
            self.name = name
        }
        if let place = UserDefaults.standard.string(forKey: "organizerCachedPlace"),
            let street = UserDefaults.standard.string(forKey: "organizerCachedStreet"),
            let city = UserDefaults.standard.string(forKey: "organizerCachedCity"),
            let state = UserDefaults.standard.string(forKey: "organizerCachedState"),
            let lat = UserDefaults.standard.value(forKey: "organizerCachedLat") as? Double,
            let lon = UserDefaults.standard.value(forKey: "organizerCachedLon") as? Double
        {
            self.venue = Venue(place, street, city, state, lat, lon)
        }
        if let type = UserDefaults.standard.string(forKey: "organizerCachedType") {
            self.type = Balizinha.Event.EventType(rawValue: type)
        }
        if let info = UserDefaults.standard.string(forKey: "organizerCachedInfo") {
            self.info = info
        }
    }
    
    fileprivate func cacheOrganizerFavorites() {
        if let name = name {
            UserDefaults.standard.set(name, forKey: "organizerCachedName")
        } else {
            UserDefaults.standard.set(nil, forKey: "organizerCachedName")
        }
        
        if let venue = venue {
            UserDefaults.standard.set(venue.name, forKey: "organizerCachedPlace")
            UserDefaults.standard.set(venue.street, forKey: "organizerCachedStreet")
            UserDefaults.standard.set(venue.city, forKey: "organizerCachedCity")
            UserDefaults.standard.set(venue.state, forKey: "organizerCachedState")
            UserDefaults.standard.set(venue.lat, forKey: "organizerCachedLat")
            UserDefaults.standard.set(venue.lon, forKey: "organizerCachedLon")
        } else {
            UserDefaults.standard.set(nil, forKey: "organizerCachedPlace")
            UserDefaults.standard.set(nil, forKey: "organizerCachedStreet")
            UserDefaults.standard.set(nil, forKey: "organizerCachedCity")
            UserDefaults.standard.set(nil, forKey: "organizerCachedState")
            UserDefaults.standard.set(nil, forKey: "organizerCachedLat")
            UserDefaults.standard.set(nil, forKey: "organizerCachedLon")
        }
        
        if let type = type {
            UserDefaults.standard.set(type.rawValue, forKey: "organizerCachedType")
        }
        if let info = info {
            UserDefaults.standard.set(info, forKey: "organizerCachedInfo")
        }
    }
    
    @IBAction func didClickSave(_ sender: AnyObject) {
        // in case user clicks save without clicking done first
        self.done()
        self.info = self.descriptionTextView?.text ?? eventToEdit?.info
        
        guard let venue = venue else {
            self.simpleAlert("Invalid selection", message: "Please select a venue")
            return
        }
        guard let venueName = venue.name ?? venue.street else {
            self.simpleAlert("Invalid selection", message: "Invalid name for selected venue")
            return
        }
        guard let city = venue.city else {
            self.simpleAlert("Invalid selection", message: "Invalid city for selected venue")
            return
        }
        guard let state = venue.state else {
            self.simpleAlert("Invalid selection", message: "Invalid state for selected venue")
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
        guard let maxPlayers = self.maxPlayers else {
            self.simpleAlert("Invalid selection", message: "Please select the number of players allowed")
            return
        }
        
        if paymentRequired && SettingsService.paymentRequired(){
            guard let amount = self.amount, amount.doubleValue > 0 else {
                self.simpleAlert("Invalid payment amount", message: "Please enter the amount required to play, or turn off the payment requirement.")
                return
            }
        }

        navigationItem.rightBarButtonItem?.isEnabled = false

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
            dict["place"] = venueName
            dict["lat"] = venue.lat
            dict["lon"] = venue.lon
            dict["maxPlayers"] = maxPlayers
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
            if let image = newEventImage {
                savePhoto(photo: image, event: event, completion: { url, id in
                    // no callback action
                    self.navigationController?.dismiss(animated: true, completion: {
                        // event updated - force reload
                        self.delegate?.eventsDidChange()
                    })
                })
            } else {
                self.navigationController?.dismiss(animated: true, completion: {
                    // event updated - force reload
                    self.delegate?.eventsDidChange()
                })
            }
        }
        else {
            activityOverlay.show()
            EventService.shared.createEvent(self.name ?? "Balizinha", type: self.type ?? .event3v3, city: city, state: state, lat: venue.lat, lon: venue.lon, place: venueName, startTime: start, endTime: end, maxPlayers: maxPlayers, info: self.info, paymentRequired: self.paymentRequired, amount: self.amount, leagueId: league?.id, completion: { [weak self] (event, error) in
                
                DispatchQueue.main.async {
                    self?.activityOverlay.hide()
                    
                    guard let event = event else {
                        if let error = error {
                            self?.simpleAlert("Could not create event", defaultMessage: "There was an error creating your event.", error: error)
                        }
                        self?.navigationItem.rightBarButtonItem?.isEnabled = true
                        return
                    }
                    
                    // update photo if it has been changed
                    if let image = self?.newEventImage {
                        self?.savePhoto(photo: image, event: event, completion: { url, id in
                            // no callback action
                            self?.navigationController?.dismiss(animated: true, completion: {
                                // event created
                                self?.delegate?.eventsDidChange()
                            })
                        })
                    } else {
                        self?.navigationController?.dismiss(animated: true, completion: {
                            // event created
                            self?.delegate?.eventsDidChange()
                        })
                    }
                }
            })
            
            if eventToClone != nil {
                LoggingService.shared.log(event: .ClonedEvent, info: nil)
            }
        }
    }
    
    @objc func didClickCancel(_ sender: Any) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
}

extension CreateEventViewController: UITableViewDataSource, UITableViewDelegate {
    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        if let event = eventToEdit, event.userIsOrganizer(), CancelEventViewModel(event: event).shouldShow {
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
        case Sections.cancel.rawValue:
            return 1
        default:
            return 0
        }
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case Sections.photo.rawValue:
            let cell: EventPhotoCell = tableView.dequeueReusableCell(withIdentifier: "EventPhotoCell", for: indexPath) as! EventPhotoCell
            if let photo = newEventImage {
                cell.photo = photo
            } else if let url = currentEventUrl {
                cell.url = url
            }
            return cell
        case Sections.details.rawValue:
            let cell : DetailCell
            if options[indexPath.row] == "Venue" || options[indexPath.row] == "City" || options[indexPath.row] == "Name" {
                cell = tableView.dequeueReusableCell(withIdentifier: "cityCell", for: indexPath) as! DetailCell
                cell.valueTextField.delegate = self
                cell.valueTextField.inputAccessoryView = nil
                
                if options[indexPath.row] == "Venue" {
                    cell.valueTextField.placeholder = "Fenway Park"
                    self.placeField = cell.valueTextField
                    self.placeField?.text = venue?.name
                    self.placeField?.isUserInteractionEnabled = false
                } else if options[indexPath.row] == "Name" {
                    cell.valueTextField.placeholder = "Balizinha"
                    self.nameField = cell.valueTextField
                    self.nameField?.text = name
                    self.nameField?.isUserInteractionEnabled = true
                }
                
            }
            else if options[indexPath.row] == "Payment" {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ToggleCell", for: indexPath) as! ToggleCell
                cell.input?.inputAccessoryView = keyboardDoneButtonView
                cell.delegate = self
                self.amountField = cell.input
                self.paymentSwitch = cell.switchToggle
                self.didToggle(cell.switchToggle, isOn: paymentRequired)
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
                    
                    if let type = type, let index = self.eventTypes.firstIndex(of: type) {
                        if eventTypes[index] == .other {
                            typeField!.text = "Select event type"
                        } else {
                            typeField!.text = eventTypes[index].rawValue
                        }
                    }
                case "Day":
                    self.dayField = cell.valueTextField
                    self.dayField?.inputView = self.datePickerView
                    cell.valueTextField.inputAccessoryView = self.keyboardDoneButtonView
                    if let date = date {
                        self.dayField?.text = date.dateStringForPicker()
                    }
                case "Start Time":
                    self.startField = cell.valueTextField
                    self.startField?.inputView = self.startTimePickerView
                    cell.valueTextField.inputAccessoryView = self.keyboardDoneButtonView
                    if let date = startTime {
                        self.startField?.text = date.timeStringForPicker()
                    }
                case "End Time":
                    self.endField = cell.valueTextField
                    self.endField?.inputView = self.endTimePickerView
                    cell.valueTextField.inputAccessoryView = self.keyboardDoneButtonView
                    if let date = endTime {
                        self.endField?.text = date.timeStringForPicker()
                    }
                case "Max Players":
                    self.maxPlayersField = cell.valueTextField
                    self.maxPlayersField?.inputView = self.numberPickerView
                    cell.valueTextField.inputAccessoryView = self.keyboardDoneButtonView2

                    if let max = maxPlayers {
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
            
            if let notes = info {
                cell.descriptionTextView.text = notes
            }

            return cell
        case Sections.cancel.rawValue:
            guard let event = eventToEdit, let cell = tableView.dequeueReusableCell(withIdentifier: "CancelEventCell", for: indexPath) as? CancelEventCell else { return UITableViewCell() }
            cell.configure(event)
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "detailCell", for: indexPath)
            return cell
            
        }

    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel(frame: CGRect(x: 16, y: 0, width: self.view.frame.size.width - 16, height: 40))
        let view = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 40))
        view.backgroundColor = UIColor.mediumGreen
        label.backgroundColor = UIColor.clear
        label.font = UIFont.montserratMedium(size: 18)
        label.textColor = UIColor.offWhite
        view.clipsToBounds = true

        switch section {
        case Sections.photo.rawValue:
            return photoHeaderView
        case Sections.details.rawValue:
            label.text = "Details"
        case Sections.notes.rawValue:
            label.text = "Description"
        case Sections.cancel.rawValue:
            view.backgroundColor = .white
            label.text = ""
        default:
            return nil;
        }
        view.addSubview(label)
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == Sections.photo.rawValue {
            return 100
        }
        if section == Sections.cancel.rawValue {
            return 0.1
        }
        return 40
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case Sections.photo.rawValue:
            let alert = UIAlertController(title: "Select image", message: nil, preferredStyle: .actionSheet)
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action) in
                    self.selectPhoto(camera: true)
                }))
            }
            alert.addAction(UIAlertAction(title: "Photo album", style: .default, handler: { (action) in
                self.selectPhoto(camera: false)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            })
            
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad), let cell = self.tableView.cellForRow(at: indexPath) as? EventPhotoCell {
                alert.popoverPresentationController?.sourceView = cell
                alert.popoverPresentationController?.sourceRect = cell.imagePlus.frame
            }

            self.present(alert, animated: true, completion: nil)
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
            case "Venue":
                textField = self.placeField
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
            if textField != self.placeField {
                textField?.isUserInteractionEnabled = true
            }
            textField?.becomeFirstResponder()
            currentField = textField
            
            if options[indexPath.row] == "Venue" {
                performSegue(withIdentifier: "toLocationSearch", sender: nil)
            }
        case Sections.cancel.rawValue:
            guard let event = eventToEdit else { return }

            promptForCancelDeleteEvent(event)
        default:
            break
        }
        
    }
    
    @objc func done() {
        // on button click on toolbar for day, time pickers
        self.currentField?.resignFirstResponder()
        self.updateLabel()
    }
    
    func updateLabel(){
        guard currentField != nil else { return }
        
        if (currentField == self.typeField) {
            let selectedRow = self.typePickerView.selectedRow(inComponent: 0)
            self.type = eventTypes[selectedRow]
            if eventTypes[selectedRow] == .other {
                currentField!.text = "Select event type"
            } else {
                currentField!.text = self.eventTypes[selectedRow].rawValue
            }
        } else if (currentField == self.maxPlayersField) { //selected max players
            self.maxPlayers = UInt(self.pickerView(self.numberPickerView, titleForRow: self.numberPickerView.selectedRow(inComponent: 0), forComponent: 0)!)
            if let maxPlayers = self.maxPlayers {
                currentField!.text = "\(maxPlayers)"
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
            if let eventToEdit = eventToEdit {
                // TODO: replace with event.venue
                let venue = Venue(eventToEdit.place, nil, eventToEdit.city, eventToEdit.state, eventToEdit.lat, eventToEdit.lon)
                controller.currentVenue = venue
            }
        }
    }
}

// MARK: Delete
extension CreateEventViewController {
    private func promptForCancelDeleteEvent(_ event: Balizinha.Event) {
        let viewModel = CancelEventViewModel(event: event)
        let title = "Event options"
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: viewModel.cancelOptionText, style: .default) { [weak self] (action) in
            self?.doCancel(event)
        })
        alert.addAction(UIAlertAction(title: viewModel.deleteOptionText, style: .default) { [weak self] (action) in
            self?.doDelete(event)
        })
        alert.addAction(UIAlertAction(title: "Never mind", style: .cancel) { (action) in
        })
        present(alert, animated: true, completion: nil)
    }

    private func doCancel(_ event: Balizinha.Event) {
        let viewModel = CancelEventViewModel(event: event)
        let alert = UIAlertController(title: viewModel.alertTitle, message: viewModel.cancelMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: viewModel.cancelConfirmButtonText, style: .default, handler: { (action) in
            let cancel = !event.isCancelled
            self.activityOverlay.show()
            EventService.shared.cancelEvent(event, isCancelled: cancel, completion: { [weak self] (error) in
                DispatchQueue.main.async {
                    self?.activityOverlay.hide()
                    if let error = error as NSError? {
                        let title = cancel ? "cancel" : "uncancel"
                        self?.simpleAlert("Could not \(title) event", defaultMessage: nil, error: error)
                        LoggingService.shared.log(event: .CancelEvent, info: ["eventId": event.id, "cancelled": cancel, "error": error.localizedDescription])
                    } else {
                        LoggingService.shared.log(event: .CancelEvent, info: ["eventId": event.id, "cancelled": cancel])
                        self?.delegate?.eventsDidChange()
                        self?.navigationController?.dismiss(animated: true, completion: nil)
                    }
                }
            })
        }))
        alert.addAction(UIAlertAction(title: viewModel.alertCancelText, style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func doDelete(_ event: Balizinha.Event) {
        let viewModel = CancelEventViewModel(event: event)
        let alert = UIAlertController(title: viewModel.alertTitle, message: viewModel.deleteMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: viewModel.deleteConfirmButtonText, style: .default, handler: { (action) in
            self.activityOverlay.show()
            EventService.shared.deleteEvent(event) { [weak self] (error) in
                DispatchQueue.main.async {
                    self?.activityOverlay.hide()
                    if let error = error as NSError? {
                        print("Event \(event.id) delete with error \(error)")
                        let title = "Could not delete event"
                        self?.simpleAlert(title, defaultMessage: "There was an error with deletion.", error: error)
                        LoggingService.shared.log(event: .DeleteEvent, info: ["eventId": event.id, "error": error.localizedDescription])
                    } else {
                        self?.delegate?.eventsDidChange()
                        self?.navigationController?.dismiss(animated: true, completion: nil)
                        LoggingService.shared.log(event: .DeleteEvent, info: ["eventId": event.id])
                    }
                }
            }
        }))
        alert.addAction(UIAlertAction(title: viewModel.alertCancelText, style: .cancel) { (action) in
        })
        present(alert, animated: true, completion: nil)
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
            return eventTypes.count
        }
        else if pickerView == self.numberPickerView {
            return 64
        }
        return FUTURE_DAYS // datePickerView: default 3 months
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        //print("Reloaded components")
        
        if pickerView == self.typePickerView {
            if eventTypes[row] == .other {
                return "Select event type"
            }
            return eventTypes[row].rawValue
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
    
    @objc func timePickerValueChanged(_ sender:UIDatePicker) {
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
        
        if textField == amountField, let index = options.firstIndex(of: "Payment") {
            tableView.scrollToRow(at: IndexPath(row: index, section: Sections.details.rawValue), at: .top, animated: true)
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == self.nameField {
            let oldName = self.name
            self.name = textField.text
            
            // logging to track event changes
            if let event = eventToEdit, let old = oldName, let newName = textField.text {
                LoggingService.shared.log(event: .RenameEvent, info: ["oldName": old, "newName": newName, "eventId": event.id])
            }
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
            
            // logging to track event changes
            if let event = eventToEdit {
                LoggingService.shared.log(event: .ChangeEventPaymentAmount, info: ["eventId": event.id, "oldAmount": self.amount ?? 0, "newAmount": newAmount])
            }
        }
    }
    
    // MARK: -UITextViewDelegate
    func textViewDidBeginEditing(_ textView: UITextView) {
       self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: self.keyboardHeight, right: 0)
        
        let indexPath = IndexPath(row: 0, section: Sections.notes.rawValue)
        self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        self.tableView.contentInset = UIEdgeInsets.zero
        self.info = self.descriptionTextView!.text
    }
    
    // MARK - Keyboard
    @objc func keyboardWillShow(_ notification: Notification) {
        let userInfo:NSDictionary = notification.userInfo! as NSDictionary
        let keyboardFrame:NSValue = userInfo.value(forKey: UIResponder.keyboardFrameEndUserInfoKey) as! NSValue
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
}

// photo
extension CreateEventViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func selectPhoto(camera: Bool) {
        self.view.endEditing(true)
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        
        picker.view.backgroundColor = .blue
        
        if camera, UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
            picker.cameraCaptureMode = .photo
            picker.showsCameraControls = true
        } else {
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                picker.sourceType = .photoLibrary
            }
            else {
                picker.sourceType = .savedPhotosAlbum
            }
            picker.navigationBar.isTranslucent = false
            picker.navigationBar.barTintColor = UIColor.mediumBlue
        }
        
        self.present(picker, animated: true)
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }

    func didTakePhoto(image: UIImage) {
        dismissCamera {
            self.newEventImage = image
            let indexPath = IndexPath(row: 0, section: 0)
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
    
    func dismissCamera(completion: (()->Void)? = nil) {
        dismiss(animated: true, completion: completion)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let img = info[UIImagePickerController.InfoKey.editedImage] ?? info[UIImagePickerController.InfoKey.originalImage]
        guard let photo = img as? UIImage else { return }
        self.didTakePhoto(image: photo)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismissCamera()
    }
    
    func savePhoto(photo: UIImage, event: Balizinha.Event?, completion: @escaping ((_ url: String?, _ photoId: String?)->Void)) {
        let alert = UIAlertController(title: "Progress", message: "Please wait until photo uploads", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .cancel) { (action) in
        })
        self.present(alert, animated: true, completion: nil)
        
        let resized = FirebaseImageService.resizeImageForEvent(image: photo) ?? photo
        let id = event?.id ?? RenderAPIService().uniqueId()
        FirebaseImageService.uploadImage(image: resized, type: .event, uid: id, progressHandler: { (percent) in
            alert.title = "Progress: \(Int(percent*100))%"
        }, completion: { (url) in
            alert.dismiss(animated: true, completion: nil)
            completion(url, id) // returns url for photoUrl, and id for photoId
        })
    }
}

// MARK: custom weekday pickers
extension CreateEventViewController {
    func generatePickerDates() {
        guard self.datesForPicker.count == 0 else { return }
        
        for row in 0..<FUTURE_DAYS {
            let date = Date().addingTimeInterval(3600*24*TimeInterval(row))
            datesForPicker.append(date)
        }
    }
}

// MARK: ToggleCell
extension CreateEventViewController: ToggleCellDelegate {
    func didToggle(_ toggle: UISwitch, isOn: Bool) {
        paymentRequired = isOn
        self.paymentSwitch?.isOn = isOn
        self.amountField?.isEnabled = isOn
        self.amountField?.isHidden = !isOn
        if isOn {
            self.revertAmount()
        }
        
        // logging to track event changes
        if let event = eventToEdit {
            LoggingService.shared.log(event: .ToggleEventPaymentRequired, info: ["eventId": event.id, "paymentRequired": paymentRequired])
        }
    }
    
    func revertAmount() {
        self.amountField?.text = EventService.amountString(from: self.amount)
    }
}

// MARK: PlaceSearchDelegate
extension CreateEventViewController: PlaceSelectDelegate {
    func didSelect(venue: Venue?) {
        if let location = venue?.name {
            self.placeField?.text = location
        }
        else if let street = venue?.street {
            self.placeField?.text = street
        }

        self.venue = venue
        self.navigationController?.popToViewController(self, animated: true)
    }
}

//
//  DashboardViewController.swift
//  Panna
//
//  Created by Bobby Ren on 6/16/19.
//  Copyright © 2019 Bobby Ren. All rights reserved.
//

import UIKit
import Balizinha
import RxCocoa
import RxSwift

enum DashboardMenuItem: String, CaseIterable {
    // player
    case league = "League"
    case players = "Players"
    case events = "Events"
    case actions = "Actions"
//    case payments = "Payments"
//    case feed = "Feed"
}

class DashboardViewController: UIViewController {
    let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
    
    @IBOutlet weak var tableView: UITableView!
    var leaguePickerView: UIPickerView = UIPickerView()
    var pickerRow: Int = 0
    let leagueInput: UITextField = UITextField()

    private let disposeBag = DisposeBag()
    
    var league: League? {
        didSet {
            DefaultsManager.shared.setValue(league?.id, forKey: "DashboardLeagueId")
        }
    }
    var leagues: [League] = []
    let menuItems: [DashboardMenuItem] = DashboardMenuItem.allCases
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Dashboard"
        
        setupLeagueSelector()
        leagues = LeagueService.shared.ownerLeagues.sorted(by: { (l1, l2) -> Bool in
            guard let name1 = l1.name?.lowercased() else { return true }
            guard let name2 = l2.name?.lowercased() else { return false }
            return name1 < name2
        })
        
        if let leagueId = DefaultsManager.shared.value(forKey: "DashboardLeagueId") as? String {
            league = leagues.first(where: { (l) -> Bool in
                return l.id == leagueId
            })
        }
        
        if let league = league, let index = leagues.index(of: league) {
            pickerRow = index
        } else {
            selectLeague(showPrompt: true)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let nav = segue.destination as? UINavigationController, let controller = nav.viewControllers[0] as? ListViewController else { return }
        controller.league = league
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        LoggingService.shared.log(event: .DashboardTabClicked, info: nil)
    }

    private func setupLeagueSelector() {
        leaguePickerView.sizeToFit()
        leaguePickerView.backgroundColor = .white
        leaguePickerView.delegate = self
        leaguePickerView.dataSource = self
        leagueInput.inputView = leaguePickerView
        
        let keyboardNextButtonView = UIToolbar()
        keyboardNextButtonView.sizeToFit()
        keyboardNextButtonView.barStyle = UIBarStyle.black
        keyboardNextButtonView.isTranslucent = true
        keyboardNextButtonView.tintColor = UIColor.white
        let cancel: UIBarButtonItem = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.done, target: self, action: #selector(cancelInput))
        let flex: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let select: UIBarButtonItem = UIBarButtonItem(title: "Select", style: UIBarButtonItemStyle.done, target: self, action: #selector(saveInput))
        keyboardNextButtonView.setItems([cancel, flex, select], animated: true)
        leagueInput.inputAccessoryView = keyboardNextButtonView
        
        tableView.addSubview(leagueInput)
    }

    func selectLeague(showPrompt: Bool) {
        if showPrompt {
            simpleAlert("Select a league", message: "Please choose which league to view in the dashboard. You can change this later.") {
                self.leagueInput.becomeFirstResponder()
                self.leaguePickerView.selectRow(self.pickerRow, inComponent: 0, animated: false)
            }
        } else {
            leagueInput.becomeFirstResponder()
            leaguePickerView.selectRow(pickerRow, inComponent: 0, animated: false)
        }
    }
    
    @objc private func cancelInput() {
        view.endEditing(true)
    }
    
    @objc private func saveInput() {
        view.endEditing(true)
        if pickerRow < leagues.count {
            print("Picked league \(leagues[pickerRow].name)")
            league = leagues[pickerRow]
            leagueInput.resignFirstResponder()
            
            tableView.reloadData()
        }
    }
}

extension DashboardViewController: UITableViewDataSource, UITableViewDelegate {
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        if row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LeagueSelectorCell", for: indexPath)
            if let league = league {
                cell.textLabel?.text = league.name ?? "Unnamed league"
                cell.detailTextLabel?.text = "Click to switch leagues"
            } else {
                cell.textLabel?.text = "Click to select a league"
                cell.detailTextLabel?.text = nil
            }
            return cell
        } else {
            let item = menuItems[row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.textLabel?.text = item.rawValue
            cell.accessoryType = (league != nil) ? .disclosureIndicator : .none
            
            cell.textLabel?.alpha = (league != nil) ? 1.0 : 0.25
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let row = indexPath.row
        if row == 0 {
            selectLeague(showPrompt: false)
        } else {
            let option = menuItems[row]
            if league != nil {
                performSegue(withIdentifier: option.rawValue, sender: nil)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.1
    }
}

extension DashboardViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return leagues.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if row < leagues.count {
            return leagues[row].name ?? "No name"
        }
        return nil
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        pickerRow = row
    }
}

extension DashboardViewController {
    func simpleInputAlert(_ title: String, message: String?, placeholder: String?, inputView: UIView? = nil, inputAccessoryView: UIView? = nil, completion: ((String) -> Void)?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = placeholder
            if let inputView = inputView {
                textField.inputView = inputView
            }
            if let accessory = inputAccessoryView {
                textField.inputAccessoryView = accessory
            }
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            if let textField = alert.textFields?[0], let text = textField.text {
                completion?(text)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
}

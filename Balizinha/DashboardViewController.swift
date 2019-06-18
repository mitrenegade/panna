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
    case payments = "Payments"
    case feed = "Feed"
}

class DashboardViewController: UIViewController {
    let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
    
    @IBOutlet weak var tableView: UITableView!
    var leaguePickerView: UIPickerView = UIPickerView()
    var pickerRow: Int = -1
    let leagueInput: UITextField = UITextField()

    private let disposeBag = DisposeBag()
    
    var league: League?
    var leagues: [League] = []
    let menuItems: [DashboardMenuItem] = DashboardMenuItem.allCases
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Dashboard"
        
        leaguePickerView.sizeToFit()
        leaguePickerView.backgroundColor = .white
        leaguePickerView.delegate = self
        leaguePickerView.dataSource = self
        leagueInput.inputView = leaguePickerView
        tableView.addSubview(leagueInput)
        
        leagues = LeagueService.shared.ownerLeagues
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let controller = segue.destination as? ListViewController else { return }
        controller.league = league
    }
    
    func promptForLeague() {
        leagueInput.becomeFirstResponder()
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
        self.tableView.deselectRow(at: indexPath, animated: true)
        
        let row = indexPath.row
        if row == 0 {
            promptForLeague()
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
        if row < leagues.count {
            print("Picked league \(leagues[row].name)")
            league = leagues[row]
            leagueInput.resignFirstResponder()
            
            tableView.reloadData()
        }
    }
}

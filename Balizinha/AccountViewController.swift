//
//  AccountViewController.swift
//  Balizinha
//
//  Created by Tom Strissel on 5/19/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import FBSDKLoginKit

class AccountViewController: UITableViewController {
    
    var menuOptions: [String]!
    var service = EventService.shared
    var paymentCell: PaymentCell?

    override func viewDidLoad() {
        super.viewDidLoad()

        menuOptions = ["Edit profile", "Push notifications", "Payment options", "Promo program", "Version", "Use my location", "Logout"]
        if !SettingsService.paymentRequired() {
            menuOptions = menuOptions.filter({$0 != "Promo program"})
        }
        if !SettingsService.donation() && !SettingsService.paymentRequired() {
            menuOptions = menuOptions.filter({$0 != "Payment options"})
        }
        if !SettingsService.paymentLocationTestGroup() {
            menuOptions = menuOptions.filter({$0 != "Payment options"})
        }
        
        self.navigationItem.title = "Account"
        listenFor(NotificationType.LocationOptionsChanged, action: #selector(self.reloadTableData), object: nil)
    }

    func reloadTableData() {
        tableView.reloadData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuOptions.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        switch menuOptions[indexPath.row] {
        case "Push notifications":
            let cell : PushTableViewCell = tableView.dequeueReusableCell(withIdentifier: "push", for: indexPath) as! PushTableViewCell
            cell.delegate = self
            cell.labelText.text = menuOptions[indexPath.row]
            cell.selectionStyle = .none
            cell.accessoryType = .none
            cell.configure()
            return cell
            
        case "Edit profile", "Logout":
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.textLabel?.text = menuOptions[indexPath.row]
            cell.accessoryType = .none
            return cell
            
        case "Version":
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
            cell.textLabel?.text = "Version: \(version ?? "unknown") (\(build ?? "unknown"))\(TESTING ? "t" : "")"
            cell.accessoryType = .none
            return cell
            
        case "Bundle":
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            let bundle = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String
            cell.textLabel?.text = "Bundle id: \(bundle ?? "unknown")"
            cell.accessoryType = .none
            return cell
            
        case "Promo program":
            let cell = tableView.dequeueReusableCell(withIdentifier: "PromoCell", for: indexPath) as! PromoCell
            cell.configure()
            return cell
            
        case "Payment options":
            if let cell = tableView.dequeueReusableCell(withIdentifier: "PaymentCell", for: indexPath) as? PaymentCell {
                self.paymentCell = cell
                cell.configure(host: self)
                return cell
            }
            else {
                return UITableViewCell()
            }
            
        case "Use my location":
            let cell = tableView.dequeueReusableCell(withIdentifier: "LocationSettingCell", for: indexPath) as! LocationSettingCell
            cell.configure()
            cell.labelText.text = menuOptions[indexPath.row]
            cell.delegate = self
            return cell

        default:
            return UITableViewCell()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
       
        switch menuOptions[indexPath.row] {
        case "Edit profile":
            self.performSegue(withIdentifier: "ToEditPlayerInfo", sender: nil)
        case "Push notifications":
            break
        case "Logout":
            self.logout()
        case "Promo program":
            guard let player = PlayerService.shared.current else { return }
            if let promoId = player.promotionId {
                PromotionService.shared.withId(id: promoId) { (promo, error) in
                    if let promo = promo, promo.active {
                        return
                    }
                    else {
                        self.addPromotion()
                    }
                }
            }
            else {
                self.addPromotion()
            }
        case "Payment options":
            self.paymentCell?.shouldShowPaymentController()
        default:
            break
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ToEditPlayerInfo" {
            if let nav = segue.destination as? UINavigationController, let controller = nav.viewControllers[0] as? PlayerInfoViewController {
                controller.player = PlayerService.shared.current
                controller.isCreatingPlayer = false
            }
        }
    }
    
    private func logout() {
        try! firAuth.signOut()
        EventService.resetOnLogout() // force new listeners
        PlayerService.resetOnLogout()
        OrganizerService.resetOnLogout()
        FBSDKLoginManager().logOut()
        self.notify(.LogoutSuccess, object: nil, userInfo: nil)
    }
    
    // MARK: - Promotions
    func addPromotion() {
        guard let current = PlayerService.shared.current else { return }
        let alert = UIAlertController(title: "Please enter a promo code", message: nil, preferredStyle: .alert)
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Promo code"
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] (action) in
            if let textField = alert.textFields?[0], let promo = textField.text {
                print("Using promo code \(promo)")
                PromotionService.shared.withId(id: promo, completion: { [weak self] (promotion, error) in
                    if let promotion = promotion {
                        print("\(promotion)")
                        current.promotionId = promotion.id
                        self?.tableView.reloadData()
                        LoggingService.shared.log(event: LoggingEvent.AddPromoCode, message: "success", info: ["code":promo], error: nil)
                    }
                    else {
                        self?.simpleAlert("Invalid promo code", message: "The promo code \(promo) seems to be invalid.")
                        LoggingService.shared.log(event: LoggingEvent.AddPromoCode, message: "invalid", info: ["code":promo], error: error)
                    }
                })
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
}

extension AccountViewController: ToggleCellDelegate {
    func didToggle(_ toggle: UISwitch, isOn: Bool) {
        let isOn = toggle.isOn
        print("Switch changed to \(isOn)")

        if toggle.superview?.superview is PushTableViewCell {
            if #available(iOS 10.0, *) {
                NotificationService.shared.toggleUserReceivesNotifications(isOn)
            }
        } else if toggle.superview?.superview is LocationSettingCell {
            LocationService.shared.shouldFilterNearbyEvents = isOn
            if #available(iOS 10.0, *) {
                NotificationService.shared.notify(NotificationType.EventsChanged, object: nil, userInfo: nil)
            } else {
                // Fallback on earlier versions
            }
            
            if isOn {
                LocationService.shared.startLocation(from: self)
            }
        }
    }
}

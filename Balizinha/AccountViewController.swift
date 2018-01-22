//
//  AccountViewController.swift
//  Balizinha
//
//  Created by Tom Strissel on 5/19/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import FBSDKLoginKit

class AccountViewController: UIViewController {
    
    var menuOptions: [String]!
    var service = EventService.shared
    var paymentCell: PaymentCell?
    
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        menuOptions = ["Edit profile", "Payment options", "Promo program", "Organizer options", "Push notifications", "Use my location", "Version", "Logout"]
        if !SettingsService.paymentRequired() {
            menuOptions = menuOptions.filter({$0 != "Promo program"})
        }
        if !SettingsService.donation() && !SettingsService.paymentRequired() {
            menuOptions = menuOptions.filter({$0 != "Payment options"})
        }
        if !SettingsService.paymentLocationTestGroup() {
            menuOptions = menuOptions.filter({$0 != "Payment options"})
        }
        
        navigationItem.title = "Account"
        listenFor(NotificationType.LocationOptionsChanged, action: #selector(self.reloadTableData), object: nil)
    }

    func reloadTableData() {
        tableView.reloadData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
        print("LoginLogout: logout called, trying firAuth.signout")
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

extension AccountViewController: UITableViewDataSource, UITableViewDelegate {
    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuOptions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

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
            
        case "Organizer options":
            if let cell = tableView.dequeueReusableCell(withIdentifier: "OrganizerCell", for: indexPath) as? OrganizerCell {
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
        case "Organizer options":
            let viewModel = OrganizerCellViewModel()
            if viewModel.canClick {
                print("Clicked on organizer cell")
            }
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.1
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
            self.notify(NotificationType.EventsChanged, object: nil, userInfo: nil)

            if isOn {
                LocationService.shared.startLocation(from: self)
            }
        }
    }
}

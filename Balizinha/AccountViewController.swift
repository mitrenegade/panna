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
    let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)

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
        if !SettingsService.organizerPaymentRequired() {
            menuOptions = menuOptions.filter({$0 != "Organizer options"})
        }
        
        navigationItem.title = "Account"
        listenFor(NotificationType.LocationOptionsChanged, action: #selector(self.reloadTableData), object: nil)
        
        activityIndicator.hidesWhenStopped = true
        activityIndicator.center = view.center
        view.addSubview(activityIndicator)
        activityIndicator.color = UIColor.red
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
            AuthService.shared.logout()
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
                if OrganizerService.shared.current == nil || OrganizerService.shared.current?.status == OrganizerStatus.none {
                    // click to join
                    OrganizerService.shared.requestOrganizerAccess() { (organizer, error) in
                        // do nothing, let organizer observer update the cell
                    }
                } else if OrganizerService.shared.current?.status == .approved {
                    // add payment
                    payForOrganizerService()
                }
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

// Organizer service stuff
extension AccountViewController {
    func payForOrganizerService() {
        guard let organizer = OrganizerService.shared.current else {
            self.simpleAlert("Could not become organizer", message: "There was an issue joining as an organizer. No organizer found")
            LoggingService.shared.log(event: LoggingEvent.OrganizerSignupPrompt, info: ["success": false, "error": "There was an issue joining as an organizer. No organizer found"])
            return
        }
        guard SettingsService.organizerPaymentRequired() else {
            organizer.status = .active
            return
        }

        // create organizer
        let isTrial: Bool = SettingsService.organizerTrialAvailable()
        let message = isTrial ? "You have been approved to become an organizer. Click now to start a month long free trial." : "You have been approved to become an organizer. Click now to purchase an organizer subscription."
        
        let alert = UIAlertController(title: "Become an Organizer?", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { action in
            LoggingService.shared.log(event: LoggingEvent.OrganizerSignupPrompt, info: ["success": false, "reason": "cancelled"])
        }))
        alert.addAction(UIAlertAction(title: "Start", style: UIAlertActionStyle.default, handler: { [weak self] (action) in
            
            // TODO: check for payment method before creating an organizer?
            self?.activityIndicator.startAnimating()
            // go directly to create event without payments and no alert
            
            StripeService.shared.createSubscription(isTrial: isTrial, completion: { [weak self] (success, error) in
                self?.activityIndicator.stopAnimating()
                print("Success \(success) error \(error)")
                var title: String = isTrial ? "Free trial started" : "Subscription created"
                var message: String = isTrial ? "Good luck organizing games! You are now in the 30 day organizer trial." : "Good luck organizing games!"
                if let error = error as? NSError {
                    // TODO: handle credit card payment after organizer was created!
                    // should allow users to organize for now, and ask to add a payment later
                    // should stop allowing it once their trial is up
                    if error.code == 1001 {
                        // self generated error: no payment source
                        title = "Payment needed"
                        message = "Please add a payment in order to become an organizer."
                    } else {
                        title = "Could create subscription"
                        message = "We could not charge your card."
                    }
                    
                    LoggingService.shared.log(event: LoggingEvent.OrganizerSignupPrompt, info: ["success": false, "error": error.localizedDescription])
                    
                    if let deadline = error.userInfo["deadline"] as? Double{
                        OrganizerService.shared.current?.deadline = deadline
                    }
                } else {
                    let newStatus: OrganizerStatus = isTrial ? .trial : .active
                    LoggingService.shared.log(event: LoggingEvent.OrganizerSignupPrompt, info: ["success": true, "newStatus": newStatus.rawValue])
                    OrganizerService.shared.current?.status = newStatus
                }

                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action) in
                }))
                self?.present(alert, animated: true, completion: nil)
            })
        }))
        navigationController?.present(alert, animated: true, completion: nil)
    }
}

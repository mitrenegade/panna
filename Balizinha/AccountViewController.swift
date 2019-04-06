//
//  AccountViewController.swift
//  Balizinha
//
//  Created by Tom Strissel on 5/19/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import Balizinha
import RenderPay
import RenderCloud
import RxSwift
import RxCocoa

class AccountViewController: UIViewController {
    
    enum MenuSection: String {
        case player = "Player"
        case options = "Options"
        case owner = "League Owner"
        case app = "App"
    }
    
    enum MenuItem: String {
        // player
        case profile = "Edit profile"
        case payment = "Payment options"

        // options
        case promo = "Promo program"
        case notifications = "Push notifications"
        case location = "Use my location"

        // owner
        case stripe = "Stripe account"
        case subscriptions = "Subscriptions"
        
        // app
        case feedback = "Feedback"
        case about = "About Panna"
        case logout = "Logout"
    }
    
    var menuSections: [MenuSection] = [.player, .options, .app]
    var menuOptions: [MenuSection: [MenuItem]] = [ .player: [.profile, .payment],
                                                   .options: [.promo, .notifications, .location],
                                                   .app: [.feedback, .about, .logout]]

    var service = EventService.shared
    weak var paymentCell: PaymentCell?
    let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)

    @IBOutlet weak var tableView: UITableView!
    
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        menuSections = [.player, .options, .app]
        if !SettingsService.paymentRequired() {
            removeMenuOption(.payment)
        }

        navigationItem.title = "Account"
        listenFor(NotificationType.LocationOptionsChanged, action: #selector(self.reloadTableData), object: nil)
        
        activityIndicator.hidesWhenStopped = true
        activityIndicator.center = view.center
        view.addSubview(activityIndicator)
        activityIndicator.color = UIColor.red
    }
    
    private func removeMenuOption(_ option: MenuItem) {
        for var (section, menuItems) in menuOptions {
            if let index = menuItems.firstIndex(of: option) {
                menuItems.remove(at: index)
                menuOptions[section] = menuItems
                return
            }
        }
    }

    @objc func reloadTableData() {
        tableView.reloadData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ToEditPlayerInfo" {
            if let controller = segue.destination as? PlayerInfoViewController {
                controller.player = PlayerService.shared.current.value
                controller.isCreatingPlayer = false
            }
        }
    }

    // MARK: - Promotions
    func addPromotion() {
        guard let current = PlayerService.shared.current.value else { return }
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // came here from a deeplink; handle any other destination
        if let accountDestination: DeeplinkType.AccountActions = DeepLinkService.shared.accountDestination {
            DeepLinkService.shared.clearDestinations()
            switch accountDestination {
            case .profile:
                performSegue(withIdentifier: "ToEditPlayerInfo", sender: nil)
            case .payments:
                paymentCell?.shouldShowPaymentController()
            }
        }
    }
    
    func showAboutOptions() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] ?? ""
        let buildString = TESTING ? ( "(\(build))t" ) : ""
        let versionText = "Version: \(version ?? "unknown") \(buildString)"
        let alert = UIAlertController(title: "About Panna", message: versionText, preferredStyle: .alert)
        if let url = URL(string: SettingsService.websiteUrl) {
            alert.addAction(UIAlertAction(title: "View website", style: .cancel, handler: { (action) in
                LoggingService.shared.log(event: .WebsiteViewedFromAbout, info: nil)
                UIApplication.shared.open(url)
            }))
        }
        alert.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
        navigationController?.present(alert, animated: true, completion: nil)
        
    }
}

extension AccountViewController: UITableViewDataSource, UITableViewDelegate {
    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return menuSections.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section < menuSections.count else { return nil }
        if menuSections[section] == .owner {
            if case .account = Globals.stripeConnectService.accountState.value {
                return menuSections[section].rawValue
            } else {
                return nil
            }
        }
        return menuSections[section].rawValue
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < menuSections.count else { return 0 }
        guard let options = menuOptions[menuSections[section]] else { return 0}
        if menuSections[section] == .owner {
            if case .account = Globals.stripeConnectService.accountState.value {
                return options.count
            } else {
                return 0
            }
        }
        return options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let section = menuSections[indexPath.section]
        guard let option = menuOptions[section]?[row] else { return UITableViewCell() }
        switch option {
        case .notifications:
            let cell : PushTableViewCell = tableView.dequeueReusableCell(withIdentifier: "push", for: indexPath) as! PushTableViewCell
            cell.delegate = self
            cell.labelText.text = option.rawValue
            cell.selectionStyle = .none
            cell.accessoryType = .none
            cell.configure()
            return cell
            
        case .profile, .about, .feedback, .stripe, .subscriptions, .logout:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.textLabel?.text = option.rawValue
            cell.accessoryType = .disclosureIndicator
            return cell
            
        case .promo:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PromoCell", for: indexPath) as! PromoCell
            cell.configure()
            return cell
            
        case .payment:
            if let cell = tableView.dequeueReusableCell(withIdentifier: "PaymentCell", for: indexPath) as? PaymentCell {
                cell.hostController = self
                paymentCell = cell
                return cell
            }
            else {
                return UITableViewCell()
            }
            
        case .location:
            let cell = tableView.dequeueReusableCell(withIdentifier: "LocationSettingCell", for: indexPath) as! LocationSettingCell
            cell.configure()
            cell.labelText.text = option.rawValue
            cell.selectionStyle = .none
            cell.delegate = self
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
       
        let row = indexPath.row
        let section = menuSections[indexPath.section]
        guard let option = menuOptions[section]?[row] else { return }
        switch option {
        case .profile:
            self.performSegue(withIdentifier: "ToEditPlayerInfo", sender: nil)
        case .notifications:
            if NotificationService.shared.pushRequestFailed {
                simpleAlert("Push not enabled", message: "In order to get notifications about events, please go to Settings and enable push.")
            }
            break
        case .logout:
            AuthService.shared.logout()
        case .promo:
            guard let player = PlayerService.shared.current.value else { return }
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
        case .payment:
            paymentCell?.shouldShowPaymentController()
        case .location:
            return
        case .about:
            showAboutOptions()
        case .feedback:
            performSegue(withIdentifier: "toFeedback", sender: nil)
        case .stripe:
            performSegue(withIdentifier: "toStripe", sender: nil)
        case .subscriptions:
            performSegue(withIdentifier: "toSubscriptions", sender: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.1
    }
}

extension AccountViewController: ToggleCellDelegate {
    func didToggle(_ toggle: UISwitch, isOn: Bool) {
        print("Switch changed to \(isOn)")

        if toggle.superview?.superview is PushTableViewCell {
            NotificationService.shared.toggleUserReceivesNotifications(isOn) { [weak self] error in
                DispatchQueue.main.async { [weak self] in
                    if let error = error as NSError? {
                        self?.simpleAlert("Notification update error", defaultMessage: "Your notification settings were not updated.", error: error)
                        self?.tableView.reloadData()
                    } else {
                        PlayerService.shared.refreshCurrentPlayer() // update notification setting on player
                    }
                }
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


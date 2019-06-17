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

class DashboardViewController: UIViewController {
    let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
    
    @IBOutlet weak var tableView: UITableView!
    
    private let disposeBag = DisposeBag()

    enum MenuItem: String, CaseIterable {
        // player
        case players = "Players"
        case games = "Games"
        case actions = "Actions"
        case payments = "Payments"
        case feed = "Feed"
    }
    
    let menuItems: [MenuItem] = MenuItem.allCases
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
        let item = menuItems[row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = item.rawValue
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        
        let row = indexPath.row
        let option = menuItems[row]
        self.performSegue(withIdentifier: option.rawValue, sender: nil)
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.1
    }
}

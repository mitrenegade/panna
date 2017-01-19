//
//  MenuTableViewController.swift
//  LotSportz
//
//  Created by Tom Strissel on 5/17/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit

class MenuTableViewController: UITableViewController {
    
    var MENU_LIST : [String] = ["My Events","Join events", "Create event", "Settings"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation helpers
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toCreateEvent" {
            // add a reference to menuTableViewController to navigate back
            let nav: UINavigationController = segue.destination as! UINavigationController
            let controller: CreateEventViewController = nav.viewControllers[0] as! CreateEventViewController
            controller.menuController = self
        }
    }
    
    func goToMyEvents() {
        self.performSegue(withIdentifier: "toMyEvents", sender: self)
    }

    func goToJoinEvents() {
        self.performSegue(withIdentifier: "toJoinEvents", sender: self)
    }

    func goToCreateEvent() {
        self.performSegue(withIdentifier: "toCreateEvent", sender: self)
    }

    func goToSettings() {
        self.performSegue(withIdentifier: "toSettings", sender: self)
    }

    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section{
        case 0:
            return 1
        case 1:
            return MENU_LIST.count
        default:
            return 0
        }
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Configure the cell...
        let row = indexPath.row
        let section = indexPath.section
        
        switch section
        {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "option", for: indexPath)
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            
            let logo : UIImageView = UIImageView(image: UIImage(named: "lotsports_logo_white"))
            logo.frame = CGRect(x: cell.contentView.bounds.size.width/5.5, y: cell.contentView.bounds.size.height/4, width: 150, height: 70)
            
            cell.addSubview(logo)
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "option", for: indexPath)
            cell.textLabel?.textColor = UIColor.white
            switch row
            {
            case 0...4: //My Events
                cell.textLabel?.text = MENU_LIST[row]
                return cell
            default:
                break
            }
        default:
            break
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "option", for: indexPath)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Configure the cell...
        let row = indexPath.row
        let section = indexPath.section
        
        switch section{
        case 1:
            switch row
            {
            case 0: //My Events
                self.performSegue(withIdentifier: "toMyEvents", sender: self)
            case 1:
                self.performSegue(withIdentifier: "toJoinEvents", sender: self)
            case 2:
                self.performSegue(withIdentifier: "toCreateEvent", sender: self)
            case 3:
                self.performSegue(withIdentifier: "toSettings", sender: self)
            default:
                break
            }
        default:
            break
        }
        
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 150.0
        default:
            return 60.0
        }
    }
    
    
}

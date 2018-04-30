//
//  LeaguesViewController.swift
//  Balizinha
//
//  Created by Ren, Bobby on 4/30/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit

class LeaguesViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let profileButton = UIBarButtonItem(image: UIImage(named: "menu"), style: .done, target: self, action: #selector(didClickProfile(_:)))
        navigationItem.leftBarButtonItem = profileButton
    }
    
    @objc fileprivate func didClickProfile(_ sender: Any) {
        print("Go to Account")
        guard let controller = UIStoryboard(name: "Account", bundle: nil).instantiateViewController(withIdentifier: "AccountViewController") as? AccountViewController else { return }
        let nav = UINavigationController(rootViewController: controller)
        controller.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "iconClose30"), style: .plain, target: self, action: #selector(self.dismissProfile))
        present(nav, animated: true) {
        }
    }
    
    @objc fileprivate func dismissProfile() {
        dismiss(animated: true, completion: nil)
    }
}

extension LeaguesViewController: UITableViewDataSource {
    fileprivate func reloadTableData() {
        tableView.reloadData()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        guard let workout = workoutForIndexPath(indexPath: indexPath) else {
            return UITableViewCell()
//        }
//
//        let cell = tableView.dequeueReusableCell(withIdentifier: "WorkoutTypeCell") as! WorkoutTypeCell
//        let selected = indexPath == selectedIndexPath
//        cell.setup(type: workout, selected: selected)
//        cell.setSelected(selected, animated: true)
//        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 65
    }
}

extension LeaguesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
}

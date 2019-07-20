//
//  ListViewController.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 2/12/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

import UIKit
import FirebaseCore
import Balizinha
import FirebaseDatabase
import RenderCloud

typealias Section = (name: String, objects: [FirebaseBaseModel])
class ListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    var league: League?

    internal var refName: String {
        assertionFailure("refName ust be implemented by subclass")
        return ""
    }
    internal var baseRef: Reference {
        return firRef
    }
    var objects: [FirebaseBaseModel] = []
    var sections: [Section] {
        return [("All", objects)]
    }

    let activityOverlay: ActivityIndicatorOverlay = ActivityIndicatorOverlay()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44
        
        view.addSubview(activityOverlay)

        if let nav = self.navigationController, nav.viewControllers[0] == self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(didClickCancel(_:)))
        }        
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        activityOverlay.setup(frame: view.frame)
    }

    @objc var cellIdentifier: String {
        assertionFailure("cellIdentifier must be implemented by subclass")
        return ""
    }

    @objc func didClickCancel(_ sender: AnyObject?) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }

    func load(completion:(()->Void)? = nil) {
        let ref: Query
        ref = baseRef.child(path: refName).queryOrdered(by: "createdAt")
        ref.observeSingleValue() {[weak self] (snapshot) in
            guard snapshot.exists() else { return }
            if let allObjects = snapshot.allChildren {
                self?.objects.removeAll()
                for dict: Snapshot in allObjects {
                    if let object = self?.createObject(from: dict) {
                        self?.objects.append(object)
                    }
                }
                self?.objects.sort(by: { (p1, p2) -> Bool in
                    guard let t1 = p1.createdAt else { return false }
                    guard let t2 = p2.createdAt else { return true}
                    return t1 > t2
                })

                if let completion = completion {
                    completion()
                } else {
                    self?.reloadTable()
                }
            } else {
                completion?()
            }
        }
    }
    
    func reloadTable() {
        tableView.reloadData()
    }
    
    func createObject(from snapshot: Snapshot) -> FirebaseBaseModel? {
        return FirebaseBaseModel(snapshot: snapshot)
    }
}

extension ListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}

extension ListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

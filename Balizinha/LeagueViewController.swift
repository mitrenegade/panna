//
//  LeagueViewController.swift
//  Balizinha
//
//  Created by Bobby Ren on 6/24/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit

class LeagueViewController: UIViewController {
    fileprivate enum Row { // TODO: make CaseIterable
        case title
        case tags
    }
    
    fileprivate var rows: [Row] = [.title, .tags]
    
    @IBOutlet weak var tableView: UITableView!
    var tagView: ResizableTagView?

    var league: League?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
}

extension LeagueViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch rows[indexPath.row] {
        case .title:
//            return tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath) as! EventCell
            return UITableViewCell()
        case .tags:
            return UITableViewCell()
        }
    }
}

extension LeagueViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

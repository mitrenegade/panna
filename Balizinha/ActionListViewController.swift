//
//  ActionListViewController.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 2/3/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

import UIKit
import Balizinha
import FirebaseCore
import FirebaseDatabase
import RenderCloud

class ActionListViewController: ListViewController, LeagueList {
    var league: League?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        navigationItem.title = "Activity"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(didClickCancel(_:)))

        loadMore()

        let info: [String: Any] = ["leagueId": league?.id ?? ""]
        LoggingService.shared.log(event: .DashboardViewLeagueActions, info: info)
    }
    
    override func load(completion:(()->Void)? = nil) {
        guard let league = league else { return }
        var lastKey: String? = nil
        // stored order is in ascending key/timestamp
        if let feedItem = self.objects.last as? FeedItem {
            lastKey = feedItem.id
        }
        FeedService.shared.loadFeedItems(for: league, lastKey: lastKey, pageSize: 3) { [weak self] feedItemIds in
            let group = DispatchGroup()
            
            var newFeedItems = [FeedItem]()
            for id in feedItemIds {
                if id == lastKey {
                    continue
                }
                group.enter()
                FeedService.shared.withId(id: id) { (feedItem) in
                    if let feedItem = feedItem as? FeedItem {
                        newFeedItems.append(feedItem)
                    }
                    group.leave()
                }
            }
            group.notify(queue: DispatchQueue.main) { [weak self] in
                newFeedItems = newFeedItems.sorted(by: { (item0, item1) -> Bool in
                    guard let date0 = item0.createdAt else { return true }
                    guard let date1 = item1.createdAt else { return false }
                    return date0 < date1
                })
                if lastKey == nil {
                    self?.objects = newFeedItems
                } else {
                    self?.objects.append(contentsOf: newFeedItems)
                }
                completion?()
            }
        }
    }
    
    private func loadMore() {
        activityOverlay.show()
        load() { [weak self] in
            self?.reloadTable()
            self?.activityOverlay.hide()
        }
    }
}

extension ActionListViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count + 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // this uses a feedItemActionCell to display an action so that its eventName can be shown
        if indexPath.row < objects.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "FeedItemActionCell", for: indexPath) as! FeedItemCell
            let reverseOrderIndex = objects.count - indexPath.row - 1
            if let feedItem = objects[reverseOrderIndex] as? FeedItem {
                cell.configure(with: feedItem)
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LoadMoreCell", for: indexPath)
            return cell
        }
    }
}

extension ActionListViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < self.objects.count else {
            loadMore()
            return
        }
        guard let action = objects[indexPath.row] as? Action, let eventId = action.eventId else { return }
        print("Retrieving results for action \(action.id) with event \(eventId)")
        EventService().actions(for: nil, eventId: eventId) { (actions) in
            print("done")
        }
    }
}

extension ActionListViewController {
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard indexPath.section == 0 else { return }
        let row = indexPath.row
        guard row < objects.count else { return }
        if let action = objects[row] as? Action {
            ActionService.delete(action: action)
            tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
        }
    }
}

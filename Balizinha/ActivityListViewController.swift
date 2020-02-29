//
//  ActivityListViewController.swift
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

class ActivityListViewController: ListViewController, LeagueList {
    private let pageSize: UInt = 21
    private var beginningReached: Bool = false
    var league: League?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        navigationItem.title = "Activity"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(didClickCancel(_:)))

        loadCached()
        loadMore()

        let info: [String: Any] = ["leagueId": league?.id ?? ""]
        LoggingService.shared.log(event: .DashboardViewLeagueActions, info: info)
    }
    
    override func load(completion:(()->Void)? = nil) {
        guard let league = league else { return }
        var lastKey: String? = nil
        // stored order is in descending key/timestamp
        if let feedItem = self.objects.last as? FeedItem {
            lastKey = feedItem.id
        }
        FeedService.shared.loadFeedItems(for: league, lastKey: lastKey, pageSize: pageSize) { [weak self] feedItemIds in
            let group = DispatchGroup()
            
            var newFeedItems = [FeedItem]()
            var processingCount = 0
            for id in feedItemIds {
                if id == lastKey {
                    continue
                }
                processingCount += 1
                group.enter()
                FeedService.shared.withId(id: id) { (feedItem) in
                    if let feedItem = feedItem as? FeedItem {
                        newFeedItems.append(feedItem)
                    }
                    group.leave()
                }
            }
            guard processingCount > 0 else {
                self?.beginningReached = true
                completion?()
                return
            }

            group.notify(queue: DispatchQueue.main) { [weak self] in
                // sort in descending order
                guard let self = self else { return }
                newFeedItems = newFeedItems.sorted(by: self.sortFunc)
                if lastKey == nil {
                    self.objects = newFeedItems
                } else {
                    self.objects.append(contentsOf: newFeedItems)
                }
                completion?()
            }
        }
    }
    
    private let sortFunc: ((FeedItem, FeedItem) -> Bool) = { item0, item1 in
        guard let date0 = item0.createdAt else { return false }
        guard let date1 = item1.createdAt else { return true }
        return date0 > date1
    }
    
    private func loadCached() {
        guard let league = league else { return }
        let items = FeedService.shared.feedItemsForLeague(league.id).sorted(by: self.sortFunc)
        self.objects = items
    }
    
    private func loadMore() {
        activityOverlay.show()
        load() { [weak self] in
            self?.reloadTable()
            self?.activityOverlay.hide()
        }
    }
}

extension ActivityListViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count + 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // this uses a feedItemActionCell to display an action so that its eventName can be shown
        if indexPath.row < objects.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "FeedItemActionCell", for: indexPath) as! FeedItemCell
            let index = indexPath.row
            if let feedItem = objects[index] as? FeedItem {
                cell.configure(with: feedItem)
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LoadMoreCell", for: indexPath)
            if beginningReached {
                cell.textLabel?.text = "You have reached the beginning"
            } else {
                cell.textLabel?.text = "Click to load more"
            }
            return cell
        }
    }
}

extension ActivityListViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        super.tableView(tableView, didSelectRowAt: indexPath)
        guard indexPath.row < self.objects.count else {
            if !beginningReached {
                loadMore()
            }
            return
        }
        guard let action = objects[indexPath.row] as? Action, let eventId = action.eventId else { return }
        EventService().actions(for: nil, eventId: eventId) { (actions) in
            // no op
        }
    }
}

extension ActivityListViewController {
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

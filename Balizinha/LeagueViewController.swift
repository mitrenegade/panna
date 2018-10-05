//
//  LeagueViewController.swift
//  Balizinha
//
//  Created by Bobby Ren on 6/24/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit
import Balizinha
import FBSDKShareKit
import FirebaseDatabase
import Firebase

class LeagueViewController: UIViewController {
    fileprivate enum Row: CaseIterable {
        case title
        case join
        case tags
        case info
        case players
        case share
    }
    fileprivate enum Section: CaseIterable {
        case info
        case feed
    }
    
    fileprivate var rows: [Row] = Row.allCases
    fileprivate var sections: [Section] = Section.allCases
    
    @IBOutlet weak var tableView: UITableView!
    var tagView: ResizableTagView?
    
    var league: League?
    var players: [Player] = []
    var roster: [Membership]?
    
    weak var joinLeagueCell: LeagueButtonCell?
    weak var shareLeagueCell: LeagueButtonCell?
    
    fileprivate let shareService = ShareService() // must be retained by the class
    fileprivate let activityOverlay: ActivityIndicatorOverlay = ActivityIndicatorOverlay()

    // feed
    var feedItems: [FeedItem] = []
    
    @IBOutlet weak var feedInputView: UIView!
    @IBOutlet weak var buttonSend: UIButton!
    @IBOutlet weak var buttonImage: UIButton!
    @IBOutlet weak var inputMessage: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 80
        
        if league?.info.isEmpty == true, let index = rows.index(of: .info){
            rows.remove(at: index)
        }
        if let league = league {
            let viewModel = ShareLeagueButtonViewModel(league: league)
            if !viewModel.buttonEnabled, let index = rows.index(of: .share){
                rows.remove(at: index)
            }
        }

        activityOverlay.setup(frame: view.frame)
        view.addSubview(activityOverlay)
        loadRoster()
        listenFor(.PlayerLeaguesChanged, action: #selector(loadPlayerLeagues), object: nil)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(close))
        
        setupFeedInput()
        loadFeedItems()
    }
    
    @objc fileprivate func close() {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        activityOverlay.setup(frame: view.frame)
    }

    func loadRoster() {
        activityOverlay.show()

        guard let league = league else { return }
        LeagueService.shared.memberships(for: league) { [weak self] (results) in
            self?.roster = results
            self?.observePlayers()
            DispatchQueue.main.async {
                self?.activityOverlay.hide()
            }
        }
    }
    
    @objc func loadPlayerLeagues() {
        // on join or leave, update the join button and also update player roster
        LeagueService.shared.refreshPlayerLeagues { [weak self] (results) in
            DispatchQueue.main.async {
                self?.joinLeagueCell?.reset()
                self?.shareLeagueCell?.reset()
            }
        }
//        BOBBY TODO: roster is not showing correctly after user joins league
//        BOBBY TODO: leaguesViewController needs to listen and update too
        loadRoster()
    }
    
    func observePlayers() {
        DispatchQueue.main.async {
            self.activityOverlay.show()
        }
        players.removeAll()
        let dispatchGroup = DispatchGroup()
        for membership in roster ?? [] {
            let playerId = membership.playerId
            guard membership.isActive else { continue }
            dispatchGroup.enter()
            print("Loading player id \(playerId)")
            PlayerService.shared.withId(id: playerId, completion: {[weak self] (player) in
                if let player = player {
                    print("Finished player id \(playerId)")
                    self?.players.append(player)
                }
                dispatchGroup.leave()
            })
        }
        dispatchGroup.notify(queue: DispatchQueue.main) { [weak self] in
            if let index = self?.rows.index(of: .players) {
                DispatchQueue.main.async {
                    self?.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                    self?.activityOverlay.hide()
                }
            } else {
                print("BOBBYTEST here")
            }
        }
    }
    
    func loadFeedItems() {
        // use an observer so live updates can happen
        guard let league = league else { return }
        FeedService.shared.observeFeedItems(for: league) { [weak self] (feedItem) in
            print("Loaded feedItem \(feedItem.id)")
            self?.feedItems.append(feedItem)
            self?.tableView.reloadData()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toLeaguePlayers", let controller = segue.destination as? LeaguePlayersViewController {
            controller.league = league
            controller.delegate = self
            controller.roster = roster
        }
    }
}

extension FeedService {
    public func observeFeedItems(for league: League, completion: @escaping (FeedItem)->Void) {
        let queryRef = firRef.child("feedItems").queryOrdered(byChild: "leagueId").queryEqual(toValue: league.id)

        // query for feedItems
        queryRef.observe(.value, with: { (snapshot) in
            if let allObjects = snapshot.children.allObjects as? [DataSnapshot] {
                for snapshot in allObjects {
                    let feedItem = FeedItem(snapshot: snapshot)
                    completion(feedItem)
                }
            }
        })
    }
}

extension LeagueViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < sections.count else { return 0 }
        switch sections[section] {
        case .info:
            return rows.count
        case .feed:
            return feedItems.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == sections.firstIndex(of: .info) {
            switch rows[indexPath.row] {
            case .title:
                let cell = tableView.dequeueReusableCell(withIdentifier: "LeagueTitleCell", for: indexPath) as! LeagueTitleCell
                cell.selectionStyle = .none
                cell.configure(league: league)
                return cell
            case .join:
                let cell = tableView.dequeueReusableCell(withIdentifier: "JoinLeagueCell", for: indexPath) as! LeagueButtonCell
                guard let league = league else { return cell }
                cell.selectionStyle = .none
                cell.delegate = self
                let viewModel = JoinLeagueButtonViewModel(league: league)
                cell.configure(league: league, viewModel: viewModel)
                joinLeagueCell = cell
                return cell
            case .share:
                let cell = tableView.dequeueReusableCell(withIdentifier: "ShareLeagueCell", for: indexPath) as! LeagueButtonCell
                guard let league = league else { return cell }
                cell.selectionStyle = .none
                cell.delegate = self
                let viewModel = ShareLeagueButtonViewModel(league: league)
                cell.configure(league: league, viewModel: viewModel)
                shareLeagueCell = cell
                return cell
            case .tags:
                let cell = tableView.dequeueReusableCell(withIdentifier: "LeagueTagsCell", for: indexPath) as! LeagueTagsCell
                cell.configure(league: league)
                return cell
            case .info:
                let cell = tableView.dequeueReusableCell(withIdentifier: "LeagueInfoCell", for: indexPath) as! LeagueInfoCell
                cell.selectionStyle = .none
                cell.configure(league: league)
                return cell
            case .players:
                let cell = tableView.dequeueReusableCell(withIdentifier: "LeaguePlayersCell", for: indexPath) as! LeaguePlayersCell
                cell.delegate = self
                cell.handleAddPlayers = { [weak self] in
                    self?.goToAddPlayers()
                }
                cell.roster = roster
                cell.configure(players: players)
                return cell
            }
        } else if indexPath.section == sections.firstIndex(of: .feed) {
            return feedRow(for: indexPath)
        } else {
            return UITableViewCell()
        }
    }
    
    fileprivate func feedRow(for indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let index = feedItems.count - row - 1
        guard index < feedItems.count, index > 0 else { return UITableViewCell() }

        let feedItem = feedItems[index]
        let identifier: String = feedItem.hasPhoto ? "FeedItemCell" : "FeedItemPhotoCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? FeedItemCell else { return UITableViewCell() }
        cell.configure(with: feedItem)
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == sections.firstIndex(of: .feed) else { return nil }
        return feedInputView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section == sections.firstIndex(of: .feed) else { return 0 }
        return 50
    }
}

extension LeagueViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let index = rows.index(of: .tags), index == indexPath.row {
            inputTag()
        }
    }
}

extension LeagueViewController: PlayersScrollViewDelegate {
    func didSelectPlayer(player: Player) {
        guard let playerController = UIStoryboard(name: "Account", bundle: nil).instantiateViewController(withIdentifier: "PlayerViewController") as? PlayerViewController else { return }
        
        playerController.player = player
        self.navigationController?.pushViewController(playerController, animated: true)
    }
}

extension LeagueViewController: LeaguePlayersDelegate {
    func didUpdateRoster() {
        loadRoster()
    }

    func goToAddPlayers() {
        performSegue(withIdentifier: "toLeaguePlayers", sender: nil)
    }
}

extension LeagueViewController {
    func inputTag() {
        let alert = UIAlertController(title: "Add a tag", message: nil, preferredStyle: .alert)
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "i.e. awesome"
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] (action) in
            if let textField = alert.textFields?[0], let tag = textField.text {
                print("adding tag \(tag)")
                var tags = self?.league?.tags ?? []
                guard !tag.isEmpty, !tags.contains(tag) else { return }
                tags.append(tag)
                self?.league?.tags = tags
                self?.tableView.reloadData()
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
}

extension LeagueViewController: LeagueButtonCellDelegate {
    func clickedLeagueButton(_ cell: LeagueButtonCell, league: League) {
        if cell == joinLeagueCell {
            joinLeague()
        } else if cell == shareLeagueCell {
            promptForShare()
        }
    }
    
    fileprivate func joinLeague() {
        guard let league = league else { return }
        if LeagueService.shared.playerIsIn(league: league) {
            // leave league
            activityOverlay.show()
            LeagueService.shared.leave(league: league) { [weak self] (result, error) in
                print("Leave league result \(String(describing: result)) error \(String(describing: error))")
                DispatchQueue.main.async {
                    self?.activityOverlay.hide()
                    if let error = error as NSError? {
                        self?.simpleAlert("Could not leave league", defaultMessage: nil, error: error)
                    }
                    // forces cell/button to reload
                    self?.notify(.PlayerLeaguesChanged, object: nil, userInfo: nil)
                    self?.joinLeagueCell?.refresh()
                    self?.shareLeagueCell?.refresh()
                    
                    // when a user leaves a private league
                    if league.isPrivate {
                        NotificationService.shared.notify(.EventsChanged, object: nil, userInfo: nil)
                    }
                }
            }
        } else {
            // join league
            activityOverlay.show()
            LeagueService.shared.join(league: league) { [weak self] (result, error) in
                print("Join league result \(String(describing: result)) error \(String(describing: error))")
                DispatchQueue.main.async {
                    self?.activityOverlay.hide()
                    if let error = error as NSError? {
                        self?.simpleAlert("Could not join league", defaultMessage: nil, error: error)
                    }
                    // forces cell/button to reload
                    self?.notify(.PlayerLeaguesChanged, object: nil, userInfo: nil)
                    self?.joinLeagueCell?.refresh()
                    self?.shareLeagueCell?.refresh()
                    
                    // when user joins a private league
                    if league.isPrivate {
                        NotificationService.shared.notify(.EventsChanged, object: nil, userInfo: nil)
                    }
                }
            }
        }
    }
    
    func promptForShare() {
        guard ShareService.canSendText else {
            shareLeagueCell?.reset()
            return
        }

        guard let league = league else { return }
        var shareMethods: Int = 0
        if ShareService.canSendText {
            shareMethods = shareMethods + 1
        }
        if AuthService.shared.hasFacebookProvider {
            shareMethods = shareMethods + 1
        }
        
        if shareMethods == 1 {
            // don't prompt, just perform it
            if ShareService.canSendText {
                LoggingService.shared.log(event: LoggingEvent.ShareEventClicked, info: ["method": "contacts"])
                shareService.share(league: league, from: self)
            } else if AuthService.shared.hasFacebookProvider {
                LoggingService.shared.log(event: LoggingEvent.ShareEventClicked, info: ["method": "facebook"])
                self.shareService.shareToFacebook(link: league.shareLink, from: self)
            }
            shareLeagueCell?.reset()
        } else if shareMethods == 2 {
            // multiple share options are valid, so show options
            let alert = UIAlertController(title: "Invite to league", message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Send to contacts", style: .default, handler: {(action) in
                LoggingService.shared.log(event: LoggingEvent.ShareEventClicked, info: ["method": "contacts"])
                self.shareService.share(league: league, from: self)
            }))
            if AuthService.shared.hasFacebookProvider {
                alert.addAction(UIAlertAction(title: "Share to Facebook", style: .default, handler: {(action) in
                    LoggingService.shared.log(event: LoggingEvent.ShareEventClicked, info: ["method": "facebook"])
                    self.shareService.shareToFacebook(link: league.shareLink, from: self)
                }))
            }
            if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad, let cell = shareLeagueCell {
                alert.popoverPresentationController?.sourceView = cell
                alert.popoverPresentationController?.sourceRect = cell.button.frame
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true) {
                self.shareLeagueCell?.reset()
            }
        }
    }
}

extension LeagueViewController: FBSDKSharingDelegate {
    // MARK: - FBSDKSharingDelegate
    func sharerDidCancel(_ sharer: FBSDKSharing!) {
        print("User cancelled sharing.")
    }
    
    func sharer(_ sharer: FBSDKSharing!, didCompleteWithResults results: [AnyHashable: Any]!) {
        let alert = UIAlertController(title: "Success", message: "League shared!", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func sharer(_ sharer: FBSDKSharing!, didFailWithError error: Error!) {
        print("Error: \(String(describing: error))")
        simpleAlert("Could not share", defaultMessage: "League invite could not be sent at this time.", error: error as? NSError)
    }
//    this is not causing the share to dismiss
}

// MARK: - FeedItems
extension LeagueViewController {
    func setupFeedInput() {
        // setup keyboard accessories
        let keyboardDoneButtonView = UIToolbar()
        keyboardDoneButtonView.sizeToFit()
        keyboardDoneButtonView.barStyle = UIBarStyle.black
        keyboardDoneButtonView.tintColor = UIColor.white
        let sendBtn: UIBarButtonItem = UIBarButtonItem(title: "Send", style: UIBarButtonItemStyle.done, target: self, action: #selector(send))
        let clearBtn: UIBarButtonItem = UIBarButtonItem(title: "Clear", style: UIBarButtonItemStyle.done, target: self, action: #selector(clear))
        
        let flex: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        
        keyboardDoneButtonView.setItems([clearBtn, flex, sendBtn], animated: true)
        inputMessage.inputAccessoryView = keyboardDoneButtonView
        
        buttonImage.setImage(buttonImage.image(for: .normal)?.withRenderingMode(.alwaysTemplate), for: .normal)
    }
    
    @objc func send() {
        guard let text = self.inputMessage.text, !text.isEmpty else {
            self.clear()
            return
        }
        print("sending text: \(text)")
        self.clear()
        
        guard let league = self.league else { return }
        FeedService.shared.post(leagueId: league.id, message: text, image: nil) { (error) in
            print("Done with error \(error)")
        }
    }
    
    @objc func clear() {
        print("clear text")
        inputMessage.text = nil
        view.endEditing(true)
    }
    
    @IBAction fileprivate func didClickButton(_ sender: UIButton) {
        if sender == buttonSend {
            send()
        } else if sender == buttonImage {
            promptForImage()
        }
    }
    
    fileprivate func promptForImage() {
        self.view.endEditing(true)
        let alert = UIAlertController(title: "Select image", message: nil, preferredStyle: .actionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action) in
//                self.selectPhoto(camera: true)
            }))
        }
        alert.addAction(UIAlertAction(title: "Photo album", style: .default, handler: { (action) in
//            self.selectPhoto(camera: false)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { (action) in
        })
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad)
        {
            alert.popoverPresentationController?.sourceView = feedInputView
            alert.popoverPresentationController?.sourceRect = buttonImage.frame
        }
        self.present(alert, animated: true, completion: nil)

    }
}

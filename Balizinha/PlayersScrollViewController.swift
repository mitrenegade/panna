//
//  PlayersScrollViewController.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/5/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import AsyncImageView

class PlayersScrollViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var constraintContentWidth: NSLayoutConstraint!
    @IBOutlet weak var constraintContentHeight: NSLayoutConstraint!

    var event: Event?
    weak var delegate: EventDisplayComponentDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.observeUsers()
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        scrollView.addGestureRecognizer(gesture)
    }
    
    func observeUsers() {
        guard let event = self.event else { return }
        EventService.shared.observeUsers(forEvent: event) { (ids) in
            for id: String in ids {
                PlayerService.shared.withId(id: id, completion: { (player) in
                    if let player = player {
                        self.addPlayer(player: player)
                    }
                })
            }
        }
    }
    
    fileprivate var icons: [String: PlayerIcon] = [:]
    func addPlayer(player: Player) {
        guard icons[player.id] == nil else { return }
        let icon = PlayerIcon()
        icon.player = player
        icons[player.id] = icon
        self.refresh()
    }
    
    private var borderWidth: CGFloat = 5
    private var cellPadding: CGFloat = 5

    func refresh() {
        // TODO: this does not refresh correctly when a user leaves
        var x: CGFloat = borderWidth
        var y: CGFloat = borderWidth
        var height: CGFloat = 0
        scrollView.subviews.forEach() { $0.removeFromSuperview() }
        for (id, icon) in icons {
            let view = icon.view!
            let frame = CGRect(x: x, y: y, width: iconSize, height: iconSize)
            view.frame = frame
            scrollView.addSubview(view)
            x += view.frame.size.width + cellPadding
            height = y + view.frame.size.height + borderWidth
            
            constraintContentWidth.constant = CGFloat(icons.count) * (iconSize + cellPadding)
            constraintContentHeight.constant = height
        }
        
        scrollView.contentSize = CGSize(width: constraintContentWidth.constant, height: constraintContentHeight.constant)
        delegate?.componentHeightChanged(controller: self, newHeight: self.constraintContentHeight.constant)
    }
}

// MARK: - tap to view player
extension PlayersScrollViewController {
    @objc func didTap(_ gesture: UITapGestureRecognizer?) {
        // open player info
        guard let point = gesture?.location(ofTouch: 0, in: self.scrollView) else { return }
        for (id, icon) in self.icons {
            if icon.view.frame.contains(point) {
                self.didSelectPlayer(player: icon.player)
            }
        }
    }
    
    func didSelectPlayer(player: Player?) {
        guard let player = player else { return }
        
        guard let playerController = UIStoryboard(name: "Account", bundle: nil).instantiateViewController(withIdentifier: "PlayerViewController") as? PlayerViewController else { return }
        
        playerController.player = player
        self.navigationController?.pushViewController(playerController, animated: true)
    }
    
    func goToAttendees() {
        // open Attendees list. not used yet but can be used to view/edit attendances
        if let nav = UIStoryboard(name: "Attendance", bundle: nil).instantiateInitialViewController() as? UINavigationController, let controller = nav.viewControllers[0] as? AttendeesViewController {
            controller.event = event
            present(nav, animated: true, completion: nil)
        }
    }
}

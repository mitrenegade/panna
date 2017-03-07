//
//  PlayersScrollViewController.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/5/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit

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
    
    private var icons: [PlayerIcon] = []
    func addPlayer(player: Player) {
        let icon = PlayerIcon()
        icon.player = player
        icons.append(icon)
        self.refresh()
    }
    
    private var borderWidth: CGFloat = 5
    private var cellPadding: CGFloat = 5
    
    func refresh() {
        self.clear()
        var x: CGFloat = borderWidth
        var y: CGFloat = borderWidth
        var height: CGFloat = 0
        for icon in icons {
            let view = icon.view!
            let frame = CGRect(x: x, y: y, width: iconSize, height: iconSize)
            view.frame = frame
            self.scrollView.addSubview(view)
            x += view.frame.size.width + cellPadding
            height = y + view.frame.size.height + borderWidth
            
            self.constraintContentWidth.constant = x
            self.constraintContentHeight.constant = height
        }
        
        self.delegate?.componentHeightChanged(controller: self, newHeight: self.constraintContentHeight.constant)
    }
    
    private func clear() {
        for icon in self.icons {
            icon.remove()
        }
    }
}

fileprivate var iconSize: CGFloat = 30

class PlayerIcon: NSObject {
    var view: UIView! = UIView()
    var imageView: UIImageView = UIImageView()
    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    var player: Player? {
        didSet {
            self.activityIndicator.hidesWhenStopped = true
            if activityIndicator.superview == nil {
                self.view.addSubview(activityIndicator)
            }
            
            // FIXME: imageView must be explicitly sized, and cannot just be the same size is view
            imageView.frame = CGRect(x: 0, y: 0, width: iconSize, height: iconSize)
            imageView.contentMode = .scaleAspectFit
            imageView.clipsToBounds = true
            imageView.layer.borderWidth = 1
            imageView.layer.borderColor = UIColor.lightGray.cgColor
            imageView.layer.cornerRadius = imageView.frame.size.height / 4
            
            self.refreshPhoto(url: player?.photoUrl)
            
            if imageView.superview == nil {
                self.view.addSubview(imageView)
            }
            
        }
    }
    
    func refreshPhoto(url: String?) {
        do {
            self.activityIndicator.startAnimating()
            // TODO: loading indicator
            if let url = url, let URL = URL(string: url) {
                let data = try Data(contentsOf: URL)
                if let image = UIImage(data: data) {
                    self.imageView.image = image
                    self.activityIndicator.stopAnimating()
                }
                else {
                    self.clearPhoto()
                }
            }
            else {
                self.clearPhoto()
            }
        }
        catch {
            print("invalid photo")
            self.clearPhoto()
        }
    }
    
    func clearPhoto() {
        self.activityIndicator.stopAnimating()
        self.imageView.image = UIImage(named: "profile30")
    }
    
    func remove() {
        self.view.removeFromSuperview()
    }
}

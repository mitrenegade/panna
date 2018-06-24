//
//  PlayersScrollView.swift
//  Balizinha
//
//  Created by Bobby Ren on 6/24/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit

class PlayersScrollView: UIView {
    fileprivate var icons: [String: PlayerIcon] = [:]
    private var borderWidth: CGFloat = 5
    private var cellPadding: CGFloat = 5
    fileprivate var iconSize: CGFloat = 30

    @IBOutlet weak var scrollView: UIScrollView!
    
    func reset() {
        scrollView.subviews.forEach() { $0.removeFromSuperview() }
        icons.removeAll()
    }
    
    func addPlayer(player: Player) {
        guard icons[player.id] == nil else { return }
        print("Adding player \(player.id)")
        let icon = PlayerIcon()
        icon.imageView.activityIndicatorColor = .white
        icon.object = player
        icons[player.id] = icon
    }
    
    func refresh() {
        // TODO: this does not refresh correctly when a user leaves
        var x: CGFloat = borderWidth
        var y: CGFloat = (scrollView.frame.size.height - iconSize) / 2
        var width: CGFloat = 0
        scrollView.subviews.forEach() { $0.removeFromSuperview() }
        for (id, icon) in icons {
            let view = icon
            let frame = CGRect(x: x, y: y, width: iconSize, height: iconSize)
            view.frame = frame
            scrollView.addSubview(view)
            view.refresh()
            x += view.frame.size.width + cellPadding
            
            width = CGFloat(icons.count) * (iconSize + cellPadding)
        }
        
        scrollView.contentSize = CGSize(width: width, height: scrollView.frame.size.height)
    }
}

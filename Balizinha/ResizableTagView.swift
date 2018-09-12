//
//  ResizableTagView.swift
//  Lunr
//
//  Created by Bobby Ren on 2/4/17.
//  Copyright © 2017 RenderApps. All rights reserved.
//
//  This doesn't work with UITableViewCell because it gets created before the cell is the right size, and there doesn't seem to be a way to resize it.
//  Hack: reload the tableview once it appears

import Foundation
import UIKit
import Balizinha

class Tag: NSObject {
    enum Action {
        case info
        case add
    }
    
    var view: UIView!
    let action: Tag.Action
    
    // can contain other attributes like color, font, clickable, etc
    init(tag: String, action: Tag.Action = .info) {
        let label = UILabel()
        label.numberOfLines = 1
        let font = UIFont(name: "Helvetica", size: 14.0)
        label.font = font
        label.text = tag
        label.sizeToFit()
        label.textColor = UIColor.lightGray
        label.textAlignment = .center
        
        let font2 = UIFont(name: "Helvetica", size: 11.0)
        label.font = font2
        label.layer.borderWidth = 1
        label.layer.borderColor = UIColor.lightGray.cgColor
        label.layer.cornerRadius = label.frame.size.height / 4
        self.view = label
        self.action = action
    }
    
    func remove() {
        self.view.removeFromSuperview()
    }
    
    static let adder = Tag(tag: "Add a tag", action: .add)
    static let privateTag = Tag(tag: "Private", action: .add)
}

protocol ResizableTagViewDelegate {
    func didUpdateHeight(height: CGFloat)
}

class ResizableTagView: UIView {
    private var tags: [Tag] = [] {
        didSet {
            self.refresh()
        }
    }
    var delegate: ResizableTagViewDelegate?
    
    private var borderWidth: CGFloat = 5
    private var cellPadding: CGFloat = 5
    
    func refresh() {
        self.clear()
        var x: CGFloat = borderWidth
        var y: CGFloat = borderWidth
        var height: CGFloat = 0
        for tag in tags {
            let view = tag.view!
            if x + view.frame.size.width > self.frame.size.width - 2*borderWidth {
                x = borderWidth
                y = y + view.frame.size.height + cellPadding
            }
            
            let frame = CGRect(x: x, y: y, width: view.frame.size.width, height: view.frame.size.height)
            view.frame = frame
            self.addSubview(view)
            x += view.frame.size.width + cellPadding
            height = y + view.frame.size.height + borderWidth
        }
        delegate?.didUpdateHeight(height: height)
    }
    
    func configureWithTags(tagStrings: [String]?, isPrivate: Bool = false) {
        self.clear()
        var arr = [Tag]()
        if let strings = tagStrings {
            for str in strings {
                let tag = Tag(tag: str)
                arr.append(tag)
            }
        }
        if isPrivate {
            arr.append(Tag.privateTag)
        }
        arr.append(Tag.adder)
        self.tags = arr
    }

    private func clear() {
        for tag in self.tags {
            tag.remove()
        }
    }
}


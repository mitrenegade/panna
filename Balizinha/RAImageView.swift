//
//  RAImageView.swift
//  rollcall
//
//  Created by Bobby Ren on 6/19/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit

class RAImageManager: NSObject {
    static var imageCache = [String: UIImage]()
    let defaultSession = URLSession(configuration: .default)
    var task: URLSessionDataTask?
    var loadingUrl: String?
    fileprivate var imageView: RAImageView?
    
    init(imageView: RAImageView?) {
        self.imageView = imageView
    }
    
    func load(imageUrl: String?, completion: ((UIImage?)->Void)?) {
        guard loadingUrl != imageUrl else { return }
        guard let imageUrl = imageUrl, let url = URL(string: imageUrl) else {
            return
        }
        cancel()

        if let cached = RAImageManager.imageCache[imageUrl] {
            completion?(cached)
            return
        }
        
        loadingUrl = imageUrl
        let currentUrl = imageUrl
        imageView?.activityIndicator?.startAnimating()
        task = defaultSession.dataTask(with: url, completionHandler: { [weak self] (data, response, error) in
            defer {
                DispatchQueue.main.async {
                    self?.cancel()
                }
            }
            
            if nil != error {
                print("error")
                completion?(nil)
            } else if let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 {
                let image = UIImage(data: data)
                RAImageManager.imageCache[currentUrl] = image
                guard self?.loadingUrl == currentUrl else {
                    print("url has changed - cancel")
                    return
                }
                completion?(image)
            }
        })
        task?.resume()
    }
    
    fileprivate func cancel() {
        task?.cancel()
        task = nil
        loadingUrl = nil
        imageView?.activityIndicator?.stopAnimating()
    }
}

class RAImageView: UIImageView {
    var manager: RAImageManager?
    var imageUrl: String? {
        didSet {
            manager?.load(imageUrl: imageUrl, completion: { [weak self] (image) in
                DispatchQueue.main.async { // this seems to force a redraw
                    self?.image = image
                    self?.activityIndicator?.stopAnimating()
                }
            })
        }
    }
    
    override var frame: CGRect {
        didSet {
            super.frame = frame
            activityIndicator?.center = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
        }
    }
    
    var activityIndicator: UIActivityIndicatorView?
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    fileprivate func commonInit() {
        if activityIndicator == nil {
            let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
            activityIndicator.hidesWhenStopped = true
            addSubview(activityIndicator)
            self.activityIndicator = activityIndicator
        }
        
        manager = RAImageManager(imageView: self)
    }
}

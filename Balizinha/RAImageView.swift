//
//  RAImageView.swift
//  rollcall
//
//  Created by Bobby Ren on 6/19/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit

class RAImageView: UIImageView {
    static var imageCache = [String: UIImage]()
    let defaultSession = URLSession(configuration: .default)
    var loadingUrl: String?
    var task: URLSessionDataTask?
    var imageUrl: String? {
        didSet {
            guard loadingUrl != imageUrl else { return }
            load()
        }
    }
    
    var activityIndicator: UIActivityIndicatorView?
    
    fileprivate func cancel() {
        task?.cancel()
        task = nil
        loadingUrl = nil
        activityIndicator?.stopAnimating()
    }

    fileprivate func load() {
        cancel()
        guard let imageUrl = imageUrl, let url = URL(string: imageUrl) else {
            return
        }
        
        if activityIndicator == nil {
            let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
            activityIndicator.hidesWhenStopped = true
            activityIndicator.center = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
            addSubview(activityIndicator)
            self.activityIndicator = activityIndicator
        }
        
        if let cached = RAImageView.imageCache[imageUrl] as? UIImage {
            DispatchQueue.main.async { // this seems to force a redraw
                self.image = cached
            }
            return
        }

        loadingUrl = imageUrl
        let currentUrl = imageUrl
        activityIndicator?.startAnimating()
        task = defaultSession.dataTask(with: url, completionHandler: { [weak self] (data, response, error) in
            defer {
                self?.cancel()
            }
            
            if nil != error {
                print("error")
            } else if let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 {
                let image = UIImage(data: data)
                RAImageView.imageCache[currentUrl] = image
                guard self?.loadingUrl == currentUrl else {
                    print("url has changed - cancel")
                    return
                }
                DispatchQueue.main.async {
                    self?.image = image
                }
            }
        })
        task?.resume()
    }
}

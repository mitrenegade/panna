//
//  FirebaseAPIService.swift
//  Balizinha
//
//  Created by Ren, Bobby on 2/25/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit

class FirebaseAPIService: NSObject {
    // TODO: should this not be shared? how will we handle multiple requests?
    static let shared = FirebaseAPIService()
    
    // variables for creating customer key
    let opQueue = OperationQueue()
    var urlSession: URLSession?
    var dataTask: URLSessionTask?
    var data: Data?
    
    typealias cloudCompletionHandler = ((_ response: Any?, _ error: Error?) -> ())
    var completionHandler: cloudCompletionHandler?
    
    override init() {
        super.init()
        urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: self.opQueue)
    }

    class func getUniqueId(completion: @escaping ((String?)->())) {
        let method = "POST"
        FirebaseAPIService.shared.cloudFunction(functionName: "getUniqueId", method: method, params: nil) { (result, error) in
            guard let result = result as? [String: String], let id = result["id"] else {
                completion(nil)
                return
            }
            completion(id)
        }
    }

    var baseURL: URL? {
        let urlSuffix = TESTING ? "-dev" : "-c9cd7"
        return URL(string: "https://us-central1-balizinha\(urlSuffix).cloudfunctions.net/")
    }

    func test() {
        let urlString = "https://us-central1-balizinha-dev.cloudfunctions.net/testFunction"
        guard let requestUrl = URL(string:urlString) else { return }
        var request = URLRequest(url:requestUrl)
        
        let params = ["uid": "123", "email": "test@gmail.com"]
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        
        try! request.httpBody = JSONSerialization.data(withJSONObject: params, options: [])
        
        let task = URLSession.shared.dataTask(with: request)
        task.resume()
    }
    
    func cloudFunction(functionName: String, method: String, params: [String: Any]?, completion: cloudCompletionHandler?) {
        guard let url = self.baseURL?.appendingPathComponent(functionName) else {
            completion?(nil, nil) // todo
            return
        }
        var request = URLRequest(url:url)
        request.httpMethod = method
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        
        if let params = params {
            do {
                try request.httpBody = JSONSerialization.data(withJSONObject: params, options: [])
            } catch let error {
                print("FirebaseAPIService: cloudFunction could not serialize params: \(params) with error \(error)")
            }
        }
        
        self.completionHandler = completion
        
        let task = urlSession?.dataTask(with: request)
        task?.resume()
    }
}

extension FirebaseAPIService: URLSessionDelegate, URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        print("FirebaseAPIService: data received")
        if let data = self.data {
            self.data?.append(data)
        }
        else {
            self.data = data
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("FirebaseAPIService: completed")
        defer {
            self.data = nil
            self.completionHandler = nil
        }
        
        if let usableData = self.data {
            do {
                let json = try JSONSerialization.jsonObject(with: usableData, options: [])
                print("FirebaseAPIService: urlSession completed with json \(json)")
                completionHandler?(json as? [String: AnyObject], nil)
            } catch let error {
                print("FirebaseAPIService: JSON parsing resulted in error \(error)")
                //                let dataString = String.init(data: usableData, encoding: .utf8)
                //                print("StripeService: try reading data as string: \(dataString)")
                completionHandler?(nil, error)
            }
        }
        else if let error = error {
            completionHandler?(nil, error)
        }
        else {
            print("here")
        }
    }
}

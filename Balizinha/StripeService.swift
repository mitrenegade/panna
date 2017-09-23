//
//  StripeService.swift
//  Balizinha
//
//  Created by Bobby Ren on 9/21/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Stripe

fileprivate var singleton: StripeService?

class StripeService: NSObject, STPEphemeralKeyProvider {
//    static var shared: StripeService {
//        if singleton == nil {
//            singleton = StripeService()
//        }
//        
//        return singleton!
//        
//    }

    // payment method
    var paymentContext: STPPaymentContext?
    var hostController: UIViewController?
    
    // variables for creating customer key
    let opQueue = OperationQueue()
    var urlSession: URLSession?
    var dataTask: URLSessionTask?
    var data: Data?

    var completionHandler: STPJSONResponseCompletionBlock?
    
    let baseURL = URL(string: "https://us-central1-balizinha-dev.cloudfunctions.net/")

    func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping STPJSONResponseCompletionBlock) {
        guard let url = self.baseURL?.appendingPathComponent("ephemeralKeys") else { return }
        
        urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: self.opQueue)
        
        let params = ["api_version": apiVersion, "customer_id": "cus_BQqLbjbWyqc8Ca"]
        var request = URLRequest(url:url)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")

        try! request.httpBody = JSONSerialization.data(withJSONObject: params, options: [])
        
        self.completionHandler = completion
        
        let task = urlSession?.dataTask(with: request)
        task?.resume()
    }
    
    func setupPaymentContext(host: UIViewController) {
        let customerContext = STPCustomerContext(keyProvider: self)
        self.paymentContext = STPPaymentContext(customerContext: customerContext)
        self.paymentContext?.delegate = self
        self.paymentContext?.hostViewController = host
//        self.paymentContext?.paymentAmount = 500 // pull from game object
    }
}

// MARK: - STPPaymentContextDelegate
extension StripeService: STPPaymentContextDelegate {
    func paymentContextDidChange(_ paymentContext: STPPaymentContext) {
        print("didChange")

        NotificationCenter.default.post(name: NSNotification.Name("StripePaymentContextChanged"), object: nil)
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext,
                        didCreatePaymentResult paymentResult: STPPaymentResult,
                        completion: @escaping STPErrorBlock) {
        print("didCreatePayment")
        //        FirebaseFunctionsService.createCharge(paymentResult.source.stripeID, completion: { (error: Error?) in
        //            if let error = error {
        //                completion(error)
        //            } else {
        //                completion(nil)
        //            }
        //        })
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext,
                        didFinishWith status: STPPaymentStatus,
                        error: Error?) {
        print("didFinish")
        switch status {
        case .error: break
        //            self.showError(error)
        case .success: break
        //            self.showReceipt()
        case .userCancellation:
            return // Do nothing
        }
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext,
                        didFailToLoadWithError error: Error) {
        print("didFailToLoad")
        // Show the error to your user, etc.
    }
}

// MARK: - Customer Key
extension StripeService: URLSessionDelegate, URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        print("data received")
        if let data = self.data {
            self.data?.append(data)
        }
        else {
            self.data = data
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("completed")
        defer {
            self.data = nil
            self.completionHandler = nil
        }
        
        if let usableData = self.data {
            do {
                let json = try JSONSerialization.jsonObject(with: usableData, options: [])
                completionHandler?(json as? [String: AnyObject], nil)
            } catch let error {
                print("error \(error)")
                let string = String(data: usableData, encoding: .utf8)
                completionHandler?(nil, error)
            }
        }
        else if let error = error {
            completionHandler?(nil, error)
        }
    }
}

//
//  FirebaseFunctionsService.swift
//  Balizinha
//
//  Created by Bobby Ren on 9/19/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit

class FirebaseFunctionsService: NSObject {
    func test() {
        let urlString = "https://us-central1-balizinha-dev.cloudfunctions.net/testFunction"
        guard let requestUrl = URL(string:urlString) else { return }
        let request = URLRequest(url:requestUrl)
        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) in
            if let usableData = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: usableData, options: [])
                    print("json \(json)") //JSONSerialization
                } catch let error as Error {
                    print("error \(error)")
                }
            }
            else if let error = error {
                print("error \(error)")
            }
        }
        task.resume()
    }
}

//
//  FirebaseImageService.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/5/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage

fileprivate let storage = FIRStorage.storage()
fileprivate let storageRef = storage.reference()
fileprivate let imageRef = storageRef.child("images")

class FirebaseImageService: NSObject {
    class func uploadImage(image: UIImage, completion: @escaping ((_ imageUrl: String?)->Void)) {
        guard let data = UIImageJPEGRepresentation(image, 1) else {
            completion(nil)
            return
        }
        
        let uploadTask = imageRef.put(data, metadata: nil) { (meta, error) in
            guard let metadata = meta else {
                completion(nil)
                return
            }
            let url = metadata.downloadURL()
            completion(url?.absoluteString)
        }
    }
}

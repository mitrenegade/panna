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

fileprivate let storage = Storage.storage()
fileprivate let storageRef = storage.reference()
fileprivate let imageBaseRef = storageRef.child("images")

class FirebaseImageService: NSObject {

    class func uploadImage(image: UIImage, type: String, uid: String, progressHandler: ((_ percent: Double)->Void)? = nil, completion: @escaping ((_ imageUrl: String?)->Void)) {
        guard let data = UIImageJPEGRepresentation(image, 0.9) else {
            completion(nil)
            return
        }
        
        let imageRef: StorageReference = imageBaseRef.child(type).child(uid)
        let uploadTask = imageRef.putData(data, metadata: nil) { (meta, error) in
            guard let metadata = meta else {
                completion(nil)
                return
            }
            let url = metadata.downloadURL()
            completion(url?.absoluteString)
        }
        
        uploadTask.observe(.progress) { (storageTaskSnapshot) in
            if let progress = storageTaskSnapshot.progress {
                print("Progress \(progress)")
                let percent = progress.fractionCompleted
                progressHandler?(percent)
            }
        }
    }
    
    class func resizeImage(image: UIImage, newSize: CGSize) -> UIImage? {
        // Guard newSize is different
        guard image.size != newSize else { return nil }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
        image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    class func resizeImageForProfile(image: UIImage) -> UIImage? {
        let size = image.size
        if size.width <= 500 || size.height <= 500 {
            return image
        }
        var width = size.width
        var height = size.height
        if width < height {
            height = 500 / width * height
            width = 500
        } else {
            width = 500 / height * width
            height = 500
        }
        let newSize = CGSize(width: width, height: height)
        print("Resizing image of \(size) to \(newSize)")
        return resizeImage(image: image, newSize: newSize)
    }
    
    class func resizeImageForEvent(image: UIImage) -> UIImage? {
        // same conditions/size
        return resizeImageForProfile(image:image)
    }
}

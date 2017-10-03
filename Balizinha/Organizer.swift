//
//  Organizer.swift
//  Balizinha
//
//  Created by Bobby Ren on 10/2/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Firebase

class Organizer: FirebaseBaseModel {

    var paymentSourceId: String? {
        guard let dict = self.dict else { return nil }
        return dict["paymentSourceId"] as? String
    }
}

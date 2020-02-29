//
//  Constants.swift
// Balizinha
//
//  Created by Bobby Ren on 5/8/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Foundation
import FirebaseDatabase
import FirebaseAuth
import RenderPay
import RenderCloud

var TESTING = true
var AIRPLANE_MODE = false

var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
var stateAbbreviations = [ "AK",
                           "AL",
                           "AR",
                           "AS",
                           "AZ",
                           "CA",
                           "CO",
                           "CT",
                           "DC",
                           "DE",
                           "FL",
                           "GA",
                           "GU",
                           "HI",
                           "IA",
                           "ID",
                           "IL",
                           "IN",
                           "KS",
                           "KY",
                           "LA",
                           "MA",
                           "MD",
                           "ME",
                           "MI",
                           "MN",
                           "MO",
                           "MS",
                           "MT",
                           "NC",
                           "ND",
                           "NE",
                           "NH",
                           "NJ",
                           "NM",
                           "NV",
                           "NY",
                           "OH",
                           "OK",
                           "OR",
                           "PA",
                           "PR",
                           "RI",
                           "SC",
                           "SD",
                           "TN",
                           "TX",
                           "UT",
                           "VA",
                           "VI",
                           "VT",
                           "WA",
                           "WI",
                           "WV",
                           "WY"]

enum UserSettings: String {
    case DisplayedJoinEventMessage
}

let STRIPE_KEY_DEV = "pk_test_YYNWvzYJi3bTyOJi2SNK3IkE"
let STRIPE_KEY_PROD = "pk_live_IziZ9EDk1374oI3rXjEciLBG"

let STRIPE_CLIENT_ID_DEV = "ca_ECowy0cLCEaImKunoIsUfm2n4EbhxrMO"
let STRIPE_CLIENT_ID_PROD = "ca_ECowdoBb2DfRFlBMQSZ2jT4SSXAUJ6Lx"

var firRef = Database.database().reference()
let firAuth = Auth.auth()

let METERS_PER_MILE: Double = 1609
let EVENT_RADIUS_MILES_DEFAULT: Double = 50

let CACHE_ORGANIZER_FAVORITE_LOCATION = true // TODO: use a setting

let SOFT_UPGRADE_INTERVAL_DEFAULT = (3600*24*7)
let APP_STORE_URL = "itms-apps://itunes.apple.com/app/id1198807198"

let GOOGLE_API_KEY_DEV = "AIzaSyD9zawgH3oSnXJNAvlGPnbZcbQhWIQZ09I"
let GOOGLE_API_KEY_PROD = "AIzaSyCr6wG6UZ9yhjlJbId0ErgkLrIdcYt11iU"

extension UIFont {
    class func printAvailableFonts() {
        let fontFamilyNames = UIFont.familyNames
        for familyName in fontFamilyNames {
            print("------------------------------")
            print("Font Family Name = [\(familyName)]")
            let names = UIFont.fontNames(forFamilyName: familyName )
            print("Font Names = [\(names)]")
        }
    }
    
    class func montserrat(size: CGFloat) -> UIFont {
        return UIFont(name: "Montserrat-Regular", size: size) ?? UIFont.systemFont(ofSize:size)
    }
    class func montserratBold(size: CGFloat) -> UIFont {
        return UIFont(name: "Montserrat-Bold", size: size) ?? UIFont.systemFont(ofSize:size)
    }
    class func montserratSemiBold(size: CGFloat) -> UIFont {
        return UIFont(name: "Montserrat-SemiBold", size: size) ?? UIFont.systemFont(ofSize:size)
    }
    class func montserratMedium(size: CGFloat) -> UIFont {
        return UIFont(name: "Montserrat-Medium", size: size) ?? UIFont.systemFont(ofSize:size)
    }
    class func montserratLight(size: CGFloat) -> UIFont {
        return UIFont(name: "Montserrat-Light", size: size) ?? UIFont.systemFont(ofSize:size)
    }
}

class Globals {
    static var stripeConnectService: StripeConnectService = StripeConnectService(clientId: TESTING ? STRIPE_CLIENT_ID_DEV : STRIPE_CLIENT_ID_PROD)
    static var stripePaymentService: StripePaymentService = StripePaymentService(apiService: RenderAPIService())
}


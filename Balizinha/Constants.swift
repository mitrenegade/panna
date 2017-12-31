//
//  Constants.swift
// Balizinha
//
//  Created by Bobby Ren on 5/8/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Foundation
import Firebase

let leaveColor = UIColor(red: 253/256.0, green: 172/256.0, blue: 146/256.0, alpha: 1.0)
let joinColor = UIColor(red: 28/256.0, green: 71/256.0, blue: 131/256.0, alpha: 1.0)

var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

enum UserSettings: String {
    case DisplayedJoinEventMessage
}

var TESTING = true
var AIRPLANE_MODE = false

let STRIPE_KEY_DEV = "pk_test_YYNWvzYJi3bTyOJi2SNK3IkE"
let STRIPE_KEY_PROD = "pk_live_IziZ9EDk1374oI3rXjEciLBG"

var firRef = Database.database().reference()
let firAuth = Auth.auth()

let METERS_PER_MILE: Double = 1609
let EVENT_RADIUS_MILES_DEFAULT: Double = 50

let CACHE_ORGANIZER_FAVORITE_LOCATION = true // TODO: use a setting

extension UIColor {
    static let darkGreen = UIColor(red: 88/255.0, green: 122/255.0, blue: 103/255.0, alpha: 1)
    static let mediumGreen = UIColor(red: 118.0/255.0, green: 146.0/255.0, blue: 130.0/255.0, alpha: 1)
    static let lightGreen = UIColor(red: 163.0/255.0, green: 180.0/255.0, blue: 172.0/255.0, alpha: 1)
    static let darkRed = UIColor(red: 145.0/255.0, green: 81.0/255.0, blue: 72.0/255.0, alpha: 1)
    static let mediumRed = UIColor(red: 164.0/255.0, green: 113.0/255.0, blue: 10/255.0, alpha: 1)
    static let lightRed = UIColor(red: 192.0/255.0, green: 160.0/255.0, blue: 156.0/255.0, alpha: 1)
    static let darkGray = UIColor(red: 58.0/255.0, green: 58.0/255.0, blue: 60.0/255.0, alpha: 1)
    static let mediumGray = UIColor(red: 93.0/255.0, green: 94.0/255.0, blue: 96.0/255.0, alpha: 1)
    static let lightGray = UIColor(red: 148.0/255.0, green: 148.0/255.0, blue: 150.0/255.0, alpha: 1)
    static let darkBlue = UIColor(red: 37.0/255.0, green: 51.0/255.0, blue: 62.0/255.0, alpha: 1)
    static let mediumBlue = UIColor(red: 62.0/255.0, green: 82.0/255.0, blue: 101.0/255.0, alpha: 1)
    static let lightBlue = UIColor(red: 152.0/255.0, green: 170.0/255.0, blue: 188.0/255.0, alpha: 1)
    static let offWhite = UIColor(red: 217.0/255.0, green: 214.0/255.0, blue: 214.0/255.0, alpha: 1)
}

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

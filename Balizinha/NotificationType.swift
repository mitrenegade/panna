//
//  NotificationType.swift
//  Panna
//
//  Created by Bobby Ren on 10/12/19.
//  Copyright © 2019 Bobby Ren. All rights reserved.
//
import Foundation

enum NotificationType: String {
    case EventsChanged
    case PaymentContextChanged
    case LocationOptionsChanged
    case GoToMapForSharedEvent
    case GoToAccountDeepLink
    case PlayerLeaguesChanged // on join or leave
   
    // sharing/notifications
    case DisplayFeaturedEvent
    case DisplayFeaturedLeague

    func name() -> Notification.Name {
        return Notification.Name(self.rawValue)
    }
}

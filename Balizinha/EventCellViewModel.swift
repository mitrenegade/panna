//
//  EventCellViewModel.swift
//  Panna
//
//  Created by Bobby Ren on 4/15/19.
//  Copyright © 2019 Bobby Ren. All rights reserved.
//

import Foundation
import Balizinha

typealias EventStatus = (isPast: Bool, userIsOwner: Bool, userJoined: Bool)

class EventCellViewModel: NSObject {
    var event: Balizinha.Event

    private var containsUser: Bool = false
    private var status: (Bool, Bool, Bool, Bool) {
        return (event.userIsOrganizer, event.isPast, event.isCancelled, containsUser)
    }
    // convenience for switch statements
    private let _isPast = true
    private let _isOrganizer = true
    private let _containsUser = true
    private let _isCancelled = true

    init(event: Balizinha.Event) {
        self.event = event
        
        if let player = PlayerService.shared.current.value {
            containsUser = event.containsPlayer(player)
        } else {
            containsUser = false
        }
    }
    var titleLabel: String {
        let name = event.name ?? "Balizinha"
        let type = event.type.rawValue
        return "\(name) (\(type))"
    }
    
    var placeLabel: String {
        return event.place ?? "Location TBD"
    }
    
    var timeDateLabel: String {
        if let startTime = event.startTime {
            return "\(event.dateString(startTime)) \(event.timeString(startTime))"
        }
        else {
            return "Date/Time TBD"
        }
    }

    var buttonTitle: String {
        guard !AuthService.isAnonymous else {
            return "Preview"
        }

        switch status {
        case (_isOrganizer, !_isPast, let cancelled, _):
            return cancelled ? "Edit" : "Uncancel"
        case (_isOrganizer, _isPast, _, _):
            break
        case (_, !_isPast, _isCancelled, _):
            return "Cancelled"
        case (_, !_isPast, _, let containsUser):
            return containsUser ? "Leave" : "Join"
        default:
            break
        }
        
        return ""
    }
    
    var buttonFont: UIFont {
        guard !AuthService.isAnonymous else {
            return UIFont.montserrat(size: 13)
        }
        return UIFont.montserrat(size: 16)
    }
    
    var buttonHidden: Bool {
        return event.isPast
    }
    
    var labelFullText: String? {
        if !event.isPast {
            // Button display and action
            
            if event.userIsOrganizer {
                return "This is your event."
            }
            else if containsUser {
                return "You're going!" //To-Do: Add functionality whether or not event is full
            }
            else {
                if event.isFull {
                    return "Event full"
                } else {
                    let left = event.maxPlayers - event.numPlayers
                    return "\(left) spots left"
                }
            }
        } else {
            return nil
        }
    }
    
    var buttonActionEnabled: Bool {
        if !event.isPast {
            // Button display and action
            
            if event.userIsOrganizer {
                return true
            }
            else if containsUser {
                return true
            }
            else {
                if event.isFull {
                    return false
                } else {
                    return true
                }
            }
        } else {
            return false
        }
    }
    
    var labelAttendanceText: String {
        return "\(event.numPlayers)"
    }
    
    func getEventPhoto(_ completion: ((_ imageUrl: String?, _ image: UIImage?)->Void)?) {
        if let leagueId = event.league {
            FirebaseImageService().leaguePhotoUrl(with: leagueId) { (url) in
                DispatchQueue.main.async {
                    if let urlString = url?.absoluteString {
                        completion?(urlString, nil)
                    } else {
                        completion?(nil, UIImage(named: "soccer"))
                    }
                }
            }
        } else {
            // TODO: use different images based on event type
            completion?(nil, UIImage(named: "soccer"))
        }
    }
    
    func handleButtonTap(delegate: EventCellDelegate? = nil) {
        guard !AuthService.isAnonymous else {
            delegate?.previewEvent(event)
            return
        }
        if event.userIsOrganizer {
            // edit
            if event.isCancelled {
                print("Uncancel event")
            } else {
                delegate?.editEvent(event)
            }
        } else if !event.isPast {
            let join = !containsUser
            delegate?.joinOrLeaveEvent(event, join: join)
        }

    }
}

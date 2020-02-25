//
//  LoggingEvent.swift
//  Panna
//
//  Created by Bobby Ren on 10/12/19.
//  Copyright © 2019 Bobby Ren. All rights reserved.
//

enum LoggingEvent: String {
    case TutorialPageViewed
    case TutorialSkipped
    case FeatureFlagError
    case BackgroundFetch
    case PreviewTutorialClicked
    case PreviewEventClicked
    case PreviewSignupClicked
    case WebsiteViewedFromAbout
    
    // sharing
    case ShareEventClicked
    case ShareEventCompleted
    case RecommendedEventCellViewed
    case ShareLeagueClicked
    
    // deep links
    case DeepLinkForAccountOpened
    case DeepLinkForSharedEventOpened
    case DeepLinkForSharedLeagueOpened
    
    // prelogin sharing
    case SignupFromSharedEvent
    case SignupFromSharedLeague

    // upgrade
    case softUpgradeDismissed
    
    // create/edit event
    case SearchForVenue
    case EditVenueName
    case LockVenueName
    case DragVenueMap
    case CloneButtonClicked
    case ClonedEvent
    
    // view event details
    case ShowOrHideMap
    case ShowMapDirections
    
    // edit event details
    case RenameEvent
    case ToggleEventPaymentRequired
    case ChangeEventPaymentAmount
    case DeleteEvent
    case CancelEvent
    
    // push
    case PushNotificationsToggled
    case PushNotificationReceived
    case PushNotificationSubscriptionFailed
    
    // organizer
    case OrganizerSignupPrompt
    case OrganizerNoLeaguesAlert
    
    // guest event
    case GuestEventJoined
    case GuestEventLeft
    case GuestEventNameEntered
    case OnboardingSignupClicked
    
    // payment/stripe
    case show_payment_controller
    case NeedsValidateCustomer // stripeCustomer doesn't exist
    case NeedsRefreshPayment // need to change STPCard to STPSource
    
    // promo
    case AddPromoCode
    case RemovePromoCode
    
    // dashboard
    case DashboardTabClicked
    case DashboardLeagueSelected
    case DashboardViewLeaguePlayers
    case DashboardViewLeagueEvents
    case DashboardViewLeagueActions
    case DashboardViewEventPlayers
    case DashboardSearchForTerm
    
    // venue
    case ShowVenueLocationOnMap
    case FilterVenueBySearchTerm
    case CreateVenueStarted
    
    // recurring events
    case RecurringEventToggled
    case RecurringEventEndDateClicked
    case RecurringEventDaylightSavingsWarned
    
    // feed item clicks
    case FeedItemClicked
    case FeedItemChatViewed
    
    // location
    case ToggleLocationFiltering
    case AlternateLocationForFiltering
    case GoToLocationPermissionSettings
    
    // join events
    case JoinEventClicked
    case LeaveEventClicked
    case OptOutEventClicked
}

enum LoggingKey: String {
    case eventId
    case joinLeaveEventSource

    case joinEventClickedResult
    case joinEventAmountRequired
    
}

enum LoggingValue {
    enum JoinLeaveEventSource: String {
        case list
        case detail
        case onboarding
        case helper // this makes it harder because helper is invoked from multiple sources so it's not really useful
    }

    enum JoinEventClickedResult: String {
        // alerts and warnings
        case invalidPlayer
        case leaveEventPrompt
        case nameNeeded
        case joinPannaPrompt
        case anonymousPlayerOnboarding
        
        // league
        case joinedLeague
        case joinLeagueError
        
        // whether payment was needed/went through
        case chargeForEventError
        case invalidEvent
        case invalidPaymentAmount
        case paymentError
        case paymentNotRequired

        case joinEventError
        case success
    }
}


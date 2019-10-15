//
//  MockLocationService.swift
//  Panna
//
//  Created by Bobby Ren on 10/14/19.
//  Copyright © 2019 Bobby Ren. All rights reserved.
//

import UIKit
import CoreLocation
import RxCocoa
import RxSwift
import Balizinha

class MockLocationService: LocationService {
    // use this to test things dependent on observableLocation
    var mockLocation: CLLocation?

    // use this to test things dependent on locationState
    var mockLocationState: LocationState = .noLocation {
        didSet {
            locationState.accept(mockLocationState)
        }
    }
    
    var mockPlayerCity: City? {
        didSet {
            playerCity.accept(mockPlayerCity)
        }
    }
    
    override var observableLocation: Observable<CLLocation?> {
        return Observable.combineLatest(locationState.asObservable(), playerCity.asObservable()) { [weak self] currentLocationState, currentPlayerCity in
            return self?.mockLocation
        }
    }
    
}

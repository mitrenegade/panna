//
//  LoggingProvider.swift
//  Panna
//
//  Created by Bobby Ren on 10/12/19.
//  Copyright © 2019 Bobby Ren. All rights reserved.
//

import Foundation

protocol LoggingProvider {
    func log(event: LoggingEvent)
    func log(event: LoggingEvent, info: [String : Any]?)
    func log(event: LoggingEvent, message: String?, info: [String : Any]?, error: NSError?)
}

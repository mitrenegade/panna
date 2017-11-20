//
//  TutorialButtonViewModel.swift
//  Balizinha
//
//  Created by Bobby Ren on 11/20/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit

class TutorialButtonViewModel: NSObject {
    
    init(pages: Int) {
        maxPages = pages
    }
    
    private var maxPages: Int
    var currentPage: Int = 0
    
    var skipButtonTitle: String {
        return "SKIP"
    }
    
    var goButtonTitle: String {
        if currentPage == maxPages - 1 {
            return "GO"
        }
        return "NEXT"
    }
}

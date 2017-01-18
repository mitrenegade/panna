//
//  transparentTextField.swift
//  LotSportz
//
//  Created by Tom Strissel on 6/1/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit

class TransparentTextField: UITextField {

    var isCityLocationCell : Bool!
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    override func caretRect(for position: UITextPosition) -> CGRect {
        return CGRect.zero
    }

}

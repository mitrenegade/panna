//
//  PaymentTypesViewController.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/5/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit

class PaymentTypesViewController: UIViewController {
    var event: Event?
    weak var delegate: EventDisplayComponentDelegate?
    
    @IBOutlet weak var labelAmount: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.updatePaymentInfo()
    }

    func updatePaymentInfo() {
        guard event?.paymentRequired == true, let amount = event?.amount else {
            labelAmount.text = "No payment required to join"
            return
        }

        guard let amountString: String = EventService.amountString(from: amount) else {
            labelAmount.text = "Could not calculate payment"
            return
        }
        labelAmount.text = "Cost: \(amountString) to play"
    }
}

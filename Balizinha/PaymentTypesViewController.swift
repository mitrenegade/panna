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
    weak var delegate: SectionComponentDelegate?
    
    @IBOutlet weak var labelAmount: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        guard let event = self.event else {
            labelAmount.text = "Could not load event cost"
            return
        }
        if event.userIsOrganizer {
            self.showPaymentTotal()
        }
        else {
            self.showPaymentRequired()
        }
    }
    
    func showPaymentTotal() {
        guard SettingsService.paymentRequired() else {
            labelAmount.text = nil
            return
        }
        
        guard let event = event, event.paymentRequired == true else {
            labelAmount.text = "No payment required"
            return
        }
        
        EventService.shared.totalAmountPaid(for: event) { [weak self] (total, count) in
            let amount = NSNumber(value: total)

            guard let amountString: String = EventService.amountString(from: amount) else {
                self?.labelAmount.text = "Could not calculate payment"
                return
            }
            
            if count == 0 {
                self?.labelAmount.text = "0 payments received"
            }
            else if count == 1 {
                self?.labelAmount.text = "1 payment received for \(amountString)"
            }
            else {
                self?.labelAmount.text = "\(count) payments received totaling \(amountString)"
            }
        }
    }

    func showPaymentRequired() {
        guard SettingsService.paymentRequired() else {
            labelAmount.text = nil
            return
        }

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

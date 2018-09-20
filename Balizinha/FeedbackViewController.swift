//
//  FeedbackViewController.swift
//  Panna
//
//  Created by Bobby Ren on 9/19/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit
import Firebase
import Balizinha

class FeedbackViewController: UIViewController {

    @IBOutlet weak var inputSubject: UITextField!
    @IBOutlet weak var inputDetails: UITextView!
    
    @IBOutlet weak var buttonSubmit: UIButton!
    
    var isLeagueInquiry: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if isLeagueInquiry {
            inputSubject.text = "League inquiry"
            inputSubject.isUserInteractionEnabled = false
        }
    }
    
    @IBAction func didClickSubmit(sender: UIButton?) {
        guard let subject = inputSubject.text, !subject.isEmpty else {
            simpleAlert("Please enter a subject", message: nil)
            return
        }

        guard let userId = PlayerService.shared.current.value?.id else { return }
        var params: [String: Any] = ["subject": subject, "userId": userId]
        if let details = inputDetails.text, !details.isEmpty {
            params["details"] = details
        }
        FirebaseAPIService().cloudFunction(functionName: "submitFeedback", method: "POST", params: params) { [weak self] (result, error) in
            print("Feedback result \(result) error \(error)")
            if let error = error as? NSError {
                self?.simpleAlert("Feedback failed", defaultMessage: "Could not submit feedback on \(subject)", error: error)
            } else {
                self?.navigationController?.popToRootViewController(animated: true)
            }
        }
    }
    
}

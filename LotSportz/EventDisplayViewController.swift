//
//  EventDisplayViewController.swift
//  LotSportz
//
//  Created by Tom Strissel on 6/26/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit

class EventDisplayViewController: UIViewController {

    @IBOutlet var labelType: UILabel!
    @IBOutlet var labelDate: UILabel!
    @IBOutlet var labelField: UILabel!
    @IBOutlet var labelCity: UILabel!
    
    @IBOutlet var labelDescription: UILabel!
    @IBOutlet var labelNumAttending: UILabel!
    @IBOutlet var labelSpotsAvailable: UILabel!
    @IBOutlet var btnJoin: UIButton!
    @IBOutlet var btnShare: UIButton!
    
    var event : Event!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.view.bringSubviewToFront(labelType.superview!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func didTapButton(sender: UIButton) {
        if sender == btnJoin {
            //TODO: Join Functionality
        } else if sender == btnShare {
            //TODO: Facebook share functionality
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

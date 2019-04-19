//
//  OrganizerViewController.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/19/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Balizinha

class OrganizerViewController: UIViewController {

    var event: Balizinha.Event?
    let playerIcon = PlayerIcon()
    
    @IBOutlet var iconView: UIView!
    @IBOutlet var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        playerIcon.frame = CGRect(x: 0, y: 0, width: iconView.frame.size.width, height: iconView.frame.size.height)
        iconView.addSubview(playerIcon)
        if let event = event, let ownerId = event.organizer {
            PlayerService.shared.withId(id: ownerId, completion: { (player) in
                self.playerIcon.object = player
                if let player = player {
                    self.label.text = "Organizer: \(player.name ?? player.email ?? "")"
                }
                else {
                    self.label.text = "No organizer"
                }
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

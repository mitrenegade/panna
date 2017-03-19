//
//  OrganizerViewController.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/19/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit

class OrganizerViewController: UIViewController {

    var event: Event?
    let playerIcon = PlayerIcon()
    
    @IBOutlet var iconView: UIView!
    @IBOutlet var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.iconView.addSubview(playerIcon.imageView)
        if let event = event, let ownerId = event.owner {
            PlayerService.shared.withId(id: ownerId, completion: { (player) in
                self.playerIcon.player = player
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

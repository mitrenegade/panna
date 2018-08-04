//
//  PlayerLeaguesViewController.swift
//  Balizinha
//
//  Created by Bobby Ren on 4/21/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit
import Balizinha

class PlayerLeaguesViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    fileprivate var icons: [String: PlayerIcon] = [:]
    
    func addLeague(league: League) {
        guard icons[league.id] == nil else { return }
        let icon = FirebaseModelIcon()
        icon.object = league
        icons[league.id] = icon as? PlayerIcon
//        refresh()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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

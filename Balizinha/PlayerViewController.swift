//
//  PlayerViewController.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/15/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit

class PlayerViewController: UIViewController {
    
    @IBOutlet var photoView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var cityLabel: UILabel!
    @IBOutlet var notesLabel: UILabel!
    
    var player: Player?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.refresh()
    }

    func refresh() {
        guard let player = self.player else { return }
        
        if let name = player.name {
            self.nameLabel.text = name
        }
        if let city = player.city {
            self.cityLabel.text = city
        }
        if let notes = player.info {
            self.notesLabel.text = notes
            self.notesLabel.sizeToFit()
        }
        if let photoUrl = player.photoUrl {
            self.refreshPhoto(url: photoUrl)
        }
        
        self.photoView.layer.cornerRadius = self.photoView.frame.size.height / 2
    }
    
    func refreshPhoto(url: String) {
        do {
            if let URL = URL(string: url) {
                let data = try Data(contentsOf: URL)
                if let image = UIImage(data: data) {
                    self.photoView.image = image
                }
            }
        }
        catch {
            print("invalid photo")
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

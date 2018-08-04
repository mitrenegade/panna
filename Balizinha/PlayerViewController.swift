//
//  PlayerViewController.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/15/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Balizinha

class PlayerViewController: UIViewController {
    
    @IBOutlet weak var photoView: RAImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var notesLabel: UILabel!
    
    var player: Player?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.refresh()
        
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.barTintColor = UIColor.mediumBlue
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }

    func refresh() {
        guard let player = self.player else { return }
        
        if let name = player.name {
            self.nameLabel.text = name
        }
        else if let email = player.email {
            self.nameLabel.text = email
        }
        else {
            self.nameLabel.text = nil
        }
        
        if let city = player.city {
            self.cityLabel.text = city
        }
        else {
            self.cityLabel.text = nil
        }
        
        if let notes = player.info {
            self.notesLabel.text = notes
            self.notesLabel.sizeToFit()
        }
        else {
            self.notesLabel.text = nil
        }
        
        refreshPhoto()
    }
    
    func refreshPhoto() {
        photoView.layer.cornerRadius = photoView.frame.size.height / 2
        FirebaseImageService().profileUrl(for: player?.id) {[weak self] (url) in
            DispatchQueue.main.async {
                if let url = url {
                    self?.photoView.imageUrl = url.absoluteString
                }
                else {
                    self?.photoView.layer.cornerRadius = 0
                    self?.photoView.imageUrl = nil
                    self?.photoView.image = UIImage(named: "profile-img")
                }
            }
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

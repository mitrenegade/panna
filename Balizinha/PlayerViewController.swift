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
        refresh()
        
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barTintColor = PannaUI.navBarTint
        
        photoView.image = UIImage(named: "profile-img")?.withRenderingMode(.alwaysTemplate)
        photoView.tintColor = PannaUI.profileTint
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
        
        if let cityId = player.cityId {
            VenueService.shared.withId(id: cityId) { [weak self] (city) in
                DispatchQueue.main.async {
                    if let city = city {
                        self?.cityLabel.text = city.shortString
                    } else if let city = player.city {
                        self?.cityLabel.text = city
                    }
                }
            }
        } else if let city = player.city {
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
        FirebaseImageService().profileUrl(with: player?.id) {[weak self] (url) in
            DispatchQueue.main.async {
                if let url = url {
                    self?.photoView.imageUrl = url.absoluteString
                }
                else {
                    self?.photoView.layer.cornerRadius = 0
                    self?.photoView.imageUrl = nil
                    self?.photoView.image = UIImage(named: "profile-img")?.withRenderingMode(.alwaysTemplate)
                    self?.photoView.tintColor = PannaUI.profileTint
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

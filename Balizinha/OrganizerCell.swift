//
//  OrganizerCell.swift
//  Balizinha
//
//  Created by Bobby Ren on 1/21/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit
import FirebaseDatabase
import Stripe
import RxSwift

class OrganizerCell: UITableViewCell {
    let disposeBag = DisposeBag()
    override func awakeFromNib() {
        OrganizerService.shared.observableOrganizer.asObservable().subscribe(onNext: { _ in
            self.refresh()
        }).disposed(by: disposeBag)
    }
    
    func refresh() {
        let viewModel = OrganizerCellViewModel()
        self.textLabel?.text = viewModel.labelTitle
        self.detailTextLabel?.text = viewModel.labelDetail
    }
}

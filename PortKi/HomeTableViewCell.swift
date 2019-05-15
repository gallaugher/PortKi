//
//  HomeTableViewCell.swift
//  PortKi
//
//  Created by John Gallaugher on 5/14/19.
//  Copyright © 2019 John Gallaugher. All rights reserved.
//

import UIKit

class HomeTableViewCell: UITableViewCell {
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var disclosureButton: UIButton!
    
    weak var delegate: PlusAndDisclosureDelegate?
    var indexPath: IndexPath!
    
    @IBAction func plusButtonPressed(_ sender: UIButton) {
        delegate?.didTapPlusButton(at: indexPath)
    }
    
    @IBAction func disclosureButtonPressed(_ sender: UIButton) {
        delegate?.didTapDisclosure(at: indexPath)
    }
    
}

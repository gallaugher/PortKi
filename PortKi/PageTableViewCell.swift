//
//  PageTableViewCell.swift
//  PortKi
//
//  Created by John Gallaugher on 5/14/19.
//  Copyright © 2019 John Gallaugher. All rights reserved.
//

import UIKit

class PageTableViewCell: UITableViewCell {
    
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var disclosureButton: UIButton!
    @IBOutlet weak var indentView: UIView!
    @IBOutlet weak var pageIcon: UIImageView!
    
    weak var delegate: PlusAndDisclosureDelegate?
    var indexPath: IndexPath!
    
    @IBAction func plusPressed(_ sender: UIButton) {
        delegate?.didTapPlusButton(at: indexPath)
    }
    
    @IBAction func disclosurePressed(_ sender: UIButton) {
        delegate?.didTapDisclosure(at: indexPath)
    }
    
}

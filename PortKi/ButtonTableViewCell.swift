//
//  ButtonTableViewCell.swift
//  PortKi
//
//  Created by John Gallaugher on 5/14/19.
//  Copyright © 2019 John Gallaugher. All rights reserved.
//

import UIKit

class ButtonTableViewCell: UITableViewCell {
    
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var indentView: UIView!
    
    weak var delegate: PlusAndDisclosureDelegate?
    var indexPath: IndexPath!
    
    @IBAction func plusPressed(_ sender: UIButton) {
        delegate?.didTapPlusButton(at: indexPath)
    }
}

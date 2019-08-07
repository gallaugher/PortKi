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
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var screenButton: UIButton!
    
    weak var delegate: PlusAndDisclosureDelegate?
    var indexPath: IndexPath!
    
    @IBAction func plusPressed(_ sender: UIButton) {
        delegate?.didTapPlusButton(at: indexPath)
    }
    
    @IBAction func screenButtonPressed(_ sender: UIButton) {
        delegate?.didTapPageButton(at: indexPath)
    }
}

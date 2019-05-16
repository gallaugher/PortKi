//
//  AlignmentTableViewCell.swift
//  PortKi
//
//  Created by John Gallaugher on 5/15/19.
//  Copyright © 2019 John Gallaugher. All rights reserved.
//

import UIKit

class AlignmentTableViewCell: UITableViewCell {
    weak var delegate: AlignmentCellDelegate?
    
    @IBOutlet weak var alignmentSegmentedControl: UISegmentedControl!
    @IBOutlet weak var styleView: UIView!
    
    @IBOutlet weak var boldButton: ToggleButton!
    @IBOutlet weak var italicsButton: ToggleButton!
    @IBOutlet weak var underlineButton: ToggleButton!
    
    @IBOutlet var styleButtonCollection: [ToggleButton]!
    
    @IBAction func AlignmentPressed(_ sender: UISegmentedControl) {
                delegate?.alignmentSegmentSelected(selectedSegment: alignmentSegmentedControl.selectedSegmentIndex)
    }
    
    
    @IBAction func stylePressed(_ sender: ToggleButton) {
        delegate?.styleButtonSelected(sender)
    }

}

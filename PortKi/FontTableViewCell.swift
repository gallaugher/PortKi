//
//  FontTableViewCell.swift
//  PortKi
//
//  Created by John Gallaugher on 5/15/19.
//  Copyright © 2019 John Gallaugher. All rights reserved.
//

import UIKit

class FontTableViewCell: UITableViewCell {
    
    @IBOutlet weak var fontLabel: UILabel!
    
    func configureFontCell(selectedFont: UIFont) {
        fontLabel.text = selectedFont.familyName
    }
}

//
//  PaddedTextField.swift
//  PortKi
//
//  Created by John Gallaugher on 5/22/19.
//  Copyright © 2019 John Gallaugher. All rights reserved.
//

import UIKit

class PaddedTextField: UITextField {
    let padding = UIEdgeInsets(top: 0, left: 7, bottom: 0, right: 8)
    let noPadding = UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        if self.borderStyle == .none {
            let content = bounds.inset(by: padding)
            return content
        } else {
            return bounds.inset(by: noPadding)
        }
    }
}

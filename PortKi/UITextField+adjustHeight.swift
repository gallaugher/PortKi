//
//  UITextField+adjustHeight.swift
//  PortKi
//
//  Created by John Gallaugher on 5/21/19.
//  Copyright © 2019 John Gallaugher. All rights reserved.
//

import UIKit

extension UITextField {
    func adjustHeight () {
        let originalFrame = self.frame
        self.sizeToFit()
        self.frame = CGRect(x: originalFrame.origin.x, y: self.frame.origin.y, width: originalFrame.width, height: self.frame.height)
    }
}

//
//  UITextField+limitLength.swift
//  PortKi
//
//  Created by John Gallaugher on 5/20/19.
//  Copyright © 2019 John Gallaugher. All rights reserved.
//

import UIKit

private var maxLengths = [UITextField: Int]()

extension UITextField {
    
    @IBInspectable var maxLength: Int {
        get {
            guard let length = maxLengths[self] else {
                return Int.max
            }
            return length
        }
        set {
            maxLengths[self] = newValue
            addTarget(
                self,
                action: #selector(limitLength),
                for: UIControl.Event.editingChanged
            )
        }
    }
    
    @objc func limitLength(textField: UITextField) {
        guard let prospectiveText = textField.text,
            prospectiveText.count > maxLength
            else {
                return
        }
        
        let selection = selectedTextRange
        let maxCharIndex = prospectiveText.index(prospectiveText.startIndex, offsetBy: maxLength)
        // text = prospectiveText.substring(upto: maxCharIndex)
        text = String(prospectiveText.prefix(maxLength))
        selectedTextRange = selection
    }
}

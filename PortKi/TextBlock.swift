//
//  TextBlock.swift
//  PortKi
//
//  Created by John Gallaugher on 5/15/19.
//  Copyright © 2019 John Gallaugher. All rights reserved.
//

import UIKit

struct TextBlock {
    var text = ""
    var origin = CGPoint(x: 0, y: 0)
    var textColor = UIColor.black
    var fontSize: CGFloat = 20.0
    var font = UIFont.systemFont(ofSize: 20.0)
    var backgroundColor = UIColor.clear
    var isBold = false
    var isItalic = false
    var isUnderlined = false
    var alignment = 0 // left alignment
}

//
//  ScreenDesignCellDelegates.swift
//  PortKi
//
//  Created by John Gallaugher on 5/15/19.
//  Copyright © 2019 John Gallaugher. All rights reserved.
//

import Foundation
import UIKit
import ColorSlider

// These link the cusetom table view cells with the Screen Design View Controller so that actions can be taken by code in ScreenDesignViewController when the cells are interacted with

protocol AlignmentCellDelegate: class {
    func alignmentSegmentSelected(selectedSegment: Int)
    func styleButtonSelected(_ sender: ToggleButton)
}

// This links the one or two buttons in the cusetom table view cells with the View Controller so that actions can be taken when the buttons are pressed
protocol SizeCellDelegate: class {
    func fontSizeStepperPressed(_ newFontSize: Int)
}

protocol ColorCellDelegate: class {
    func changeColorSelected(slider: ColorSlider, textColorButton: UIButton, textBackgroundButton: UIButton)
    func setSelectedFrame(sender: UIButton, textColorSelected: Bool, textColorFrame: UIView, textBackgroundFrame: UIView)
}

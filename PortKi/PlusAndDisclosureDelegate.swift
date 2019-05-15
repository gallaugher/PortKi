//
//  PlusAndDisclosureDelegate.swift
//  PortKi
//
//  Created by John Gallaugher on 5/14/19.
//  Copyright © 2019 John Gallaugher. All rights reserved.
//

import Foundation

// This links the one or two buttons in the cusetom table view cells with the View Controller so that actions can be taken when the buttons are pressed
protocol PlusAndDisclosureDelegate: class {
    func didTapPlusButton(at indexPath: IndexPath)
    func didTapDisclosure(at indexPath: IndexPath)
}

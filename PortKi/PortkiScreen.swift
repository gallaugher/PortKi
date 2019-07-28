//
//  PortkiScreen.swift
//  PortKi
//
//  Created by John Gallaugher on 7/22/19.
//  Copyright © 2019 John Gallaugher. All rights reserved.
//

import UIKit

struct ButtonCoordinates: Codable {
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat
}

struct Button: Codable {
    var text: String
    var buttonCoordinates: ButtonCoordinates
    var buttonDestination: String
}

struct PortkiScreen: Codable {
    var pageID: String
    var buttons: [Button]
    var screenURL: String
}

struct PortkiImage: Codable {
    var imageFileName: String
    var imageData: Data
}

//
//  PortkiNode.swift
//  PortKi
//
//  Created by John Gallaugher on 7/23/19.
//  Copyright © 2019 John Gallaugher. All rights reserved.
//

import UIKit

// A Node is either the "Home" screen, a "Button", or a "Screen".

struct PortkiNode: Codable {
    var nodeName: String  // name of button if there is one,"Home", or blank if a child screen.
    var nodeType: String // "home", "button", "screen" I think
    var parentID: String // Do I need this?
    var hierarchyLevel: Int // level indented, 0 for home, 1 for first buttons + pages, etc...
    var childrenIDs: [String] // IDs of elements this leads to - screens to buttons, buttons to screens.
    var backgroundImageUUID: String // assume no image at first
    var documentID: String
    
    init(nodeName: String, nodeType: String, parentID: String, hierarchyLevel: Int, childrenIDs: [String], backgroundImageUUID: String, documentID: String) {
        self.nodeName = nodeName
        self.nodeType = nodeType
        self.parentID = parentID
        self.hierarchyLevel = hierarchyLevel
        self.childrenIDs = childrenIDs
        self.backgroundImageUUID = backgroundImageUUID
        self.documentID = documentID
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func saveTextBlocks(textBlocks: TextBlocks) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let encoded = try? encoder.encode(textBlocks) {
            if let jsonString = String(data: encoded, encoding: .utf8) {
                let parameters = ["value": jsonString]
                guard let json = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
                    print("😡 Grr. json conversion didn't work")
                    return
                }
                print(" 😀 JSON Conversion for PortkiNode.saveTextBlocks Worked !!! - JSON below")
                let fileNameURL = getDocumentsDirectory().appendingPathComponent("\(self.documentID).json")
                do {
                    try json.write(to: fileNameURL, options: .atomic)
                    // TODO: At some point consider writing all of this to adafruit for backup or sync
                } catch {
                    print("😡 Grr. json wasn't writte to file \(error.localizedDescription)")
                }
            }
        } else {
            print("encoding didn't work")
        }
    }
    
}

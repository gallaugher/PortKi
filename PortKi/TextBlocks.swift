//
//  TextBlocks.swift
//  PortKi
//
//  Created by John Gallaugher on 5/22/19.
//  Copyright © 2019 John Gallaugher. All rights reserved.
//

import Foundation
import SwiftyJSON

struct TextBlocks: Codable {
    var pageID: String = ""
    var textBlocksArray: [TextBlock] = []
    
    
    
    func loadTextBlocks(pageID: String, completed: @escaping (TextBlocks?) -> ()) {
        let fileName = "\(pageID).json"
        let fileURL = getDocumentsDirectory().appendingPathComponent("\(pageID).json")
        do {
            let data = try Data(contentsOf: fileURL)
            let json = JSON(data)
            let decoder = JSONDecoder()
            let jsonString = json["value"].stringValue
            print(jsonString)
            let convertedJsonData = Data(jsonString.utf8)
            do {
                let textBlocks = try decoder.decode(TextBlocks.self, from: convertedJsonData)
                completed(textBlocks)
            } catch {
                print(error.localizedDescription)
                completed(nil)
            }
        } catch {
            print("😡 Couldn't get json from file \(fileName): error:\(error)")
            completed(nil)
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

}

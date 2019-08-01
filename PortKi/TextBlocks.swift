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
        
        let filename = getDocumentsDirectory().appendingPathComponent("\(pageID).json")
        do {
            let data = try Data(contentsOf: filename)
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
            print("😡 Couldn't get json from file: error:\(error)")
            completed(nil)
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
//    var db: Firestore!
//    
//    init() {
//        db = Firestore.firestore()
//    }
//    
//    func loadData(element: Element, completed: @escaping () -> ())  {
//        guard element.documentID != "" else {
//            return
//        }
////        db.collection("textblocks").whereField("parentID", isEqualTo: element.documentID).addSnapshotListener { (querySnapshot, error) in
//// No need for listener here, and it was firing after save & screwing things up by redrawing extra elements in the interface, creating out-of-range errors.
//        db.collection("textblocks").whereField("parentID", isEqualTo: element.documentID).getDocuments() { (querySnapshot, error) in
//            guard error == nil else {
//                print("*** ERROR: loading TextBlocks documents \(error!.localizedDescription)")
//                return completed()
//            }
//            self.textBlocksArray = []
//            // there are querySnapshot!.documents.count documents in the spots snapshot
//            for document in querySnapshot!.documents {
//                let textBlock = TextBlock(dictionary: document.data())
//                textBlock.documentID = document.documentID
//                self.textBlocksArray.append(textBlock)
//            }
//            completed()
//        }
//    }
//    
//    // NOTE: If you keep the same programming conventions (e.g. a calculated property .dictionary that converts class properties to String: Any pairs, the name of the document stored in the class as .documentID) then the only thing you'll need to change is the document path (i.e. the lines containing "events" below.
//    func saveData(element: Element, completed: @escaping (Bool) -> ()) {
//        var allSaved = true
//        for textBlock in self.textBlocksArray {
//            textBlock.parentID = element.documentID
//            textBlock.saveData(element: element) { (success) in
//                if !success {
//                    allSaved = false
//                }
//            }
//        }
//        completed(allSaved)
//    }
}

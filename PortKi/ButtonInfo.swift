//
//  ButtonInfo.swift
//  PortKi
//
//  Created by John Gallaugher on 5/23/19.
//  Copyright © 2019 John Gallaugher. All rights reserved.
//

import UIKit

class ButtonInfo {
    var buttonName: String
    var buttonRect: CGRect
    var idToLoad: String
    var documentID: String
    
    var dictionary: [String: Any] {
        return ["buttonName": buttonName, "buttonX": buttonRect.origin.x, "buttonY": buttonRect.origin.y,  "buttonWidth": buttonRect.width, "buttonHeight": buttonRect.height, "idToLoad": idToLoad]
    }
    
    init(buttonName: String, buttonRect: CGRect, idToLoad: String, documentID: String) {
        self.buttonName = buttonName
        self.buttonRect = buttonRect
        self.idToLoad = idToLoad
        self.documentID = ""
    }
    
    convenience init() {
        self.init(buttonName: "", buttonRect: CGRect(x: 0, y: 0, width: 0, height: 0), idToLoad: "", documentID: "")
    }
    
    convenience init(dictionary: [String: Any]) {
        let buttonName = dictionary["buttonName"] as! String? ?? ""
        let buttonX = dictionary["buttonX"] as! CGFloat? ?? CGFloat()
        let buttonY = dictionary["buttonY"] as! CGFloat? ?? CGFloat()
        let buttonWidth = dictionary["buttonWidth"] as! CGFloat? ?? CGFloat()
        let buttonHeight = dictionary["buttonHeight"] as! CGFloat? ?? CGFloat()
        
        let buttonRect = CGRect(x: buttonX, y: buttonY, width: buttonWidth, height: buttonHeight) ?? CGRect()
        let idToLoad = dictionary["idToLoad"] as! String? ?? ""
        self.init(buttonName: buttonName, buttonRect: buttonRect, idToLoad: idToLoad, documentID: "")
    }

    // NOTE: If you keep the same programming conventions (e.g. a calculated property .dictionary that converts class properties to String: Any pairs, the name of the document stored in the class as .documentID) then the only thing you'll need to change is the document path (i.e. the lines containing "events" below.
//    func saveData(completed: @escaping (Bool) -> ()) {
//        let db = Firestore.firestore()
//        // Create the dictionary representing the data we want to save
//        let dataToSave = self.dictionary
//        // if we HAVE saved a record, we'll have a documentID
//        if self.documentID != "" {
//            let ref = db.collection("buttons").document(self.documentID)
//            ref.setData(dataToSave) { (error) in
//                if let error = error {
//                    print("*** ERROR: updating document \(self.documentID) \(error.localizedDescription)")
//                    completed(false)
//                } else {
//                    print("^^^ Document updated with ref ID \(ref.documentID)")
//                    completed(true)
//                }
//            }
//        } else {
//            var ref: DocumentReference? = nil // Let firestore create the new documentID
//            ref = db.collection("buttons").addDocument(data: dataToSave) { error in
//                if let error = error {
//                    print("*** ERROR: creating new document \(error.localizedDescription)")
//                    completed(false)
//                } else {
//                    print("^^^ new buttons document created with ref ID \(ref?.documentID ?? "unknown")")
//                    self.documentID = ref!.documentID
//                    completed(true)
//                }
//            }
//        }
//    }
}

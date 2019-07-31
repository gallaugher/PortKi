//
//  TextBlock.swift
//  PortKi
//
//  Created by John Gallaugher on 5/15/19.
//  Copyright © 2019 John Gallaugher. All rights reserved.
//

import UIKit

class TextBlock {
    var text = ""
    var originPoint = CGPoint(x: 0, y: 0)
    var textColor = UIColor.black
    var fontSize: CGFloat = 20.0
    var font = UIFont.systemFont(ofSize: 20.0)
    var backgroundColor = UIColor.clear
    var isBold = false
    var isItalic = false
    var isUnderlined = false
    var alignment = 0 // left alignment
    var parentID: String
    var documentID: String
    
    var dictionary: [String: Any] {
        let fontName = font.fontName
        let xCoordinate = originPoint.x
        let yCoordinate = originPoint.y
        let textColorHex = textColor.hexString
        let backgroundColorHex = backgroundColor.hexString
        return ["text": text, "xCoordinate": xCoordinate, "yCoordinate": yCoordinate, "textColorHex": textColorHex, "fontSize": fontSize, "fontName": fontName, "backgroundColorHex": backgroundColorHex, "isBold": isBold, "isItalic": isItalic, "isUnderlined": isUnderlined, "alignment": alignment, "parentID": parentID]
    }
    
    init(text: String, originPoint: CGPoint, textColor: UIColor, fontSize: CGFloat, font: UIFont, backgroundColor: UIColor, isBold: Bool, isItalic: Bool, isUnderlined: Bool, alignment: Int, parentID: String, documentID: String) {
        self.text = text
        self.originPoint = originPoint
        self.textColor = textColor
        self.fontSize = fontSize
        self.font = font
        self.backgroundColor = backgroundColor
        self.isBold = isBold
        self.isItalic = isItalic
        self.isUnderlined = isUnderlined
        self.alignment = alignment
        self.parentID = parentID
        self.documentID = ""
    }
    
    convenience init() {
        self.init(text: "", originPoint: CGPoint(x: 0, y: 0), textColor: UIColor.black, fontSize: CGFloat(20.0), font: UIFont.systemFont(ofSize: 20.0), backgroundColor: UIColor.clear, isBold: false, isItalic: false, isUnderlined: false, alignment: 0, parentID: "", documentID: "")
    }
    
    convenience init(dictionary: [String: Any]) {
        let text = dictionary["text"] as! String? ?? ""
        let xCoordinate = dictionary["xCoordinate"] as! CGFloat? ?? 0.0
        let yCoordinate = dictionary["yCoordinate"] as! CGFloat? ?? 0.0
        let originPoint = CGPoint(x: xCoordinate, y: yCoordinate)
        let textColorHex = dictionary["textColorHex"] as! String? ?? "FFFFFF"
        let textColor = UIColor.init(hexString: textColorHex)
        let fontSize = dictionary["fontSize"] as! CGFloat? ?? 20.0
        let fontName = dictionary["fontName"] as! String? ?? ""
        let font = UIFont(name: fontName, size: fontSize) ?? UIFont.systemFont(ofSize: 20.0)
        let backgroundColorHex = dictionary["backgroundColorHex"] as! String? ?? "00000000"
        var backgroundColor = UIColor.init(hexString: backgroundColorHex)
        if backgroundColorHex == "" {
            backgroundColor = UIColor.clear
        }
        let isBold = dictionary["isBold"] as! Bool? ?? false
        let isItalic = dictionary["isItalic"] as! Bool? ?? false
        let isUnderlined = dictionary["isUnderlined"] as! Bool? ?? false
        let alignment = dictionary["alignment"] as! Int? ?? 0
        let parentID = dictionary["parentID"] as! String? ?? ""
        self.init(text: text, originPoint: originPoint, textColor: textColor, fontSize: fontSize, font: font, backgroundColor: backgroundColor, isBold: isBold, isItalic: isItalic, isUnderlined: isUnderlined, alignment: alignment, parentID: parentID, documentID: "")
    }
    
//    // NOTE: If you keep the same programming conventions (e.g. a calculated property .dictionary that converts class properties to String: Any pairs, the name of the document stored in the class as .documentID) then the only thing you'll need to change is the document path (i.e. the lines containing "events" below.
//    func saveData(element: Element, completed: @escaping (Bool) -> ()) {
//        let db = Firestore.firestore()
//        // Create the dictionary representing the data we want to save
//        let dataToSave = self.dictionary
//        // if we HAVE saved a record, we'll have a documentID
//        if self.documentID != "" {
//            let ref = db.collection("textblocks").document(self.documentID)
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
//            ref = db.collection("textblocks").addDocument(data: dataToSave) { error in
//                if let error = error {
//                    print("*** ERROR: creating new document \(error.localizedDescription)")
//                    completed(false)
//                } else {
//                    print("^^^ new TextBlock document created with ref ID \(ref?.documentID ?? "unknown")")
//                    self.documentID = ref!.documentID
//                    completed(true)
//                }
//            }
//        }
//    }
}

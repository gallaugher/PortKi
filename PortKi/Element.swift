//
//  Element.swift
//  PortKi
//
//  Created by John Gallaugher on 5/14/19.
//  Copyright © 2019 John Gallaugher. All rights reserved.
//

import UIKit
import Firebase

class Element {
    var elementName: String
    var elementType: String
    var parentID: String
    var hierarchyLevel: Int // level indented, 0 for home, 1 for first buttons + pages, etc...
    var childrenIDs: [String]
    var backgroundImageUUID = "" // assume no image at first
    var backgroundImage = UIImage()
    var backgroundColor = UIColor.white
    var documentID: String
    
    var dictionary: [String: Any] {
        let backgroundColorHex = backgroundColor.hexString
        return ["elementName": elementName, "elementType": elementType, "parentID": parentID, "hierarchyLevel": hierarchyLevel, "childrenIDs": childrenIDs, "backgroundImageUUID": backgroundImageUUID, "bmpImage": bmpImage, "backgroundColorHex": backgroundColorHex]
    }
    
    var bmpImage: Data {
        let options: NSDictionary =     [:]
        let convertToBmp = self.backgroundImage.toData(options: options, type: .bmp)
        guard let bmpData = convertToBmp else {
            print("😡 ERROR: could not convert image to a bitmap bmpData var.")
            return Data()
        }
        return bmpData
    }
    
    init(elementName: String, elementType: String, parentID: String, hierarchyLevel: Int, childrenIDs: [String], backgroundImageUUID: String, backgroundImage: UIImage, backgroundColor: UIColor, documentID: String) {
        self.elementName = elementName
        self.elementType = elementType
        self.parentID = parentID
        self.hierarchyLevel = hierarchyLevel
        self.childrenIDs = childrenIDs
        self.backgroundImageUUID = backgroundImageUUID
        self.backgroundImage = backgroundImage
        self.backgroundColor = backgroundColor
        self.documentID = documentID
    }
    
    convenience init() {
        self.init(elementName: "", elementType: "", parentID: "", hierarchyLevel: 0, childrenIDs: [String](), backgroundImageUUID: "", backgroundImage: UIImage(), backgroundColor: UIColor.clear, documentID: "")
    }
    
    convenience init(dictionary: [String: Any]) {
        let elementName = dictionary["elementName"] as! String? ?? ""
        let elementType = dictionary["elementType"] as! String? ?? ""
        let parentID = dictionary["parentID"] as! String? ?? ""
        let hierarchyLevel = dictionary["hierarchyLevel"] as! Int? ?? 0
        let backgroundImageUUID = dictionary["backgroundImageUUID"] as! String? ?? ""
        let childrenIDs = dictionary["childrenIDs"] as! [String]? ?? [String]()
        let bmpImage = dictionary["bmpImage"] as! Data? ?? Data()
        let backgroundImage = UIImage(data: bmpImage) ?? UIImage()
        let backgroundColorHex = dictionary["backgroundColorHex"] as! String? ?? "00000000"
        let backgroundColor = UIColor.init(hexString: backgroundColorHex)
        self.init(elementName: elementName, elementType: elementType, parentID: parentID, hierarchyLevel: hierarchyLevel, childrenIDs: childrenIDs, backgroundImageUUID: backgroundImageUUID, backgroundImage: backgroundImage, backgroundColor: backgroundColor, documentID: "")
    }
    
    // NOTE: If you keep the same programming conventions (e.g. a calculated property .dictionary that converts class properties to String: Any pairs, the name of the document stored in the class as .documentID) then the only thing you'll need to change is the document path (i.e. the lines containing "elements" below.
    func saveData(completed: @escaping (Bool) -> ()) {
        let db = Firestore.firestore()
        // Create the dictionary representing the data we want to save
        let dataToSave = self.dictionary
        // if we HAVE saved a record, we'll have a documentID
        if self.documentID != "" {
            let ref = db.collection("elements").document(self.documentID)
            ref.setData(dataToSave) { (error) in
                if let error = error {
                    print("*** ERROR: updating document \(self.documentID) \(error.localizedDescription)")
                    completed(false)
                } else {
                    print("^^^ Document updated with ref ID \(ref.documentID)")
                    completed(true)
                }
            }
        } else {
            var ref: DocumentReference? = nil // Let firestore create the new documentID
            ref = db.collection("elements").addDocument(data: dataToSave) { error in
                if let error = error {
                    print("*** ERROR: creating new document \(error.localizedDescription)")
                    completed(false)
                } else {
                    print("^^^ new element document created with ref ID \(ref?.documentID ?? "unknown")")
                    self.documentID = ref!.documentID
                    completed(true)
                }
            }
        }
    }
    
    func saveImage(completed: @escaping (Bool) -> ()) {
        let storage = Storage.storage()
        // convert screen.image to a Data type so it can be saved by Firebase Storage
        guard let imageToStore = self.backgroundImage.jpegData(compressionQuality: 0.25) else {
            print("*** ERROR: couuld not convert image to data format")
            return completed(false)
        }
        let options: NSDictionary = [:]
        let convertToBmp = self.backgroundImage.toData(options: options, type: .bmp)
        guard let bmpData = convertToBmp else {
            print("😡 ERROR: could not convert image to a bitmap bmpData var.")
            return
        }
        let uploadMetadata = StorageMetadata()
        // uploadMetadata.contentType = "image/jpeg"
        uploadMetadata.contentType = "image/bmp"
        // create a ref to upload storage to with the backgroundImageUUID that we created.
        let storageRef = storage.reference().child(self.backgroundImageUUID)
        let uploadTask = storageRef.putData(bmpData, metadata: uploadMetadata) {metadata, error in
            guard error == nil else {
                print("😡 ERROR during .putData storage upload for reference \(storageRef). Error: \(error!.localizedDescription)")
                return
            }
            print("😎 Upload worked! Metadata is \(metadata!)")
        }
        
        uploadTask.observe(.success) { (snapshot) in
            print("😎 successfully saved image to Firebase Storage")
            //            // Create the dictionary representing the data we want to save
            //            let dataToSave = self.dictionary
            //            // This will either create a new doc at documentUUID or update the existing doc with that name
            //            let ref = db.collection("spots").document(spot.documentID).collection("photos").document(self.documentUUID)
            //            ref.setData(dataToSave) { (error) in
            //                if let error = error {
            //                    print("*** ERROR: updating document \(self.documentUUID) in spot \(spot.documentID) \(error.localizedDescription)")
            //                    completed(false)
            //                } else {
            //                    print("^^^ Document updated with ref ID \(ref.documentID)")
            //                    completed(true)
            //                }
            //            }
        }
        
        uploadTask.observe(.failure) { (snapshot) in
            if let error = snapshot.error {
                print("*** ERROR: upload task for file \(self.backgroundImageUUID) failed, in element \(self.documentID), error \(error)")
            }
            return completed(false)
        }
    }
    
    func loadBackgroundImage (completed: @escaping () -> ()) {
        let storage = Storage.storage()
        let backgroundImageRef = storage.reference().child(self.backgroundImageUUID)
        backgroundImageRef.getData(maxSize: 25 * 1025 * 1025) { data, error in
            if let error = error {
                print("*** ERROR: An error occurred while reading data from file ref: \(backgroundImageRef) \(error.localizedDescription)")
                return completed()
            } else {
                let image = UIImage(data: data!)
                self.backgroundImage = image!
                return completed()
            }
        }
    }
}

//
//  Screen.swift
//  PortKi
//
//  Created by John Gallaugher on 5/23/19.
//  Copyright © 2019 John Gallaugher. All rights reserved.
//

import UIKit
import Firebase

class Screen {
    var screenImage: UIImage
    var imageUUID: String
    var buttonIdArray: [String]
    var documentID: String
    
    var dictionary: [String: Any] {
        return ["screenBmpData": screenBmpData, "imageUUID": imageUUID, "buttonIdArray": buttonIdArray]
    }
    
    var screenBmpData: Data {
        let options: NSDictionary = [:]
        var convertToBmp = self.screenImage.toData(options: options, type: .bmp)
        
        // TODO: Get rid of this, below. Just experimenting with sizes since bmp conversion is too big.
        let imgData = screenImage.jpegData(compressionQuality: 1.0)
        convertToBmp = imgData as? Data
        guard let screenBmpData = convertToBmp else {
            print("😡 ERROR: could not convert image to a bitmap bmpData var.")
            return Data()
        }
        return screenBmpData
    }
    
    init(screenImage: UIImage, imageUUID: String, buttonIdArray: [String], documentID: String) {
        self.screenImage = screenImage
        self.imageUUID = imageUUID
        self.buttonIdArray = buttonIdArray
        self.documentID = ""
    }
    
    convenience init() {
        self.init(screenImage: UIImage(), imageUUID: "", buttonIdArray: [String](), documentID: "")
    }
    
    convenience init(dictionary: [String: Any]) {
        let screenBmpData = dictionary["screenBmpData"] as! Data? ?? Data()
        let imageUUID = dictionary["imageUUID"] as! String? ?? ""
        let buttonIdArray = dictionary["buttonIdArray"] as! [String]? ?? [String]()
        let screenImage = UIImage() // I fudged this. I don't think I need to get the .bmp since I shouldn't be reading this data in for display
        self.init(screenImage: screenImage, imageUUID: imageUUID, buttonIdArray: buttonIdArray, documentID: "")
    }
    
    func saveData(completed: @escaping (Bool) -> ()) {
        let db = Firestore.firestore()
        // Create the dictionary representing the data we want to save
        let dataToSave = self.dictionary
        // if we HAVE saved a record, we'll have a documentID
        if self.documentID != "" {
            let ref = db.collection("screens").document(self.documentID)
            ref.setData(dataToSave) { (error) in
                
                if let error = error {
                    print("*** ERROR: updating screen document \(self.documentID) \(error.localizedDescription)")
                    completed(false)
                } else {
                    print("^^^ Screen document updated with ref ID \(ref.documentID)")
                    completed(true)
                }
            }
        } else {
            var ref: DocumentReference? = nil // Let firestore create the new documentID
            ref = db.collection("screens").addDocument(data: dataToSave) { error in
                if let error = error {
                    print("*** ERROR: creating new screens document \(error.localizedDescription)")
                    completed(false)
                } else {
                    print("^^^ new screens document created with ref ID \(ref?.documentID ?? "unknown")")
                    self.documentID = ref!.documentID
                    completed(true)
                }
            }
        }
    }
    
    
    
    
    func saveImage(completed: @escaping (Bool) -> ()) {
        let storage = Storage.storage()
        // convert screen.image to a Data type so it can be saved by Firebase Storage
        guard let imageToStore = self.screenImage.jpegData(compressionQuality: 1) else {
            print("*** ERROR: couuld not convert image to data format")
            return completed(false)
        }
        let options: NSDictionary = [:]
        let convertToBmp = self.screenImage.toData(options: options, type: .bmp)
        guard let bmpData = convertToBmp else {
            print("😡 ERROR: could not convert image to a bitmap bmpData var.")
            return
        }
        let uploadMetadata = StorageMetadata()
        // uploadMetadata.contentType = "image/jpeg"
        uploadMetadata.contentType = "image/bmp"
        // create a ref to upload storage to with the imageUUID that we created.
        let storageRef = storage.reference().child(self.imageUUID)
        let uploadTask = storageRef.putData(bmpData, metadata: uploadMetadata) {metadata, error in
            guard error == nil else {
                print("😡 ERROR during .putData storage upload for screen reference \(storageRef). Error: \(error!.localizedDescription)")
                return
            }
            print("😎 Upload worked! Screen etadata is \(metadata!)")
        }
        
        uploadTask.observe(.success) { (snapshot) in
            print("😎 successfully saved screen image to Firebase Storage")
        }
        
        uploadTask.observe(.failure) { (snapshot) in
            if let error = snapshot.error {
                print("*** ERROR: upload task for file \(self.imageUUID) failed, in screen \(self.documentID), error \(error)")
            }
            return completed(false)
        }
    }
    
    func loadScreenImage (completed: @escaping () -> ()) {
        let storage = Storage.storage()
        let screenImageRef = storage.reference().child(self.imageUUID)
        screenImageRef.getData(maxSize: 25 * 1025 * 1025) { data, error in
            if let error = error {
                print("*** ERROR: An error occurred while reading data from screen file ref: \(screenImageRef) \(error.localizedDescription)")
                return completed()
            } else {
                let image = UIImage(data: data!)
                self.screenImage = image!
                return completed()
            }
        }
    }
}

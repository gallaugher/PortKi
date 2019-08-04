//
//  ScreenListViewController.swift
//  PortKi
//
//  Created by John Gallaugher on 5/14/19.
//  Copyright © 2019 John Gallaugher. All rights reserved.

import UIKit
import Alamofire
import SwiftyJSON
import AWSCognito
import AWSS3

class ScreenListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var editBarButton: UIBarButtonItem!
    @IBOutlet weak var updatePyPortalButton: UIBarButtonItem!
    
    // used simply to calculate button properties to be used in PyPortal via portkiScreens converted to JSON
    @IBOutlet var screenView: UIView!
    
    let filesFolderName = "portki-files"
    let awsBucketName = "portki" // at some point you'll want to get this for individual users.
    
    var portkiScreens: [PortkiScreen] = []
    var portkiNodes: [PortkiNode] = []
    var newNodes: [PortkiNode] = []
    let indentBase = 26 // how far to indent button/screen levels
    var imageURL = "https://gallaugher.com/wp-content/uploads/2009/08/John-White-Border-Beard-Crossed-Arms-Photo.jpg"
    
    override func viewDidLoad() {
        setupAWSS3()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        loadPortkiScreens()
        loadPortkiNodes()
        setUpFirstNodesIfNoNodesExist()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        guard let home = portkiNodes.first(where: {$0.nodeType == "Home"}) else {
            print("ERROR: There was a problem finding the 'Home' node")
            return
        }
        newNodes = []
        if portkiNodes.count > 1 { // more than just home, so sort
            sortNodes(node: home)
            portkiNodes = self.newNodes
        }
        self.tableView.reloadData()
    }
    
    func setupAWSS3() {
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.USEast1,
                                                                identityPoolId:"us-east-1:93b4d97e-1aaa-43a3-99f3-ae183b5a8b86")
        let configuration = AWSServiceConfiguration(region:.USEast1, credentialsProvider:credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
    }
    
    func setUpFirstNodesIfNoNodesExist(){
        if portkiNodes.isEmpty {
            // if there are no portkiNodes then there must not be any portkiScreens, either
            // If there are no portkiScreens, then create new "Home" screen and new "Home" node.
            portkiScreens.append(PortkiScreen(pageID: "Home", buttons: [Button](), screenURL: ""))
            portkiNodes.append(PortkiNode(nodeName: "Home", nodeType: "Home", parentID: "", hierarchyLevel: 0, childrenIDs: [String](), backgroundImageUUID: "", documentID: "Home"))
            tableView.reloadData()
            let indexPathForSelectedRow = IndexPath(row: 0, section: 0) // "Home" should always be row zero.
            tableView.selectRow(at: indexPathForSelectedRow, animated: true, scrollPosition: .top)
            // segue to next screen since you've just created a new tree with blank "Home" screen & nodes.
            performSegue(withIdentifier: "AddScreen", sender: nil)
        } else {
            // TODO: Read in json for nodes from some location where you store it - either locally or at adafruit.io
            print(" >>> There are \(portkiNodes.count) portkiNodes")
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func loadPortkiNodes() {
        let fileName = "portkiNodes.json"
        let fileURL = getDocumentsDirectory().appendingPathComponent("portkiNodes.json")
        do {
            let data = try Data(contentsOf: fileURL)
            let json = JSON(data)
            let decoder = JSONDecoder()
            let jsonString = json["value"].stringValue
            let convertedJsonData = Data(jsonString.utf8)
            do {
                portkiNodes = try decoder.decode([PortkiNode].self, from: convertedJsonData)
            } catch {
                print(error.localizedDescription)
            }
        } catch {
            print("😡 Couldn't get json from file \(fileName): error:\(error)")
        }
    }
    
    // Note that I might not need to load portki screens if everything goes one way - out to Adafruit & not back. This would be the case if I store only on the app. So I'm not calling this yet.
    func loadPortkiScreens() {
        let filename = getDocumentsDirectory().appendingPathComponent("portkiScreens.json")
        do {
            let data = try Data(contentsOf: filename)
            // print(data)
            let json = JSON(data)
            // print(json["value"])
            
            // print("now decoding")
            let decoder = JSONDecoder()
            let jsonString = json["value"].stringValue
            let convertedJsonData = Data(jsonString.utf8)
            do {
                portkiScreens = try decoder.decode([PortkiScreen].self, from: convertedJsonData)
                //                for node in portkiNodes {
                //                    print(node.nodeName)
                //                    print("   This screen has \(node.childrenIDs.count) children")
                //                }
            } catch {
                print(error.localizedDescription)
            }
        } catch {
            print("😡 Couldn't get json from file: error:\(error)")
        }
    }
    
    func loadPortkiScreensFromAdafruitIo() {
        let apiURL = "https://io.adafruit.com/api/v2/gallaugher/feeds/portki"
        Alamofire.request(apiURL).responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                let jsonData = json["last_value"]
                //                print(jsonData)
                //                print("now decoding")
                let decoder = JSONDecoder()
                let jsonString = json["last_value"].stringValue
                let convertedJsonData = Data(jsonString.utf8)
                do {
                    self.portkiScreens = try decoder.decode([PortkiScreen].self, from: convertedJsonData)
                    //                    for screen in self.portkiScreens {
                    //                        print(screen.pageID)
                    //                        print("   This screen has \(screen.buttons.count) buttons")
                    //                    }
                } catch {
                    print(error.localizedDescription)
                }
            case .failure(let error):
                print("ERROR: \(error.localizedDescription) failed to get data from url \(apiURL)")
            }
        }
    }
    
    func sortNodes(node: PortkiNode) {
        newNodes.append(node)
        if !node.childrenIDs.isEmpty { // if there is at least one child for this element
            for childID in node.childrenIDs { // loop through all children
                if let child = portkiNodes.first(where: {$0.documentID == childID}) {
                    sortNodes(node: child ) // and sort its children, if any
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // click to edit an exiseting screen
        switch segue.identifier {
        case "ShowScreen":
            let destination = segue.destination as! ScreenDesignViewController
            let selectedIndexPath = tableView.indexPathForSelectedRow!
            let selectedScreen = portkiNodes[selectedIndexPath.row]
            if selectedScreen.nodeName != "Home" {
                let parentIndex = portkiNodes.firstIndex(where: {$0.documentID == portkiNodes[selectedIndexPath.row].parentID})
                if let parentIndex = parentIndex {
                    destination.siblingButtonIDArray = portkiNodes[parentIndex].childrenIDs
                }
            }
            destination.portkiNode = portkiNodes[selectedIndexPath.row]
            destination.portkiNodes = portkiNodes
            
            // Now find portkiScreen that cooresponds to the portkiNode you're passing, and pass in that portkiScreen, too.
            let foundPortkiScreenIndex = portkiScreens.firstIndex(where: {$0.pageID == portkiNodes[selectedIndexPath.row].documentID})
            
            if let portkiScreenIndex = foundPortkiScreenIndex {
                destination.portkiScreen = portkiScreens[portkiScreenIndex]
                print("Just properly passed in a portkiScreen")
            } else {
                print("😡 ERROR: Couldn't find a portkiScreenIndex to pass in with the portkiNode")
            }
        case "AddScreen":
            // adding a screen pass the last element - we'll sort them when they're back. No need to worry about deselecting
            let navigationController = segue.destination as! UINavigationController
            let destination = navigationController.viewControllers.first as! ScreenDesignViewController
            destination.portkiNode = portkiNodes.last
            destination.portkiNodes = portkiNodes
            
            // Now find portkiScreen that cooresponds to the portkiNode you're passing, and pass in that portkiScreen, too.
            let foundPortkiScreenIndex = portkiScreens.firstIndex(where: {$0.pageID == portkiNodes.last!.documentID})
            
            if let portkiScreenIndex = foundPortkiScreenIndex {
                destination.portkiScreen = portkiScreens[portkiScreenIndex]
                print("Just properly passed in a portkiScreen")
            } else {
                print("😡 ERROR: Couldn't find a portkiScreenIndex to pass in with the portkiNode")
            }
        case "About":
            print("Headed to the about screen")
        default:
            print("😡 ERROR: segueing to an unidentified view controller")
        }
        //        if segue.identifier == "ShowScreen" {
        //            let destination = segue.destination as! ScreenDesignViewController
        //            let selectedIndexPath = tableView.indexPathForSelectedRow!
        //            let selectedScreen = portkiNodes[selectedIndexPath.row]
        //            if selectedScreen.nodeName != "Home" {
        //                let parentIndex = portkiNodes.firstIndex(where: {$0.documentID == portkiNodes[selectedIndexPath.row].parentID})
        //                if let parentIndex = parentIndex {
        //                    destination.siblingButtonIDArray = portkiNodes[parentIndex].childrenIDs
        //                }
        //            }
        //            destination.portkiNode = portkiNodes[selectedIndexPath.row]
        //            destination.portkiNodes = portkiNodes
        //
        //            // Now find portkiScreen that cooresponds to the portkiNode you're passing, and pass in that portkiScreen, too.
        //            let foundPortkiScreenIndex = portkiScreens.firstIndex(where: {$0.pageID == portkiNodes[selectedIndexPath.row].documentID})
        //
        //            if let portkiScreenIndex = foundPortkiScreenIndex {
        //                destination.portkiScreen = portkiScreens[portkiScreenIndex]
        //                print("Just properly passed in a portkiScreen")
        //            } else {
        //                print("😡 ERROR: Couldn't find a portkiScreenIndex to pass in with the portkiNode")
        //            }
        //
        //        } else { // adding a screen pass the last element - we'll sort them when they're back. No need to worry about deselecting
        //            let navigationController = segue.destination as! UINavigationController
        //            let destination = navigationController.viewControllers.first as! ScreenDesignViewController
        //            destination.portkiNode = portkiNodes.last
        //            destination.portkiNodes = portkiNodes
        //
        //            // Now find portkiScreen that cooresponds to the portkiNode you're passing, and pass in that portkiScreen, too.
        //            let foundPortkiScreenIndex = portkiScreens.firstIndex(where: {$0.pageID == portkiNodes.last!.documentID})
        //
        //            if let portkiScreenIndex = foundPortkiScreenIndex {
        //                destination.portkiScreen = portkiScreens[portkiScreenIndex]
        //                print("Just properly passed in a portkiScreen")
        //            } else {
        //                print("😡 ERROR: Couldn't find a portkiScreenIndex to pass in with the portkiNode")
        //            }
        
    }
    
    @IBAction func unwindFromScreenDesignViewController(segue: UIStoryboardSegue) {
        let sourceViewController = segue.source as! ScreenDesignViewController
        // Unwind only happens on "Save" press, not cancel, so you should always need to update the portkiNode
        
        // First update portkiScreens - the data structure used to create JSON for the PyPortal:
        let portkiNode = sourceViewController.portkiNode!
        let portkiNodeIndex = portkiNodes.firstIndex(where: {$0.documentID == portkiNode.documentID})
        
        if let portkiNodeIndex = portkiNodeIndex {
            portkiNodes[portkiNodeIndex] = portkiNode
            // print(">> Must have UPDATED a screen in unwindFromScreenDesignVC")
        } else {
            print("😡😡 ERROR IN unwindFromScreenDesignVC - since portkiNodes were created before transfer, then there should be on already and you shouldn't have to create a new one.")
            portkiNodes.append(portkiNode)
            print(">> Must have just added a new screen in unwindFromScreenDesignVC")
        }
    }
    
    func sendJsonToAdafruitIo(jsonString: String) {
        let parameters = ["value": jsonString]
        guard let url = URL(string: "https://io.adafruit.com/api/feeds/portki/data.json?X-AIO-Key=073cd97c69db42dab2b411062bf15f23") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: []) else { return }
        request.httpBody = httpBody
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    // print(json)
                    print("😀 JSON for portKiScreens POSTED to Adafruit.io - HURRAY!!!")
                } catch {
                    print(error)
                    print("😡 Grr. json for portkiScreens wasn't posted to Adafruit.io")
                }
            }
            }.resume()
    }
    
    @IBAction func updatePyPortalPressed(_ sender: UIBarButtonItem) {
        // Go through all portkiScreens + add proper [Button] + Button coordinates for each screen
        // So as long as I have a count of the # of screens I have, I don't need to pass PortkiScreen data back and forth between the view controllers.
        
        portkiScreens = []
        // Note: Do I even need portkiScreens if I'm rebuilding the array, below?
        for index in 0..<portkiNodes.count {
            if portkiNodes[index].nodeType == "Button" {
                continue
            }
            // Create all buttons for that node and update the portkiScreen with proper coordinates
            var buttons = createLeftRightBackButtons(portkiNode: portkiNodes[index])
            let leafButtons = createLeafButtons(portkiNode: portkiNodes[index])
            buttons += getButtonsFromUIButtons(leafButtons: leafButtons, portkiNode: portkiNodes[index])
            let fileName = "\(portkiNodes[index].documentID).jpeg"
            let screenURL = "https://\(awsBucketName).s3.amazonaws.com/\(fileName)"
            var portkiScreen = PortkiScreen(pageID: portkiNodes[index].documentID, buttons: buttons, screenURL: screenURL)
            portkiScreens.append(portkiScreen)
            print("Node # \(index):")
            print(portkiNodes[index])
            print("Screen # \(portkiScreens.count-1):")
            print(portkiScreens.last!)
            
            getDataFromFile(named: fileName) { (data) in
                guard let data = data else {
                    print("😡 ERROR: Bummer, didn't return valid data from getDataFromFile")
                    return
                }
                self.uploadFileToAWS(fileName: fileName, contentType: "image/jpeg", data: data)
            }
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let encoded = try? encoder.encode(portkiScreens) {
            if let jsonString = String(data: encoded, encoding: .utf8) {
                //                print(jsonString)
                
                let parameters = ["value": jsonString]
                guard let json = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
                    print("😡 Grr. json conversion didn't work")
                    return
                }
                print("** JSON Conversion Worked !!!")
                //                print(json)
                
                let fileNameURL = getDocumentsDirectory().appendingPathComponent("portkiScreens.json")
                do {
                    try json.write(to: fileNameURL, options: .atomic)
                    uploadFileToAWS(fileName: "portki.json", contentType: "application/json", data: json)
                    sendJsonToAdafruitIo(jsonString: jsonString)
                } catch {
                    print("😡 Grr. json wasn't writte to file \(error.localizedDescription)")
                }
            }
        } else {
            print("encoding didn't work")
        }
    }
    
    @IBAction func editBarButtonPressed(_ sender: UIBarButtonItem) {
        if tableView.isEditing {
            tableView.setEditing(false, animated: true)
            updatePyPortalButton.isEnabled = true
            editBarButton.title = "Edit"
        } else {
            tableView.setEditing(true, animated: true)
            updatePyPortalButton.isEnabled = false
            editBarButton.title = "Done"
        }
        tableView.reloadData()
    }
}

// NOTE: This is where I write files to Google Drive
extension ScreenListViewController {
    
    func getDataFromFile(named fileName: String, completed: @escaping (_ data: Data?) -> ()) {
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        do {
            let data = try Data(contentsOf: fileURL)
            print("😀 Success: created data from file \(fileName) via fileURL \(fileURL)")
            completed(data)
        } catch {
            print("😡 ERROR: couldn't create data for fileName \(fileName) at local URL \(fileURL).")
            completed(nil)
        }
    }
    
    func uploadFileToAWS(fileName: String, contentType: String, data: Data) {
        DispatchQueue.main.async {
            let transferUtility = AWSS3TransferUtility.default()
            let expression = AWSS3TransferUtilityUploadExpression()
            
            transferUtility.uploadData(data, bucket: self.awsBucketName, key: fileName, contentType: contentType, expression: expression) { (task, error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                print(" 😀 Upload of file \(fileName) to AWS S3 bucket \(self.awsBucketName) was successful!")
            }
        }
    }
}

extension ScreenListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // return elements.elementArray.count
        return portkiNodes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Element could be home, a button, or a screen
        
        switch portkiNodes[indexPath.row].nodeType {
        case "Home":
            let cell = tableView.dequeueReusableCell(withIdentifier: "HomeCell", for: indexPath) as! HomeTableViewCell
            cell.delegate = self
            cell.indexPath = indexPath
            if tableView.isEditing {
                cell.plusButton.isEnabled = false
                cell.disclosureButton.isEnabled = false
            } else {
                cell.plusButton.isEnabled = true
                cell.disclosureButton.isEnabled = true
            }
            return cell
        case "Button":
            let cell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell", for: indexPath) as! ButtonTableViewCell
            cell.delegate = self
            cell.indexPath = indexPath
            var newRect = cell.indentView.frame
            // now change x value & reassign to indentview
            // let indentAmount = CGFloat(elements.elementArray[indexPath.row].hierarchyLevel*indentBase)
            let indentAmount = CGFloat(portkiNodes[indexPath.row].hierarchyLevel*indentBase)
            newRect = CGRect(x: indentAmount, y: newRect.origin.y, width: newRect.width, height: newRect.height)
            UIView.animate(withDuration: 0.5, animations: {cell.indentView.frame = newRect})
            // cell.button.setTitle(elements.elementArray[indexPath.row].elementName, for: .normal)
            cell.button.setTitle(portkiNodes[indexPath.row].nodeName, for: .normal)
            cell.plusButton.isEnabled = tableView.isEditing ? false : true
            return cell
        case "Screen":
            let cell = tableView.dequeueReusableCell(withIdentifier: "ScreenCell", for: indexPath) as! ScreenTableViewCell
            cell.delegate = self
            cell.indexPath = indexPath
            var newRect = cell.indentView.frame
            // now change x value & reassign to indentview
            let indentAmount = CGFloat(portkiNodes[indexPath.row].hierarchyLevel*indentBase)
            newRect = CGRect(x: indentAmount, y: newRect.origin.y, width: newRect.width, height: newRect.height)
            UIView.animate(withDuration: 0.5, animations: {cell.indentView.frame = newRect})
            let parentIndex = portkiNodes.firstIndex(where: {$0.documentID == portkiNodes[indexPath.row].parentID})
            if let parentIndex = parentIndex {
                if portkiNodes[parentIndex].childrenIDs.count > 1 {
                    cell.screenIcon.image = UIImage(named:  "screenGroup")
                } else {
                    cell.screenIcon.image = UIImage(named:  "singleScreen")
                }
            }
            if tableView.isEditing {
                cell.plusButton.isEnabled = false
                cell.disclosureButton.isEnabled = false
            } else {
                cell.plusButton.isEnabled = true
                cell.disclosureButton.isEnabled = true
            }
            return cell
        default:
            print("*** ERROR: cellForRowAt had incorrect case.")
            return UITableViewCell()
        }
    }
    
    func deleteFileFromCloud(fileName: String) {
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.USEast1,
                                                                identityPoolId:"us-east-1:93b4d97e-1aaa-43a3-99f3-ae183b5a8b86")
        guard let configuration = AWSServiceConfiguration(region:.USEast1, credentialsProvider:credentialsProvider) else {
            print("😡 ERROR: Could not initialize AWSServiceConfiguration in deleteFileFromCloud")
            return
        }
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        AWSS3.register(with: configuration, forKey: "defaultKey")
        let s3 = AWSS3.s3(forKey: "defaultKey")
        let deleteObjectRequest = AWSS3DeleteObjectRequest()
        deleteObjectRequest?.bucket = awsBucketName
        deleteObjectRequest?.key = fileName
        s3.deleteObject(deleteObjectRequest!).continueWith { (task:AWSTask) -> AnyObject? in
            if let error = task.error {
                print("Error occurred: \(error)")
                return nil
            }
            print("AWS file named \(fileName) deleted successfully.")
            return nil
        }
    }
    
    func deleteFileOnDevice(fileName: String) {
        let imageType = "jpeg"
        let fileURL = getDocumentsDirectory().appendingPathComponent("\(fileName).\(imageType)")
        do {
            let fileManager = FileManager.default
            try fileManager.removeItem(at: fileURL)
            print("Successfully deleted file named \(fileName) from iOS device")
        } catch {
            print("ERROR: Couldn't remove file named \(fileName) on iOS device")
        }
    }
    
    func deleteNodesFromTable(selectedIndex: Int) {
        print("** selectedIndex = \(selectedIndex)")
        print("** portkiNodes[selectedIndex] = \(portkiNodes[selectedIndex])")
        if portkiNodes[selectedIndex].childrenIDs.count > 0 {
            for childID in portkiNodes[selectedIndex].childrenIDs { // loop through all children
                if let childIndex = portkiNodes.firstIndex(where: {$0.documentID == childID}) {
                    print("   calling deleteNodesFromTable for index: \(childIndex) and documentID \(portkiNodes[childIndex].documentID)")
                    deleteNodesFromTable(selectedIndex: childIndex ) // and sort its children, if any
                }
            }
        }
        // First remove the element from its parent's array of childrenIDs
        // First find the parent's index
        if let parentIndex = portkiNodes.firstIndex(where: {$0.documentID == portkiNodes[selectedIndex].parentID}) {
            // then find the child's ID in the parent's index & remove that element.
            if let childIndex = portkiNodes[parentIndex].childrenIDs.firstIndex(where: {$0 == portkiNodes[selectedIndex].documentID}) {
                // remove value here
                let fileName = portkiNodes[parentIndex].childrenIDs[childIndex]
                print("** I am deleting a node named \(fileName)")
                portkiNodes[parentIndex].childrenIDs.remove(at: childIndex)
            } else {
                print("😡 ERROR: Couldn't find the index of child in it's parent's .childrenIDs. This should not have happened. YOU SHOULD NEVER SEE THIS MESSAGE.")
            }
        }
        // then remove the element itself:
        var fileName = portkiNodes[selectedIndex].documentID
        print("** I am deleting a node named \(fileName)")
        portkiNodes.remove(at: selectedIndex)
        deleteFileFromCloud(fileName: fileName+".jpeg")
        deleteFileOnDevice(fileName: fileName+".jpeg")
        if fileName.hasSuffix(".jpeg") {
            deleteFileOnDevice(fileName: fileName+".json")
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        print("Nodes Before Delete")
        print(portkiNodes)
        print("")
        if editingStyle == .delete {
            // if it's a screen
            if portkiNodes[indexPath.row].nodeType == "Screen" {
                // find it's parent
                if let parentIndex = portkiNodes.firstIndex(where: {$0.documentID == portkiNodes[indexPath.row].parentID}) {
                    // if its parent has only one child, then it must be a button that would have no children after deleting selected child, so delete starting with the parent's index
                    if portkiNodes[parentIndex].childrenIDs.count == 1 {
                        deleteNodesFromTable(selectedIndex: parentIndex)
                    } else {
                        deleteNodesFromTable(selectedIndex: indexPath.row)
                    }
                } else {
                    print("😡 ERROR: Couldn't find the index of $0.documentIDs parent. This should not have happened. YOU SHOULD NEVER SEE THIS MESSAGE.")
                }
            } else {
                // start deleting from selected index.
                deleteNodesFromTable(selectedIndex: indexPath.row)
            }
            tableView.reloadData()
            print("Nodes AFTER Delete")
            print(portkiNodes)
        }
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        // First make a copy of the item that you are going to move
        let itemToMove = portkiNodes[sourceIndexPath.row]
        // Delete item from the original location (pre-move)
        portkiNodes.remove(at: sourceIndexPath.row)
        // Insert item into the "to", post-move, location
        portkiNodes.insert(itemToMove, at: destinationIndexPath.row)
    }
    
    //MARK:- tableView methods to freeze the Home cell (first cell in array
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return (indexPath.row != 0 ? true : false)
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return (indexPath.row != 0 ? true : false)
    }
    
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        return (proposedDestinationIndexPath.row == 0 ? sourceIndexPath : proposedDestinationIndexPath)
    }
}

// Created protocol to handle clicks within custom cells
extension ScreenListViewController: PlusAndDisclosureDelegate {
    
    func findInsertionIndex(lastChild: Int) -> Int {
        if portkiNodes[lastChild].childrenIDs.count > 0 {
            
            if let lastChildIndex = portkiNodes.firstIndex(where: {$0.documentID == portkiNodes[lastChild].childrenIDs.last!}) {
                findInsertionIndex(lastChild: lastChildIndex)
            }
        }
        return lastChild
    }
    
    func addAButtonAndScreen(buttonName: String, indexPath: IndexPath) {
        let newButtonID = UUID().uuidString
        let newPageID = UUID().uuidString
        let newButton = PortkiNode(nodeName: buttonName, nodeType: "Button", parentID: portkiNodes[indexPath.row].documentID, hierarchyLevel: portkiNodes[indexPath.row].hierarchyLevel+1, childrenIDs: [newPageID], backgroundImageUUID: "", documentID: newButtonID)
        let newScreen = PortkiNode(nodeName: buttonName, nodeType: "Screen", parentID: newButtonID, hierarchyLevel: portkiNodes[indexPath.row].hierarchyLevel+2, childrenIDs: [String](), backgroundImageUUID: "", documentID: newPageID)
        
        // trying to add nodes first before creating buttons to see if this helps.
        portkiNodes[indexPath.row].childrenIDs.append(newButtonID)
        portkiNodes.append(newButton)
        portkiNodes.append(newScreen)
        
        
        // Also setup new PortkiScreen and add it to PortkiScreens, this is what will be saved to json for use on PyPortal
        
        // var buttonInfoArray = buildButtonArray(portkiNode: newScreen)
        // Also setup new PortkiScreen and add it to PortkiScreens, this is what will be saved to json for use on PyPortal
        var buttons = createLeftRightBackButtons(portkiNode: newScreen)
        let leafButtons = createLeafButtons(portkiNode: newScreen)
        buttons += getButtonsFromUIButtons(leafButtons: leafButtons, portkiNode: newScreen)
        
        portkiScreens.append(PortkiScreen(pageID: newPageID, buttons: buttons, screenURL: ""))
        
        tableView.reloadData()
        let selectedIndexPath = IndexPath(row: portkiNodes.count-1, section: indexPath.section)
        self.tableView.selectRow(at: selectedIndexPath, animated: true, scrollPosition: .none)
        self.performSegue(withIdentifier: "AddScreen", sender: nil)
    }
    
    func addScreen(indexPath: IndexPath) {
        let newPageID = UUID().uuidString
        let newScreen = PortkiNode(nodeName: portkiNodes[indexPath.row].nodeName, nodeType: "Screen", parentID: portkiNodes[indexPath.row].documentID, hierarchyLevel: portkiNodes[indexPath.row].hierarchyLevel+1, childrenIDs: [String](), backgroundImageUUID: "", documentID: newPageID)
        
        // Now add the new nodes + indexPaths and reload data
        
        portkiNodes[indexPath.row].childrenIDs.append(newPageID)
        portkiNodes.append(newScreen)
        
        // Also setup new PortkiScreen and add it to PortkiScreens, this is what will be saved to json for use on PyPortal
        
        // var buttonInfoArray = buildButtonArray(portkiNode: newScreen)
        // Also setup new PortkiScreen and add it to PortkiScreens, this is what will be saved to json for use on PyPortal
        var buttons = createLeftRightBackButtons(portkiNode: newScreen)
        let leafButtons = createLeafButtons(portkiNode: newScreen)
        buttons += getButtonsFromUIButtons(leafButtons: leafButtons, portkiNode: newScreen)
        portkiScreens.append(PortkiScreen(pageID: newPageID, buttons: buttons, screenURL: ""))
        
        tableView.reloadData()
        let selectedIndexPath = IndexPath(row: portkiNodes.count-1, section: indexPath.section)
        self.tableView.selectRow(at: selectedIndexPath, animated: true, scrollPosition: .none)
        self.performSegue(withIdentifier: "AddScreen", sender: nil)
    }
    
    func didTapPlusButton(at indexPath: IndexPath) {
        switch portkiNodes[indexPath.row].nodeType {
        case "Screen", "Home":
            showInputDialog(title: nil,
                            message: "Open new screen with a button named:",
                            actionTitle: "Create Button",
                            cancelTitle: "Cancel",
                            inputPlaceholder: nil,
                            inputKeyboardType: .default,
                            actionHandler: {(input:String?) in
                                guard let screenName = input else {
                                    return
                                }
                                self.addAButtonAndScreen(buttonName: screenName, indexPath: indexPath)},
                            cancelHandler: nil)
        case "Button":
            showTwoButtonAlert(title: nil,
                               message: "Create a new screen from button \(portkiNodes[indexPath.row].nodeName):",
                actionTitle: "Create Screen",
                cancelTitle: "Cancel",
                actionHandler: {_ in self.addScreen(indexPath: indexPath)},
                cancelHandler: nil)
        default:
            print("ERROR in default case of didTapPlusButton")
        }
    }
    
    func didTapDisclosure(at indexPath: IndexPath) {
        print("*** You Tapped the Disclosure Button at \(indexPath.row)")
        self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        self.performSegue(withIdentifier: "ShowScreen", sender: nil)
    }
}

extension ScreenListViewController {
    // Organizing all of the code to generate buttons
    func createButton(buttonName: String) -> UIButton {
        let screenViewRect = CGRect(x: 0, y: 0, width: 320, height: 240)
        screenView = UIView(frame: screenViewRect)
        let newButton = UIButton(frame: screenView.frame)
        newButton.setTitle(buttonName, for: .normal)
        newButton.titleLabel?.font = .boldSystemFont(ofSize: 13.0)
        newButton.sizeToFit()
        newButton.frame = CGRect(x: newButton.frame.origin.x, y: newButton.frame.origin.y, width: newButton.frame.width + (ButtonPadding.paddingAroundText*2), height: newButton.frame.height)
        newButton.backgroundColor = UIColor.init(hexString: "923125")
        return newButton
    }
    
    func createLeafButtons(portkiNode: PortkiNode) -> [UIButton] {
        var leafButtons: [UIButton] = []
        var buttons: [Button] = []
        
        // These are the buttons along the bottom of a screen that transition to a new outward "leaf" screen. They are not the xPrev, xNext, or xBack buttons.
        // no buttons to create if there aren't any children
        guard portkiNode.childrenIDs.count > 0 else {
            return leafButtons
        }
        
        var buttonNames = [String]() // clear out button names
        for childID in portkiNode.childrenIDs { // loop through all childIDs
            if let buttonNode = portkiNodes.first(where: {$0.documentID == childID}) { // if you can find an node with that childID
                buttonNames.append(buttonNode.nodeName) // add it's name to buttonNames
            }
        }
        
        // create a button (in actionButtons) for each buttonName
        for buttonName in buttonNames {
            leafButtons.append(createButton(buttonName: buttonName))
        }
        
        // position action buttons
        // 12 & 12 from lower right-hand corner
        let indent: CGFloat = 12.0
        // start in lower-left of screenView
        var buttonX: CGFloat = 0.0
        // var buttonX = screenView.frame.origin.x
        let buttonY = screenView.frame.height-indent-leafButtons[0].frame.height
        
        for button in leafButtons {
            var buttonFrame = button.frame
            buttonX = buttonX + indent
            buttonFrame = CGRect(x: buttonX, y: buttonY, width: buttonFrame.width, height: buttonFrame.height)
            button.frame = buttonFrame
            // screenView.addSubview(button)
            buttonX = buttonX + button.frame.width // move start portion of next button rect to the end of the current button rect
        }
        
        if portkiNode.nodeType == "Home" {
            var widthOfAllButtons = leafButtons.reduce(0.0,{$0 + $1.frame.width})
            widthOfAllButtons = widthOfAllButtons + (CGFloat(leafButtons.count-1)*indent)
            var shiftedX = (screenView.frame.width-widthOfAllButtons)/2
            
            for button in leafButtons {
                button.frame.origin.x = shiftedX
                shiftedX = shiftedX + button.frame.width + indent
            }
        }
        
        return leafButtons
    }
    
    func getButtonsFromUIButtons(leafButtons: [UIButton], portkiNode: PortkiNode) -> [Button] {
        var buttons: [Button] = []
        for index in 0..<leafButtons.count {
            let buttonCoordinates = ButtonCoordinates(x: leafButtons[index].frame.origin.x, y: leafButtons[index].frame.origin.y, width: leafButtons[index].frame.width, height: leafButtons[index].frame.height)
            let buttonName = leafButtons[index].titleLabel?.text ?? "NO TITLE"
            
            let childButtonID = portkiNode.childrenIDs[index]
            // find node for child button ID. find out which page this button points to.
            let foundButtonDestinationIndex = portkiNodes.firstIndex(where: {$0.documentID == childButtonID})
            guard let buttonDestinationIndex = foundButtonDestinationIndex else {
                print("😡 Unexpected: unable to find buttonDestinationIndex \(childButtonID) in portkiNodes")
                continue
            }
            let foundFirstChildID = portkiNodes[buttonDestinationIndex].childrenIDs.first
            guard let buttonDestination = foundFirstChildID else {
                print("😡 Unexpected: could not find a first child that buttonID \(portkiNodes[buttonDestinationIndex].documentID) points to")
                continue
            }
            let button = Button(text: buttonName, buttonCoordinates: buttonCoordinates, buttonDestination: buttonDestination)
            buttons.append(button)
        }
        return buttons
    }
    
    func createLeftRightBackButtons(portkiNode: PortkiNode) -> [Button] {
        var buttons: [Button] = []
        guard portkiNode.nodeType != "Home" else {
            return buttons // Home has no xLeft, xRight, xBack
        }
        
        let foundParentButton = portkiNodes.first(where: {$0.documentID == portkiNode.parentID})
        guard let parentButton = foundParentButton else { // unwrap found parent
            if portkiNode.nodeType != "Home" {
                print("😡 ERROR: could not get the node's parentButton")
            }
            return buttons
        }
        
        // Make a back button - all screens other than home have a Back button.
        let foundBackButtonDestination = portkiNodes.first(where: {$0.documentID == parentButton.parentID})
        guard let backButtonDestination = foundBackButtonDestination else { // unwrap found parent
            if portkiNode.nodeType != "Home" {
                print("😡 ERROR: could not get the node's backButtonDestination")
            }
            return buttons
        }
        var buttonCoordinates = ButtonCoordinates(x: 269, y: 188, width: 44, height: 44)
        var button = Button(text: "xBack", buttonCoordinates: buttonCoordinates, buttonDestination: backButtonDestination.documentID)
        buttons.append(button)
        
        // If this button has no siblings, then you're done
        if parentButton.childrenIDs.count < 2 {
            return buttons
        }
        
        // since there are siblings, then make "xLeft" and "xRight" buttons
        let foundButtonIndexInChildID = parentButton.childrenIDs.firstIndex(of: portkiNode.documentID)
        guard let buttonIndexInChildID = foundButtonIndexInChildID else {
            print("😡 ERROR: Couldn't find buttonIndexInChildID even though parentButton.childrenIDs.count >= 2")
            return buttons
        }
        var destinationIndex = buttonIndexInChildID - 1 // destination for xLeft is previous
        if destinationIndex < 0 { // if already at beginning, go to the end
            destinationIndex = parentButton.childrenIDs.count-1
        }
        // make the xLeft button
        buttonCoordinates = ButtonCoordinates(x: 0, y: 88, width: 30, height: 44)
        button = Button(text: "xLeft", buttonCoordinates: buttonCoordinates, buttonDestination: parentButton.childrenIDs[destinationIndex] )
        buttons.append(button)
        
        // now for xRight, which should be one index value greater
        destinationIndex = buttonIndexInChildID + 1 // destination for xLeft is previous
        if destinationIndex >= parentButton.childrenIDs.count { // if already at end, go to the beginning
            destinationIndex = 0
        }
        // since there are siblings, then make "xPrev" and "xNext" buttons
        buttonCoordinates = ButtonCoordinates(x: 290, y: 88, width: 30, height: 44)
        button = Button(text: "xRight", buttonCoordinates: buttonCoordinates, buttonDestination: parentButton.childrenIDs[destinationIndex] )
        buttons.append(button)
        
        return buttons
    }
}

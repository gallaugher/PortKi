//
//  ScreenListViewController.swift
//  PortKi
//
//  Created by John Gallaugher on 5/14/19.
//  Copyright © 2019 John Gallaugher. All rights reserved.
//

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher
import Alamofire
import SwiftyJSON

class ScreenListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    // used simply to calculate button properties to be used in PyPortal via portkiScreens converted to JSON
    @IBOutlet var screenView: UIView!
    
    let googleDriveService = GTLRDriveService()
    var googleUser: GIDGoogleUser?
    var uploadFolderID: String?
    let filesFolderName = "portki-files"
    
    var portkiScreens: [PortkiScreen] = []
    var portkiNodes: [PortkiNode] = []
    var newNodes: [PortkiNode] = []
    let indentBase = 26 // how far to indent button/screen levels
    var imageURL = "https://gallaugher.com/wp-content/uploads/2009/08/John-White-Border-Beard-Crossed-Arms-Photo.jpg"
    
    override func viewDidLoad() {
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance()?.scopes =
            [kGTLRAuthScopeDrive]
        GIDSignIn.sharedInstance()?.signIn()
        //        GIDSignIn.sharedInstance().signInSilently()
        
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
    
    func setUpFirstNodesIfNoNodesExist(){
        if portkiNodes.isEmpty {
            // if there are no portkiNodes then there must not be any portkiScreens, either
            // If there are no portkiScreens, then create new "Home" screen and new "Home" node.
            portkiScreens.append(PortkiScreen(pageID: "Home", buttons: [Button]()))
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
        let filename = getDocumentsDirectory().appendingPathComponent("portkiNodes.json")
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
                portkiNodes = try decoder.decode([PortkiNode].self, from: convertedJsonData)
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
        if segue.identifier == "ShowScreen" {
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
            
        } else { // adding a screen pass the last element - we'll sort them when they're back. No need to worry about deselecting
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
        }
    }
    
    @IBAction func unwindFromScreenDesignViewController(segue: UIStoryboardSegue) {
        let sourceViewController = segue.source as! ScreenDesignViewController
        // Unwind only happens on "Save" press, not cancel, so you should always need to update the portkiNode
        
        // First update portkiScreens - the data structure used to create JSON for the PyPortal:
        let portkiScreen = sourceViewController.portkiScreen!
        let portkiScreenIndex = portkiScreens.firstIndex(where: {$0.pageID == portkiScreen.pageID})
        
        // TODO: Unsure if I'm doing anything on the design screen that requires passing back a modified portkiScreen. Need to think about whether info below is even necessary.
        if let portkiScreenIndex = portkiScreenIndex {
            portkiScreens[portkiScreenIndex] = portkiScreen
            print(">> Must have UPDATED a screen in unwindFromScreenDesignVC")
        } else {
            print("😡😡 ERROR IN unwindFromScreenDesignVC - since portKiScreens were created before transfer, then there should be on already and you shouldn't have to create a new one.")
            portkiScreens.append(portkiScreen)
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
            //            if let response = response {
            //                print(response)
            //            }
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
        for index in 0..<portkiScreens.count {
            let foundNodeIndexForScreen = portkiNodes.firstIndex(where: {$0.documentID == portkiScreens[index].pageID})
            guard let nodeIndexForScreen = foundNodeIndexForScreen else {
                print("😡 For some reason there wasn't a portkiNode with documentID \(portkiScreens[index].pageID)")
                continue // No
            }
            var buttons = createLeftRightBackButtons(portkiNode: portkiNodes[nodeIndexForScreen])
            let leafButtons = createLeafButtons(portkiNode: portkiNodes[nodeIndexForScreen])
            buttons += getButtonsFromUIButtons(leafButtons: leafButtons, portkiNode: portkiNodes[nodeIndexForScreen])
            portkiScreens[index].buttons = buttons
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let encoded = try? encoder.encode(portkiScreens) {
            if let jsonString = String(data: encoded, encoding: .utf8) {
                // print(jsonString)
                
                let parameters = ["value": jsonString]
                guard let json = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
                    print("😡 Grr. json conversion didn't work")
                    return
                }
                print("** JSON Conversion Worked !!!")
                // print(json)
                
                let fileNameURL = getDocumentsDirectory().appendingPathComponent("portkiScreens.json")
                do {
                    try json.write(to: fileNameURL, options: .atomic)
                    writeJsonFileToGoogleDrive(fileNameURL: fileNameURL)
                    sendJsonToAdafruitIo(jsonString: jsonString)
                } catch {
                    print("😡 Grr. json wasn't writte to file \(error.localizedDescription)")
                }
            }
        } else {
            print("encoding didn't work")
        }
    }
}

// NOTE: This is where I write files to Google Drive
extension ScreenListViewController {
    
    func writeAllImagesToGoogleDrive() {
        for portkiScreen in portkiScreens {
            let fileNameURL = getDocumentsDirectory().appendingPathComponent("\(portkiScreen.pageID).bmp")
            
            if let uploadFolderID = self.uploadFolderID {
                self.uploadFile(name: "\(portkiScreen.pageID).bmp", folderID: uploadFolderID, fileURL: fileNameURL, mimeType: "image/bmp", service: self.googleDriveService)
            }
        }
    }
    
    func writeJsonFileToGoogleDrive(fileNameURL: URL) {
        // Now try writing json to the Google Drive
        // let fileURL = Bundle.main.url(forResource: "my-image", withExtension: ".png")
        
        getFolderID(name: filesFolderName, service: googleDriveService, user: googleUser!) { folderID in
            if folderID == nil {
                self.createFolder(name: self.filesFolderName,service: self.googleDriveService) { self.uploadFolderID = $0
                    if let uploadFolderID = self.uploadFolderID {
                        self.uploadFile(name: "portki.json", folderID: uploadFolderID, fileURL: fileNameURL, mimeType: "application/json", service: self.googleDriveService)
                        self.writeAllImagesToGoogleDrive()
                    }
                }
            } else {
                // Folder already exists
                self.uploadFolderID = folderID
                if let uploadFolderID = self.uploadFolderID {
                    self.uploadFile(name: "portki.json", folderID: uploadFolderID, fileURL: fileNameURL, mimeType: "application/json", service: self.googleDriveService)
                    self.writeAllImagesToGoogleDrive()
                }
            }
        }
    }
    
    func getFolderID(name: String, service: GTLRDriveService, user: GIDGoogleUser, completion: @escaping (String?) -> Void) {
        
        let query = GTLRDriveQuery_FilesList.query()
        
        // Comma-separated list of areas the search applies to. E.g., appDataFolder, photos, drive.
        query.spaces = "drive"
        
        // Comma-separated list of access levels to search in. Some possible values are "user,allTeamDrives" or "user"
        query.corpora = "user"
        
        let withName = "name = '\(name)'" // Case insensitive!
        let foldersOnly = "mimeType = 'application/vnd.google-apps.folder'"
        let ownedByUser = "'\(user.profile!.email!)' in owners"
        query.q = "\(withName) and \(foldersOnly) and \(ownedByUser)"
        
        service.executeQuery(query) { (_, result, error) in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            
            let folderList = result as! GTLRDrive_FileList
            
            // For brevity, assumes only one folder is returned.
            completion(folderList.files?.first?.identifier)
        }
    }
    
    func createFolder(name: String, service: GTLRDriveService, completion: @escaping (String) -> Void) {
        
        let folder = GTLRDrive_File()
        folder.mimeType = "application/vnd.google-apps.folder"
        folder.name = name
        
        // Google Drive folders are files with a special MIME-type.
        let query = GTLRDriveQuery_FilesCreate.query(withObject: folder, uploadParameters: nil)
        //let folderPermission =  GTLRDrive_Permission
        
        service.executeQuery(query) { (_, file, error) in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            
            let folder = file as! GTLRDrive_File
            completion(folder.identifier!)
        }
    }
    
    func uploadFile(name: String, folderID: String, fileURL: URL, mimeType: String, service: GTLRDriveService) {
        let file = GTLRDrive_File()
        file.name = name
        file.parents = [folderID]
        
        // Optionally, GTLRUploadParameters can also be created with a Data object.
        let uploadParameters = GTLRUploadParameters(fileURL: fileURL, mimeType: mimeType)
        
        let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: uploadParameters)
        
        service.uploadProgressBlock = { _, totalBytesUploaded, totalBytesExpectedToUpload in
            // This block is called multiple times during upload and can
            // be used to update a progress indicator visible to the user.
        }
        
        service.executeQuery(query) { (_, result, error) in
            guard error == nil else {
                print("🚫 file \(name) was not uploaded to Google Drive \(folderID)")
                fatalError(error!.localizedDescription)
            }
            print("📁📁 File Successfully Uploaded to Google Drive! File name on drive is \(name)")
            
            // Successful upload if no error is returned.
        }
    }
}

extension ScreenListViewController: GIDSignInDelegate, GIDSignInUIDelegate {
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!,
              withError error: Error!) {
        if let error = error {
            self.googleDriveService.authorizer = nil
            self.googleUser = nil
            print("🥵🥵 \(error.localizedDescription)")
        } else {
            // Include authorization headers/values with each Drive API request.
            self.googleDriveService.authorizer = user.authentication.fetcherAuthorizer()
            self.googleUser = user
            print("🐶 WOO HOO! You signed in, dawg! ")
            // Perform any operations on signed in user here. I don't think I need any of this info, but keeping them here as a reference for now, as per tutorial, in case I need them later on.
            let userId = user.userID                  // For client-side use only!
            let idToken = user.authentication.idToken // Safe to send to the server
            let fullName = user.profile.name
            let givenName = user.profile.givenName
            let familyName = user.profile.familyName
            let email = user.profile.email
            // ...
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!,
              withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
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
            return cell
        default:
            print("*** ERROR: cellForRowAt had incorrect case.")
            return UITableViewCell()
        }
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
        
        portkiScreens.append(PortkiScreen(pageID: newPageID, buttons: buttons))
        
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
        portkiScreens.append(PortkiScreen(pageID: newPageID, buttons: buttons))
        
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

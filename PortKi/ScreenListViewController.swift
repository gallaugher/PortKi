//
//  ScreenListViewController.swift
//  PortKi
//
//  Created by John Gallaugher on 5/14/19.
//  Copyright © 2019 John Gallaugher. All rights reserved.
//

import UIKit
import CoreLocation
import Firebase
import FirebaseUI
import GoogleSignIn  // used to be called FirebaseGoogleAuthUI
import Alamofire
import SwiftyJSON

class ScreenListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    var portkiScreens: [PortkiScreen] = []
    var portkiNodes: [PortkiNode] = []
    var newElements: [Element] = []
    var elements: Elements!
    let indentBase = 26 // how far to indent button/screen levels
    var authUI: FUIAuth!
    
    override func viewDidLoad() {
        
        // initializing the authUI var and setting the delegate are step [3]
        authUI = FUIAuth.defaultAuthUI()
        authUI?.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isHidden = true
        
        elements = Elements()
        
        loadPortkiScreens()
        loadPortkiNodes()
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func loadPortkiScreens() {
        let filename = getDocumentsDirectory().appendingPathComponent("portkiScreens.json")
        do {
            let data = try Data(contentsOf: filename)
            print(data)
            let json = JSON(data)
            print(json["value"])
            
            print("now decoding")
            let decoder = JSONDecoder()
            let jsonString = json["value"].stringValue
            let convertedJsonData = Data(jsonString.utf8)
            do {
                portkiScreens = try decoder.decode([PortkiScreen].self, from: convertedJsonData)
                for node in portkiNodes {
                    print(node.nodeName)
                    print("   This screen has \(node.childrenIDs.count) children")
                }
            } catch {
                print(error.localizedDescription)
            }
        } catch {
            print("😡 Couldn't get json from file: error:\(error)")
        }
    }
    
    func loadPortkiNodes() {
        let filename = getDocumentsDirectory().appendingPathComponent("portkiNodes.json")
        do {
            let data = try Data(contentsOf: filename)
            print(data)
            let json = JSON(data)
            print(json["value"])
            
            print("now decoding")
            let decoder = JSONDecoder()
            let jsonString = json["value"].stringValue
            let convertedJsonData = Data(jsonString.utf8)
            do {
                portkiNodes = try decoder.decode([PortkiNode].self, from: convertedJsonData)
                for node in portkiNodes {
                    print(node.nodeName)
                    print("   This screen has \(node.childrenIDs.count) children")
                }
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
                print(jsonData)
                print("now decoding")
                let decoder = JSONDecoder()
                let jsonString = json["last_value"].stringValue
                let convertedJsonData = Data(jsonString.utf8)
                do {
                    self.portkiScreens = try decoder.decode([PortkiScreen].self, from: convertedJsonData)
                    for screen in self.portkiScreens {
                        print(screen.pageID)
                        print("   This screen has \(screen.buttons.count) buttons")
                    }
                } catch {
                    print(error.localizedDescription)
                }
            case .failure(let error):
                print("ERROR: \(error.localizedDescription) failed to get data from url \(apiURL)")
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        // NOTE: eventually read what's stored, but we're starting from scratch for now
        // loadPortkiScreens()
        
        if portkiNodes.isEmpty {
            // If there are no portkiScreens, then create new "Home" screen and new "Home" node.
            portkiScreens.append(PortkiScreen(pageID: "Home", buttons: [Button]()))
            portkiNodes.append(PortkiNode(nodeName: "Home", nodeType: "Home", parentID: "", hierarchyLevel: 0, childrenIDs: [String](), backgroundImageUUID: "", documentID: "Home"))
            
            // segue to next screen since you've just created a new tree with blank "Home" screen & nodes.
        } else {
            // TODO: Read in json for nodes from some location where you store it - either locally or at adafruit.io
            print(" >>> There are \(portkiNodes.count) portkiNodes")
        }
        
        //        if self.elements.elementArray.isEmpty {
        //            // TODO: deal with a first-time use setup where there is no home screen
        //
        //        } else {
        //            for screen in portkiScreens {
        //                if screen.pageID == "Home" {
        //                    var childrenIDs: [String] = []
        //                    for button in screen.buttons {
        //                        childrenIDs.append(button.buttonDestination)
        //                    }
        //                    portkiNodes.append(PortkiNode(nodeName: "Home", nodeType: "Home", parentID: "", hierarchyLevel: 0, childrenIDs: childrenIDs, backgroundImageUUID: "", backgroundImage: UIImage(), backgroundColor: UIColor.white, documentID: ""))
        //                    loadNextNode(portkiScreen: screen, hierarchyLevel: 0)
        //                    break
        //                }
        //            }
        //        }
        
        
        
        //        elements.loadData {
        //
        //            if self.elements.elementArray.isEmpty {
        //
        //                let homeElement = Element()
        //                homeElement.elementName = "Home"
        //                homeElement.elementType = "Home"
        //                homeElement.documentID = "Home"
        //                homeElement.backgroundColor = UIColor.white
        //
        //                homeElement.saveData(completed: { (success) in
        //                    if !success { // if failed
        //                        print("😡 ERROR: could not save a Home element.")
        //                        return
        //                    }
        //                    self.performSegue(withIdentifier: "AddScreen", sender: nil)
        //                })
        //            } else {
        //                self.elements.loadData {
        //                    self.newElements = []
        //                    guard let home = self.elements.elementArray.first(where: {$0.elementType == "Home"}) else {
        //                        print("ERROR: There was a problem finding the 'Home' element")
        //                        return
        //                    }
        //                    self.sortElements(element: home)
        //                    self.elements.elementArray = self.newElements
        //                    self.tableView.reloadData()
        //                }
        //            }
        //        }
    }
    
    //    func sortElements(element: Element) {
    //        newElements.append(element)
    //
    //        if !element.childrenIDs.isEmpty { // if there is at least one child for this element
    //            for childID in element.childrenIDs { // loop through all children
    //                if let child = elements.elementArray.first(where: {$0.documentID == childID}) {
    //                    sortElements(element: child ) // and sort its children, if any
    //                }
    //            }
    //        }
    //    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        signIn()
    }
    
    // Nothing should change unless you add different kinds of authentication.
    func signIn() {
        let providers: [FUIAuthProvider] = [
            FUIGoogleAuth(),
        ]
        if authUI.auth?.currentUser == nil {
            self.authUI?.providers = providers
            present(authUI.authViewController(), animated: true, completion: nil)
        } else {
            tableView.isHidden = false
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
        } else { // adding a screen pass the last element - we'll sort them when they're back. No need to worry about deselecting
            let navigationController = segue.destination as! UINavigationController
            let destination = navigationController.viewControllers.first as! ScreenDesignViewController
            destination.portkiNode = portkiNodes.last
            destination.portkiNodes = portkiNodes
        }
        
        
        //        if segue.identifier == "ShowScreen" {
        //            let destination = segue.destination as! ScreenDesignViewController
        //            let selectedIndexPath = tableView.indexPathForSelectedRow!
        //            let selectedElement = elements.elementArray[selectedIndexPath.row]
        //            if selectedElement.elementName != "Home" {
        //                let parentIndex = elements.elementArray.firstIndex(where: {$0.documentID == elements.elementArray[selectedIndexPath.row].parentID})
        //                if let parentIndex = parentIndex {
        //                    destination.siblingButtonIDArray = elements.elementArray[parentIndex].childrenIDs
        //                }
        //            }
        //            destination.element = elements.elementArray[selectedIndexPath.row]
        //            destination.elements = elements
        //        } else { // adding a screen pass the last element - we'll sort them when they're back. No need to worry about deselecting
        //            let navigationController = segue.destination as! UINavigationController
        //            let destination = navigationController.viewControllers.first as! ScreenDesignViewController
        //            destination.element = elements.elementArray.last
        //            destination.elements = elements
        //        }
    }
    
    @IBAction func signOutPressed(_ sender: UIBarButtonItem) {
        do {
            try authUI!.signOut()
            print("^^^ Successfully signed out!")
            tableView.isHidden = true
            signIn()
        } catch {
            tableView.isHidden = true
            print("*** ERROR: Couldn't sign out")
        }
    }
    
    @IBAction func unwindFromScreenDesignViewController(segue: UIStoryboardSegue) {
        let sourceViewController = segue.source as! ScreenDesignViewController
        if let indexPath = tableView.indexPathForSelectedRow {
            portkiNodes[indexPath.row] = sourceViewController.portkiNode!
            tableView.reloadRows(at: [indexPath], with: .automatic)
            
            let portkiScreen = sourceViewController.portkiScreen!
            let portkiScreenIndex = portkiScreens.firstIndex(where: {$0.pageID == portkiScreen.pageID})
            if let portkiScreenIndex = portkiScreenIndex {
                portkiScreens[portkiScreenIndex] = portkiScreen
                print(">> Must have UPDATED a screen in unwindFromScreenDesignVC")
            } else {
                portkiScreens.append(portkiScreen)
                print(">> Must have just added a screen in unwindFromScreenDesignVC")
            }
            
        } else {
            let newIndexPath = IndexPath(row: portkiNodes.count, section: 0)
            portkiNodes.append(sourceViewController.portkiNode!)
            tableView.insertRows(at: [newIndexPath], with: .automatic)
            
            portkiScreens.append(sourceViewController.portkiScreen!)
        }
    }
    
    
    @IBAction func updatePyPortalPressed(_ sender: UIBarButtonItem) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let encoded = try? encoder.encode(portkiScreens) {
            if let jsonString = String(data: encoded, encoding: .utf8) {
                print(jsonString)
                
                let parameters = ["value": jsonString]
                guard let json = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
                    print("😡 Grr. json conversion didn't work")
                    return
                }
                print("** JSON Conversion Worked !!!")
                print(json)
                
                let filename = getDocumentsDirectory().appendingPathComponent("portkiScreens.json")
                do {
                    try json.write(to: filename, options: .atomic)
                } catch {
                    print("😡 Grr. json wasn't writte to file \(error.localizedDescription)")
                }
            }
        } else {
            print("encoding didn't work")
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
        
        //        switch elements.elementArray[indexPath.row].elementType {
        //        case "Home":
        //            let cell = tableView.dequeueReusableCell(withIdentifier: "HomeCell", for: indexPath) as! HomeTableViewCell
        //            cell.delegate = self
        //            cell.indexPath = indexPath
        //            return cell
        //        case "Button":
        //            let cell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell", for: indexPath) as! ButtonTableViewCell
        //            cell.delegate = self
        //            cell.indexPath = indexPath
        //            var newRect = cell.indentView.frame
        //            // now change x value & reassign to indentview
        //            let indentAmount = CGFloat(elements.elementArray[indexPath.row].hierarchyLevel*indentBase)
        //            newRect = CGRect(x: indentAmount, y: newRect.origin.y, width: newRect.width, height: newRect.height)
        //            UIView.animate(withDuration: 0.5, animations: {cell.indentView.frame = newRect})
        //            cell.button.setTitle(elements.elementArray[indexPath.row].elementName, for: .normal)
        //            return cell
        //        case "Screen":
        //            let cell = tableView.dequeueReusableCell(withIdentifier: "ScreenCell", for: indexPath) as! ScreenTableViewCell
        //            cell.delegate = self
        //            cell.indexPath = indexPath
        //            var newRect = cell.indentView.frame
        //            // now change x value & reassign to indentview
        //            let indentAmount = CGFloat(elements.elementArray[indexPath.row].hierarchyLevel*indentBase)
        //            newRect = CGRect(x: indentAmount, y: newRect.origin.y, width: newRect.width, height: newRect.height)
        //            UIView.animate(withDuration: 0.5, animations: {cell.indentView.frame = newRect})
        //            let parentIndex = elements.elementArray.firstIndex(where: {$0.documentID == elements.elementArray[indexPath.row].parentID})
        //            if let parentIndex = parentIndex {
        //                if elements.elementArray[parentIndex].childrenIDs.count > 1 {
        //                    cell.screenIcon.image = UIImage(named:  "screenGroup")
        //                } else {
        //                    cell.screenIcon.image = UIImage(named:  "singleScreen")
        //                }
        //            }
        //            return cell
        //        default:
        //            print("*** ERROR: cellForRowAt had incorrect case.")
        //            return UITableViewCell()
        //        }
    }
}

// Name of the extension is likely the only thing that needs to change in new projects
extension ScreenListViewController: FUIAuthDelegate {
    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        let sourceApplication = options[UIApplication.OpenURLOptionsKey.sourceApplication] as! String?
        if FUIAuth.defaultAuthUI()?.handleOpen(url, sourceApplication: sourceApplication) ?? false {
            return true
        }
        // other URL handling goes here.
        return false
    }
    
    func authUI(_ authUI: FUIAuth, didSignInWith user: User?, error: Error?) {
        if let user = user {
            // Assumes data will be isplayed in a tableView that was hidden until login was verified so unauthorized users can't see data.
            tableView.isHidden = false
            print("^^^ We signed in with the user \(user.email ?? "unknown e-mail")")
        }
    }
    
    func authPickerViewController(forAuthUI authUI: FUIAuth) -> FUIAuthPickerViewController {
        
        // Create an instance of the FirebaseAuth login view controller
        let loginViewController = FUIAuthPickerViewController(authUI: authUI)
        
        // Set background color to white
        loginViewController.view.backgroundColor = UIColor.white
        
        // Create a frame for a UIImageView to hold our logo
        let marginInsets: CGFloat = 16 // logo will be 16 points from L and R margins
        let imageHeight: CGFloat = 225 // the height of our logo
        let imageY = self.view.center.y - imageHeight // places bottom of UIImageView in the center of the login screen
        let logoFrame = CGRect(x: self.view.frame.origin.x + marginInsets, y: imageY, width: self.view.frame.width - (marginInsets*2), height: imageHeight)
        
        // Create the UIImageView using the frame created above & add the "logo" image
        let logoImageView = UIImageView(frame: logoFrame)
        logoImageView.image = UIImage(named: "logo")
        logoImageView.contentMode = .scaleAspectFit // Set imageView to Aspect Fit
        loginViewController.view.addSubview(logoImageView) // Add ImageView to the login controller's main view
        return loginViewController
    }
}

// Created protocol to handle clicks within custom cells
extension ScreenListViewController: PlusAndDisclosureDelegate {
    
    func findInsertionIndex(lastChild: Int) -> Int {
        if portkiNodes[lastChild].childrenIDs.count > 0 {
            
            if let lastChildIndex = portkiNodes.firstIndex(where: {$0.documentID == portkiNodes[lastChild].childrenIDs.last!}) {
                findInsertionIndex(lastChild: lastChildIndex)
            }
//            findInsertionIndex(lastChild: lastChild+(portkiNodes[lastChild].childrenIDs.count))
        }
        return lastChild
    }
    
    func addAButtonAndScreen(buttonName: String, indexPath: IndexPath) {
        let newButtonID = UUID().uuidString
        let newPageID = UUID().uuidString
        let newButton = PortkiNode(nodeName: buttonName, nodeType: "Button", parentID: portkiNodes[indexPath.row].documentID, hierarchyLevel: portkiNodes[indexPath.row].hierarchyLevel+1, childrenIDs: [newPageID], backgroundImageUUID: "", documentID: newButtonID)
        let newScreen = PortkiNode(nodeName: buttonName, nodeType: "Screen", parentID: newButtonID, hierarchyLevel: portkiNodes[indexPath.row].hierarchyLevel+2, childrenIDs: [String](), backgroundImageUUID: "", documentID: newPageID)
        
        // let newScreen = Element(elementName: buttonName, elementType: "Screen", parentID: newButtonID, hierarchyLevel: elements.elementArray[indexPath.row].hierarchyLevel+2, childrenIDs: [String](), backgroundImageUUID: "", backgroundImage: UIImage(), backgroundColor: UIColor.white, documentID: newPageID)

        // Add the button you just added as a child of the screen in the row that you clicked + on
        // var parent = portkiNodes[indexPath.row]
        // parent.childrenIDs.append(newButtonID)
        
        // Now add the new nodes + indexPaths and reload data
        // var newIndexPath = IndexPath(row: indexPath.row+1, section: 0)
        
        // portkiNodes.append(newButton)
        
        var selectedIndexPathRow: Int!
        if portkiNodes[indexPath.row].childrenIDs.isEmpty {
            portkiNodes[indexPath.row].childrenIDs.append(newButtonID)
            // portkiNodes.append(newButton)
            // portkiNodes.append(newScreen)
            
            var insertionIndex: Int
            
            if indexPath.row == portkiNodes.count-1 {
                insertionIndex = portkiNodes.endIndex
            } else {
                insertionIndex = indexPath.row + 1
            }
            portkiNodes.insert(newButton, at: insertionIndex)
            portkiNodes.insert(newScreen, at: insertionIndex+1)
            selectedIndexPathRow = insertionIndex+1
        } else {
            var insertionIndex: Int
            insertionIndex = portkiNodes[indexPath.row].childrenIDs.count
            // find index of last child
            if let lastChildIndex = portkiNodes.firstIndex(where: {$0.documentID == portkiNodes[insertionIndex].childrenIDs.last!}) {
                insertionIndex = findInsertionIndex(lastChild: lastChildIndex)
            }
            portkiNodes[indexPath.row].childrenIDs.append(newButtonID)
            if insertionIndex == portkiNodes.count-1 {
                insertionIndex = portkiNodes.endIndex
            } else {
                insertionIndex = insertionIndex + 1
            }
            portkiNodes.insert(newButton, at: insertionIndex)
            portkiNodes.insert(newScreen, at: insertionIndex+1)
            selectedIndexPathRow = insertionIndex+1
        }
        tableView.reloadData()
        let selectedIndexPath = IndexPath(row: selectedIndexPathRow, section: 0)
        self.tableView.selectRow(at: selectedIndexPath, animated: true, scrollPosition: .none)
        self.performSegue(withIdentifier: "AddScreen", sender: nil)
        
//        var insertionIndex: Int
//        if portkiNodes[indexPath.row].childrenIDs.count > 0 {
//            insertionIndex = portkiNodes[indexPath.row].childrenIDs.count
//            // find index of last child
//            if let lastChildIndex = portkiNodes.firstIndex(where: {$0.documentID == portkiNodes[insertionIndex].childrenIDs.last!}) {
//                insertionIndex = findInsertionIndex(lastChild: lastChildIndex)
//            }
//        }

        // portkiNodes.insert(newButton, at: indexPath.row+parent.childrenIDs.count)
        
        // tableView.insertRows(at: [newIndexPath], with: .automatic)
        // newIndexPath = IndexPath(row: indexPath.row+2, section: 0)
        
        // portkiNodes.append(newScreen)
        // portkiNodes.insert(newScreen, at: indexPath.row+parent.childrenIDs.count+1)
        
        
        // tableView.insertRows(at: [newIndexPath], with: .automatic)

        // let selectedIndexPath = IndexPath(row: insertionIndex+1, section: indexPath.section)
//        let selectedIndexPath = IndexPath(row: indexPath.row+parent.childrenIDs.count, section: indexPath.section)
        
        // tableView.reloadData()
       
        
//        parent.saveData { (success) in
//            newButton.saveData { (success) in
//                guard success else {
//                    print("😡 ERROR: saving a newButton named \(buttonName)")
//                    return
//                }
//                newScreen.saveData { (success) in
//                    self.elements.elementArray[indexPath.row].childrenIDs.append(newButtonID)
//                    self.elements.elementArray.append(newButton)
//                    self.elements.elementArray.append(newScreen)
//                    let selectedIndexPath = IndexPath(row: indexPath.row, section: indexPath.section)
//                    self.tableView.selectRow(at: selectedIndexPath, animated: true, scrollPosition: .none)
//                    self.performSegue(withIdentifier: "AddScreen", sender: nil)
//                }
//            }
//        }
    }
    
    func addScreen(indexPath: IndexPath) {
        let newPageID = UUID().uuidString
        let newScreen = PortkiNode(nodeName: portkiNodes[indexPath.row].nodeName, nodeType: "Screen", parentID: portkiNodes[indexPath.row].documentID, hierarchyLevel: portkiNodes[indexPath.row].hierarchyLevel+1, childrenIDs: [String](), backgroundImageUUID: "", documentID: newPageID)
        // let newScreen = Element(elementName: elements.elementArray[indexPath.row].elementName, elementType: "Screen", parentID: elements.elementArray[indexPath.row].documentID, hierarchyLevel: elements.elementArray[indexPath.row].hierarchyLevel+1, childrenIDs: [String](), backgroundImageUUID: "", backgroundImage: UIImage(), backgroundColor: UIColor.white, documentID: newPageID)
        
        
        // Now add the new nodes + indexPaths and reload data
        
        // portkiNodes.append(newScreen)
        // portkiNodes.insert(newScreen, at: indexPath.row+portkiNodes[indexPath.row].childrenIDs.count-1)
        
        
        var selectedIndexPathRow: Int!
        var insertionIndex: Int
        insertionIndex = portkiNodes[indexPath.row].childrenIDs.count
        // find index of last child
        if portkiNodes[insertionIndex].childrenIDs.isEmpty {
            portkiNodes[indexPath.row].childrenIDs.append(newPageID)

            var insertionIndex: Int
            
            if indexPath.row == portkiNodes.count-1 {
                insertionIndex = portkiNodes.endIndex
            } else {
                insertionIndex = indexPath.row + 1
            }
            portkiNodes.insert(newScreen, at: insertionIndex)
            selectedIndexPathRow = insertionIndex
        } else {
            var insertionIndex: Int
            insertionIndex = portkiNodes[indexPath.row].childrenIDs.count
            // find index of last child
            if let lastChildIndex = portkiNodes.firstIndex(where: {$0.documentID == portkiNodes[insertionIndex].childrenIDs.last!}) {
                insertionIndex = findInsertionIndex(lastChild: lastChildIndex)
            }
            portkiNodes[indexPath.row].childrenIDs.append(newPageID)
            if insertionIndex == portkiNodes.count-1 {
                insertionIndex = portkiNodes.endIndex
            } else {
                insertionIndex = insertionIndex + 1
            }
            portkiNodes.insert(newScreen, at: insertionIndex)
            selectedIndexPathRow = insertionIndex
        }
        
        tableView.reloadData()
        let selectedIndexPath = IndexPath(row: selectedIndexPathRow, section: 0)
        self.tableView.selectRow(at: selectedIndexPath, animated: true, scrollPosition: .none)
        self.performSegue(withIdentifier: "AddScreen", sender: nil)
        
//        selectedIndexPathRow = insertionIndex+1
//
//
        tableView.reloadData()
        // let selectedIndexPath = IndexPath(row: indexPath.row+portkiNodes[indexPath.row].childrenIDs.count-1, section: indexPath.section)
//        self.tableView.selectRow(at: selectedIndexPathRow, animated: true, scrollPosition: .none)
//        let selectedIndexPath = IndexPath(row: indexPath.row, section: indexPath.section)
//        self.tableView.selectRow(at: selectedIndexPath, animated: true, scrollPosition: .none)
        self.performSegue(withIdentifier: "AddScreen", sender: nil)

        
//        parent.saveData { (success) in
//            newScreen.saveData { (success) in
//                self.elements.elementArray[indexPath.row].childrenIDs.append(newPageID)
//                self.elements.elementArray.append(newScreen)
//
//                let selectedIndexPath = IndexPath(row: indexPath.row, section: indexPath.section)
//                self.tableView.selectRow(at: selectedIndexPath, animated: true, scrollPosition: .none)
//                self.performSegue(withIdentifier: "AddScreen", sender: nil)
//            }
//        }
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
        //        let selectedIndexPath = IndexPath(row: indexPath.row, section: indexPath.section)
        //        self.tableView.selectRow(at: selectedIndexPath, animated: true, scrollPosition: .none)
        self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        self.performSegue(withIdentifier: "ShowScreen", sender: nil)
    }
}


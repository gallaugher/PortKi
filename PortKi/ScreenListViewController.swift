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
    var newNodes: [PortkiNode] = []
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
        setUpFirstNodesIfNoNodesExist()
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
    
    override func viewWillAppear(_ animated: Bool) {
        
        print("VWA VWA viewWillAppear HAPPENING NOW VWA VWA")
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
        
        // NOTE: eventually read what's stored, but we're starting from scratch for now
        // loadPortkiScreens()
        
    }
    
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
        print("UUUUU UNWIND HAPPENING NOW UUUU")
        let sourceViewController = segue.source as! ScreenDesignViewController
        // Unwind only happens on "Save" press, not cancel, so you should always need to update the portkiNode
        
        // First update portkiScreens - the data structure used to create JSON for the PyPortal:
        let portkiScreen = sourceViewController.portkiScreen!
        let portkiScreenIndex = portkiScreens.firstIndex(where: {$0.pageID == portkiScreen.pageID})
        
        // TODO: return to this to check if I should be creating the screen when I create the node. I think I should. And if I do, then I may be able to get rid of the if else below.
        if let portkiScreenIndex = portkiScreenIndex {
            portkiScreens[portkiScreenIndex] = portkiScreen
            print(">> Must have UPDATED a screen in unwindFromScreenDesignVC")
        } else {
            portkiScreens.append(portkiScreen)
            print(">> Must have just added a new screen in unwindFromScreenDesignVC")
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
        }
        return lastChild
    }
    
    func addAButtonAndScreen(buttonName: String, indexPath: IndexPath) {
        let newButtonID = UUID().uuidString
        let newPageID = UUID().uuidString
        let newButton = PortkiNode(nodeName: buttonName, nodeType: "Button", parentID: portkiNodes[indexPath.row].documentID, hierarchyLevel: portkiNodes[indexPath.row].hierarchyLevel+1, childrenIDs: [newPageID], backgroundImageUUID: "", documentID: newButtonID)
        let newScreen = PortkiNode(nodeName: buttonName, nodeType: "Screen", parentID: newButtonID, hierarchyLevel: portkiNodes[indexPath.row].hierarchyLevel+2, childrenIDs: [String](), backgroundImageUUID: "", documentID: newPageID)
        
        portkiNodes[indexPath.row].childrenIDs.append(newButtonID)
        portkiNodes.append(newButton)
        portkiNodes.append(newScreen)
        
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
        //        let selectedIndexPath = IndexPath(row: indexPath.row, section: indexPath.section)
        //        self.tableView.selectRow(at: selectedIndexPath, animated: true, scrollPosition: .none)
        self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        self.performSegue(withIdentifier: "ShowScreen", sender: nil)
    }
}


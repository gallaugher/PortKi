//
//  ScreenDesignViewController.swift
//  PortKi
//
//  Created by John Gallaugher on 5/21/19.
//  Copyright © 2019 John Gallaugher. All rights reserved.
//

import UIKit
import ColorSlider

class ScreenDesignViewController: UIViewController, UITextFieldDelegate {
    
    enum StyleButtons: Int {
        case bold = 0
        case italic = 1
        case underline = 2
    }
    
    enum BackgroundImageStatus {
        case unchanged
        case save
        case delete
    }
    
    @IBOutlet weak var screenView: UIView! // a view with fixed dimensions, same size as the PyPortal's screen
    // The content view is inside the screenView, all interface portkiNodes are configured to the contentView, so any shifting of contentView will shift all portkiNodes by the same amount.
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var grayBackgroundView: UIView!
    @IBOutlet var fieldCollection: [UITextField] = [] // Not connected, fields created programmatically
    @IBOutlet weak var deleteTextButton: UIButton!
    @IBOutlet weak var editStyleBarButton: UIBarButtonItem!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var alignmentSegmentedControl: UISegmentedControl!
    @IBOutlet weak var boldButton: ToggleButton!
    @IBOutlet weak var italicsButton: ToggleButton!
    @IBOutlet weak var underlineButton: ToggleButton!
    @IBOutlet weak var fontNameLabel: UILabel!
    @IBOutlet weak var fontListDisclosureButton: UIButton!
    @IBOutlet weak var fontSizeLabel: UILabel!
    @IBOutlet weak var sizeStepper: UIStepper!
    @IBOutlet weak var styleView: UIView!
    @IBOutlet weak var textColorStackView: UIStackView!
    @IBOutlet weak var textColorFrameView: UIView!
    @IBOutlet weak var textColorButton: UIButton!
    @IBOutlet weak var textBackgroundFrameView: UIView!
    @IBOutlet weak var textBackgroundButton: UIButton!
    @IBOutlet weak var textBackgroundStaticLabel: UILabel!
    @IBOutlet weak var screenBackgroundFrameView: UIView!
    @IBOutlet weak var screenBackgroundColorButton: UIButton!
    @IBOutlet weak var hexTextField: AllowedCharsTextField!
    @IBOutlet var colorButtonCollection: [UIButton]!
    @IBOutlet var colorFrameViewCollection: [UIView]!
    @IBOutlet weak var allowTextBackgroundCheckButton: UIButton!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet var actionButtons: [UIButton]! = []
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    var newTextFieldPressed = false
    var portkiNode: PortkiNode!
    var portkiNodes: [PortkiNode]!
    var portkiScreen: PortkiScreen!
    var screenImage: UIImage!
    var textBlocks = TextBlocks()
    var originalScrollViewFrame: CGRect!
    var selectedColorButtonTag = 0 // 0 = text, 1 = text background, 2 = screen background
    var selectedTextBlockIndex = 0
    var colorSlider: ColorSlider!
    var imagePicker = UIImagePickerController()
    var backgroundImageStatus: BackgroundImageStatus = .unchanged
    var screen = Screen()
    var buttonInfoArray = [ButtonInfo]()
    // TODO: pass in siblingButtonIDs
    var siblingButtonIDArray: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hexTextField.delegate = self
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        
        // sets up observers to alert code when keyboard is shown or hidden
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        // hide keyboard if we tap outside of a field
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        // tap.cancelsTouchesInView = false
        // self.view.addGestureRecognizer(tap)
        
        deleteTextButton.isEnabled = false
        editStyleBarButton.isEnabled = false
        loadBackgroundImage()
        loadTextBlocks()
    }
    
    func configureUserInterface() {
        // TODO: eventually will update this to whatever is saved
        configurePreviousNextButtons()
        // screenView.backgroundColor = portkiNode.backgroundColor
        grayBackgroundView.sendSubviewToBack(backgroundImageView)
        grayBackgroundView.sendSubviewToBack(screenView)
        configureColorSlider()
        // initially disable textBackgroundColor
        enableTextBackgroundColor(false)
        createButtons()
    }
    
    func createFieldCollectionFromTextBlocks(){
        fieldCollection = []
        for textBlock in textBlocks.textBlocksArray {
            let newFieldRect = CGRect(x: textBlock.originPoint.x, y: textBlock.originPoint.y, width: 320, height: 30)
            let newField = PaddedTextField(frame: newFieldRect)
            newField.font = UIFont(name: textBlock.font.fontName, size: textBlock.fontSize)
            newField.text = textBlock.text
            newField.textColor =  UIColor.init(hexString: textBlock.textColorHexString)
            if textBlock.backgroundColorHexString == "" {
                newField.backgroundColor = UIColor.clear
            } else {
                newField.backgroundColor = UIColor.init(hexString: textBlock.backgroundColorHexString)
            }
            // configure field alignment
            switch textBlock.alignment {
            case 0: // left
                newField.textAlignment = NSTextAlignment.left
            case 1: // center
                newField.textAlignment = NSTextAlignment.center
            case 2: // right
                newField.textAlignment = NSTextAlignment.right
            default:
                print("😡 ERROR: for some reason textBlock.alignment came back as something other than 0-2")
            }
            // field configure bold, italics, underline
            if textBlock.isBold {
                newField.font = newField.font?.setBoldFnc()
            }
            if textBlock.isItalic {
                newField.font = newField.font?.setItalicFnc()
            }
            if textBlock.isUnderlined {
                let field = newField
                newField.attributedText = NSAttributedString(string: field.text!, attributes:
                    [.underlineStyle: NSUnderlineStyle.single.rawValue])
            }
            fieldCollection.append(newField)
            setUpBlockAndField(newBlock: textBlock, newField: newField)
        }
    }
    
    func loadBackgroundImage() {
        backgroundImageView.image = UIImage()
        guard portkiNode.backgroundImageUUID != "" else {
            return // no backgroundImage for this screen
        }
        let imageType = "jpeg"
        let fileName = getDocumentsDirectory().appendingPathComponent("background.\(portkiNode.backgroundImageUUID).\(imageType)")
        do {
            let data = try Data(contentsOf: fileName)
            guard let image = UIImage(data: data) else {
                print("😡 Couldn't convert data for backgroundImage from \(fileName)")
                return
            }
            backgroundImageView.image = image
        } catch {
            print("😡 Couldn't get file named background.\(portkiNode.backgroundImageUUID): error:\(error)")
        }
    }
    
    func loadTextBlocks() {
        // get all the text blocks that make up the selected screen
        
        // TODO load up backgrounds first. There is a chance there is no textblock but there is a background.
        
        textBlocks.loadTextBlocks(pageID: portkiNode.documentID) { returnedTextBlocks in
            guard let returnedTextBlocksArray = returnedTextBlocks?.textBlocksArray else {
                self.createNewField()
                self.configureUserInterface()
                return
            }
            self.textBlocks.textBlocksArray = returnedTextBlocksArray
            self.createFieldCollectionFromTextBlocks()
            self.configureUserInterface()
        }
    }
    
    func configurePreviousNextButtons(){
        // Hide the back button if you're looking at the "Home" screen (because there's no way to go back if you're at home, the root of the tree hierarchy.
        if portkiNode.nodeType == "Home" {
            backButton.isHidden = true
            previousButton.isHidden = true
            nextButton.isHidden = true
        }
        
        let parentID = portkiNode.parentID
        let foundParent = portkiNodes.first(where: {$0.documentID == parentID})
        guard let parent = foundParent else { // unwrap found parent
            if portkiNode.nodeType != "Home" {
                print("😡 ERROR: could not get the node's parent")
            }
            return
        }
        if parent.childrenIDs.count > 1 {
            previousButton.isHidden = false
            nextButton.isHidden = false
        } else {
            previousButton.isHidden = true
            nextButton.isHidden = true
        }
    }
    
    func configureColorSlider() {
        textColorFrameView.layer.borderColor = Colors.buttonTint.cgColor
        textBackgroundFrameView.layer.borderColor = Colors.buttonTint.cgColor
        
        textColorButton.backgroundColor = fieldCollection[selectedTextBlockIndex].textColor
        textBackgroundButton.backgroundColor = fieldCollection[selectedTextBlockIndex].backgroundColor
        
        screenBackgroundColorButton.backgroundColor = screenView.backgroundColor
        
        configureSlider()
    }
    
    func configureSlider() {
        // Remove the prior slider, if any. If you don't do this, you'll see a buildup of accumulating sliders in the view hierarchy (click debug view hierarcy to see, if you comment out the loop below
        for subview in contentView.subviews {
            if subview is ColorSlider {
                subview.removeFromSuperview()
            }
        }
        let colorSliderY = textColorStackView.frame.origin.y + textColorStackView.frame.height + 12 // should be about 450
        let colorSliderFrame = CGRect(x: 0 + 16, y: colorSliderY, width: UIScreen.main.bounds.width - 16*2 , height: 20)
        let previewView = DefaultPreviewView(side: .top)
        previewView.offsetAmount = 10.0
        colorSlider = ColorSlider(orientation: .horizontal, previewView: previewView)
        // colorSlider.color = textColorButton.backgroundColor!
        colorSlider.color = colorButtonCollection[selectedColorButtonTag].backgroundColor!
        colorSlider.frame = colorSliderFrame
        contentView.addSubview(colorSlider)
        colorSlider.addTarget(self, action: #selector(changedColor(_:)), for: .valueChanged)
    }
    
    @objc func changedColor(_ colorSlider: ColorSlider) {
        let color = colorSlider.color
        hexTextField.text = colorSlider.color.hexString
        switch selectedColorButtonTag {
        case 0: // text color selected
            colorButtonCollection[selectedColorButtonTag].backgroundColor = color
            textBlocks.textBlocksArray[selectedTextBlockIndex].textColorHexString = color.hexString
            fieldCollection[selectedTextBlockIndex].textColor = color
        case 1: // text background selected
            colorButtonCollection[selectedColorButtonTag].backgroundColor = color
            textBlocks.textBlocksArray[selectedTextBlockIndex].backgroundColorHexString = color.hexString
            fieldCollection[selectedTextBlockIndex].backgroundColor = color
        case 2: // screen color selected
            colorButtonCollection[selectedColorButtonTag].backgroundColor = color
            screenView.backgroundColor = color
        default:
            print("😡 ERROR: Unexpected case in function changedColor")
        }
    }
    
    @IBAction func colorButtonPressed(_ sender: UIButton) {
        selectedColorButtonTag = sender.tag
        for subview in self.contentView.subviews {
            if subview is ColorSlider {
                colorSlider = subview as? ColorSlider
                subview.removeFromSuperview()
            }
        }
        configureSlider()
        if selectedColorButtonTag == 1 && colorButtonCollection[sender.tag].backgroundColor == UIColor.clear {
            hexTextField.text = ""
            colorSlider.color = UIColor.clear
        } else if selectedColorButtonTag == 1 {
            var textBackgroundColor = UIColor.clear
            if let nonNilBackgroundColor = fieldCollection[selectedTextBlockIndex].backgroundColor {
                textBackgroundColor = nonNilBackgroundColor
            }
            colorButtonCollection[selectedColorButtonTag].backgroundColor = textBackgroundColor
            hexTextField.text = colorButtonCollection[selectedColorButtonTag].backgroundColor?.hexString
            changeColor(color: textBackgroundColor)
        }
        setSelectedFrame(sender: sender)
    }
    
    // Puts a border around color indicator to show which is selected: text font or text background
    func setSelectedFrame(sender: UIButton) {
        selectedColorButtonTag = sender.tag
        for colorButtonFrame in colorFrameViewCollection {
            colorButtonFrame.layer.borderWidth = 0.0
        }
        colorFrameViewCollection[selectedColorButtonTag].layer.borderWidth = 1.0
        // TODO: This shows the selection circle inside the colorSlider
        colorSlider.layoutSubviews()
    }
    
    func setUpBlockAndField(newBlock: TextBlock, newField: UITextField) {
        // selectedTextBlockIndex = textBlocks.textBlocksArray.count-1
        let oldSelectedTextBlockIndex = selectedTextBlockIndex
        selectedTextBlockIndex = fieldCollection.count-1
        print(">>>> setting up field # \(fieldCollection.count-1)")
        print(">>>> there are \(fieldCollection.count) fields and \(textBlocks.textBlocksArray.count) textBLocks")
        print(">>>> current selected textBlock is \(selectedTextBlockIndex)")
        newField.borderStyle = .roundedRect
        newField.isUserInteractionEnabled = true
        newField.addGestureRecognizer(addGestureToField())
        newField.sizeToFit()
        let newFieldHeight = newField.frame.height
        var newFieldRect = newField.frame
        newFieldRect = CGRect(x: newFieldRect.origin.x, y: newFieldRect.origin.y, width: 320, height: newFieldHeight)
        newField.frame = newFieldRect
        newField.textColor = newBlock.textColor
        if newBlock.backgroundColorHexString == "" {
            newField.backgroundColor = UIColor.clear
        } else {
            newField.backgroundColor = UIColor(hexString: newBlock.backgroundColorHexString)
        }
        
        if newTextFieldPressed {
            let newFrame = fieldCollection[oldSelectedTextBlockIndex].frame
            newField.frame = CGRect(x: newFrame.origin.x, y: newFrame.origin.y+newFrame.height+5, width: newFrame.width, height: newFrame.height)
            newField.font = fieldCollection[oldSelectedTextBlockIndex].font
            newField.textColor = fieldCollection[oldSelectedTextBlockIndex].textColor
            textBlocks.textBlocksArray[selectedTextBlockIndex].textColorHexString = textBlocks.textBlocksArray[oldSelectedTextBlockIndex].textColorHexString
            textBlocks.textBlocksArray[selectedTextBlockIndex].backgroundColorHexString = textBlocks.textBlocksArray[oldSelectedTextBlockIndex].backgroundColorHexString
            // field configure bold, italics, underline
            textBlocks.textBlocksArray[selectedTextBlockIndex].isBold = textBlocks.textBlocksArray[oldSelectedTextBlockIndex].isBold
            if textBlocks.textBlocksArray[oldSelectedTextBlockIndex].isBold {
                newField.font = newField.font?.setBoldFnc()
            }
            textBlocks.textBlocksArray[selectedTextBlockIndex].isItalic = textBlocks.textBlocksArray[oldSelectedTextBlockIndex].isItalic
            if textBlocks.textBlocksArray[oldSelectedTextBlockIndex].isItalic {
                newField.font = newField.font?.setItalicFnc()
            }
            textBlocks.textBlocksArray[selectedTextBlockIndex].isUnderlined = textBlocks.textBlocksArray[oldSelectedTextBlockIndex].isUnderlined
            // underlining doesn't work because there's no attibuted text. I think that's oK.
            if textBlocks.textBlocksArray[oldSelectedTextBlockIndex].isUnderlined {
                let field = newField
                newField.attributedText = NSAttributedString(string: field.text!, attributes:
                    [.underlineStyle: NSUnderlineStyle.single.rawValue])
            }
            // iOS removes alignment after becomefirstresponder is set. Unsure why, so this isn't working, neither is the underline setting.
            textBlocks.textBlocksArray[selectedTextBlockIndex].alignment = textBlocks.textBlocksArray[oldSelectedTextBlockIndex].alignment
            newField.textAlignment = fieldCollection[oldSelectedTextBlockIndex].textAlignment
            if textBlocks.textBlocksArray[oldSelectedTextBlockIndex].backgroundColorHexString == "" {
                newField.backgroundColor = UIColor.clear
            } else {
                newField.backgroundColor = UIColor(hexString: newBlock.backgroundColorHexString)
            }
            newField.font?.withSize(newBlock.fontSize)
            newField.text = newBlock.text
            newField.textColor = UIColor(hex: newBlock.textColorHexString)
            
            newField.backgroundColor = fieldCollection[oldSelectedTextBlockIndex].backgroundColor
        }
        
        screenView.addSubview(newField)
        screenView.bringSubviewToFront(newField)
        selectedColorButtonTag = 0 // New field? Select textColor button
        fieldCollection[selectedTextBlockIndex] = newField
        let lastAlignment = newField.textAlignment
        fieldCollection.last!.delegate = self
        fieldCollection.last!.becomeFirstResponder()
        fieldCollection.last!.textAlignment = lastAlignment
        if newBlock.backgroundColorHexString == "" { // same as clear {
            enableTextBackgroundColor(false)
        } else {
            enableTextBackgroundColor(true)
            selectedColorButtonTag = 1
            changeColor(color: fieldCollection.last!.backgroundColor!)
        }
        selectedColorButtonTag = 0
        changeColor(color: fieldCollection.last!.textColor!)
    }
    
    @objc func changeButtonTitle(_ sender: UIButton) {
        showInputDialog(title: nil,
                        message: "Change the label on the '\(sender.titleLabel?.text ?? "")' button:",
            actionTitle: "Change",
            cancelTitle: "Cancel",
            inputPlaceholder: nil,
            inputKeyboardType: .default,
            actionHandler: {(input:String?) in
                guard let buttonTitle = input else {
                    return
                }
                sender.setTitle(buttonTitle, for: .normal)
                sender.sizeToFit()
                sender.frame = CGRect(x: sender.frame.origin.x, y: sender.frame.origin.y, width: sender.frame.width + (ButtonPadding.paddingAroundText*2), height: sender.frame.height)
                sender.center = CGPoint(x: self.screenView.frame.width/2, y: sender.center.y)
                self.saveButtonTitle(sender: sender)
        },
            cancelHandler: nil)
        
    }
    
    func saveButtonTitle(sender: UIButton) {
        
        guard let clickedButtonIndex = actionButtons.firstIndex(where: {$0 == sender}) else {
            print("😡 couldn't get clickedButtonIndex")
            return
        }
        
        let clickedButtonID = portkiNode.childrenIDs[clickedButtonIndex]
        var clickedButtonNode = portkiNodes.first(where: {$0.documentID == clickedButtonID})
        clickedButtonNode?.nodeName = sender.titleLabel?.text ?? "<ERROR CHANGING BUTTON TITLE>"
        
        // TODO: You'll need to save the updated button title
        
        //        clickedButtonNode?.saveData() {success in
        //            if !success { // if not successful
        //                print("😡 ERROR: couldn't save change to clicked button at documentID = \(clickedButtonNode!.documentID)")
        //            } else {
        //                print("-> Yeah, properly updated button title!")
        //            }
        //        }
    }
    
    func createButton(buttonName: String) -> UIButton {
        let newButton = UIButton(frame: self.screenView.frame)
        newButton.setTitle(buttonName, for: .normal)
        newButton.titleLabel?.font = .boldSystemFont(ofSize: 13.0)
        newButton.sizeToFit()
        newButton.frame = CGRect(x: newButton.frame.origin.x, y: newButton.frame.origin.y, width: newButton.frame.width + (ButtonPadding.paddingAroundText*2), height: newButton.frame.height)
        newButton.backgroundColor = UIColor.init(hexString: "923125")
        newButton.addTarget(self, action: #selector(changeButtonTitle), for: .touchUpInside)
        return newButton
    }
    
    func createButtons() {
        // no buttons to create if there aren't any children
        guard portkiNode.childrenIDs.count > 0 else {
            return
        }
        
        var buttonNames = [String]() // clear out button names
        for childID in portkiNode.childrenIDs { // loop through all childIDs
            if let buttonNode = portkiNodes.first(where: {$0.documentID == childID}) { // if you can find an node with that childID
                buttonNames.append(buttonNode.nodeName) // add it's name to buttonNames
            }
        }
        
        // create a button (in actionButtons) for each buttonName
        for buttonName in buttonNames {
            actionButtons.append(createButton(buttonName: buttonName))
        }
        
        // position action buttons
        // 12 & 12 from lower right-hand corner
        let indent: CGFloat = 12.0
        // start in lower-left of screenView
        var buttonX: CGFloat = 0.0
        // var buttonX = screenView.frame.origin.x
        let buttonY = screenView.frame.height-indent-actionButtons[0].frame.height
        
        for button in actionButtons {
            var buttonFrame = button.frame
            buttonX = buttonX + indent
            buttonFrame = CGRect(x: buttonX, y: buttonY, width: buttonFrame.width, height: buttonFrame.height)
            button.frame = buttonFrame
            screenView.addSubview(button)
            buttonX = buttonX + button.frame.width // move start portion of next button rect to the end of the current button rect
        }
        if portkiNode.nodeType == "Home" {
            var widthOfAllButtons = actionButtons.reduce(0.0,{$0 + $1.frame.width})
            widthOfAllButtons = widthOfAllButtons + (CGFloat(actionButtons.count-1)*indent)
            var shiftedX = (screenView.frame.width-widthOfAllButtons)/2
            
            for button in actionButtons {
                button.frame.origin.x = shiftedX
                shiftedX = shiftedX + button.frame.width + indent
            }
        }
    }
    
    // UITextField created & added to fieldCollection
    func createNewField() {
        let newBlock = TextBlock()
        textBlocks.pageID = portkiNode.documentID // Unique identifier for the current screen
        let newFieldRect = CGRect(x: newBlock.originPoint.x, y: newBlock.originPoint.y, width: 320, height: 30)
        let newField = PaddedTextField(frame: newFieldRect)
        newField.font?.withSize(newBlock.fontSize)
        newField.text = newBlock.text
        newField.textColor = UIColor(hex: newBlock.textColorHexString)
        newField.backgroundColor =  UIColor(hex: newBlock.backgroundColorHexString)
        textBlocks.textBlocksArray.append(newBlock)
        fieldCollection.append(newField)
        setUpBlockAndField(newBlock: textBlocks.textBlocksArray.last!, newField: newField)
    }
    
    func enableTextBackgroundColor(_ enable: Bool) {
        if enable {
            // enable textBackgroundColor
            if let textBackgroundColor = fieldCollection[selectedTextBlockIndex].backgroundColor {
                fieldCollection[selectedTextBlockIndex].backgroundColor = textBackgroundColor
            } else {
                fieldCollection[selectedTextBlockIndex].backgroundColor = UIColor.clear
            }
            colorButtonCollection[1].isSelected = true // call below will set it to false
            colorButtonCollection[1].isEnabled = true
            colorButtonCollection[1].backgroundColor = fieldCollection[selectedTextBlockIndex].backgroundColor
            textBackgroundStaticLabel.textColor = UIColor.black
            colorFrameViewCollection[1].layer.borderWidth = 1.0
            selectedColorButtonTag = 1
            allowTextBackgroundCheckButton.isSelected = true
            // move setting hex to empty string to confirmed press disabling.
            //            hexTextField.text = ""
        } else {
            // initially disable textBackgroundColor
            colorButtonCollection[1].isSelected = false // call below will set it to false
            colorButtonCollection[1].isEnabled = false
            colorButtonCollection[1].backgroundColor = UIColor.clear
            textBackgroundStaticLabel.textColor = UIColor.gray
            colorFrameViewCollection[1].layer.borderWidth = 0.0
            selectedColorButtonTag = 0
            allowTextBackgroundCheckButton.isSelected = false
        }
    }
    
    // Allows text field to be moved via click & drag
    func addGestureToField() -> UIPanGestureRecognizer {
        var panGesture = UIPanGestureRecognizer()
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(draggedView(_:)))
        return panGesture
    }
    
    func updateInterfaceForSelectedTextField() {
        // TODO: Fill me in!!
        fontNameLabel.text = fieldCollection[selectedTextBlockIndex].font?.familyName
        fieldCollection[selectedTextBlockIndex].adjustHeight()
        formatAlignmentCell()
        configureSizeCell()
        updateFieldBasedOnStyleButtons()
        configureColorSlider()
        // if fieldCollection[selectedTextBlockIndex].backgroundColor == UIColor.clear {
        if textBlocks.textBlocksArray[selectedTextBlockIndex].backgroundColorHexString == "" {
            // initially disable textBackgroundColor
            enableTextBackgroundColor(false)
            
            // NOTE: When I had a crash Wed. evening I uncommented these
            //                        colorButtonCollection[1].isSelected = true // call below will set it to false
            //                        allowTextBackgroundPressed(allowTextBackgroundCheckButton)
        } else {
            enableTextBackgroundColor(true)
        }
    }
    
    // Select / deselect text fields
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.superview == screenView {
            textField.borderStyle = .roundedRect
            selectedTextBlockIndex = fieldCollection.firstIndex(of: textField)!
            print("<><><> preparing to updateInterfaceForSelectedTextField in textFieldDidBeginEditing. selectedTextBlockIndex = \(selectedTextBlockIndex)")
            updateInterfaceForSelectedTextField()
            deleteTextButton.isEnabled = true
            editStyleBarButton.isEnabled = true
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.superview == screenView {
            textField.borderStyle = .none
            deleteTextButton.isEnabled = false
            editStyleBarButton.isEnabled = false
        }
        if textField == hexTextField {
            print("********* YOU ENDED THE HEX COLOR CELL!!!!")
            let hexString = hexTextField.text!
            let newColor = UIColor(hexString: hexString)
            print("*** CHANGING COLOR TO ENTERED HEX STRING \(newColor) ***")
            changeColor(color: newColor)
        }
        textField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == hexTextField {
            print("********* YOU ENDED THE HEX COLOR CELL!!!!")
        }
        textField.resignFirstResponder()
        return true
    }
    
    func formatAlignmentCell() {
        styleView.layer.cornerRadius = 5.0
        styleView.layer.borderWidth = 1.0
        styleView.layer.borderColor = Colors.buttonTint.cgColor
        
        alignmentSegmentedControl.selectedSegmentIndex = textBlocks.textBlocksArray[selectedTextBlockIndex].alignment
        alignmentSegmentedControl.sendActions(for: .valueChanged)
        let textBlock = textBlocks.textBlocksArray[selectedTextBlockIndex]
        textBlock.isBold ? boldButton.configureButtonState(state: .selected) : boldButton.configureButtonState(state: .normal)
        textBlock.isItalic ? italicsButton.configureButtonState(state: .selected) : italicsButton.configureButtonState(state: .normal)
        textBlock.isUnderlined ? underlineButton.configureButtonState(state: .selected) : underlineButton.configureButtonState(state: .normal)
    }
    
    func configureSizeCell() {
        let size = Int(fieldCollection[selectedTextBlockIndex].font?.pointSize ?? 17)
        fontSizeLabel.text = "\(size) pt."
        sizeStepper.value = Double(size)
    }
    
    func changeColorFromHex(hexString: String, slider: ColorSlider, colorButtons: [UIButton]) {
        slider.color = UIColor(hexString: hexString)
        // slider.color = UIColor(hex: hexString) ?? UIColor.clear
        changeColor(color: slider.color)
    }
    
    // func changeColor(color: UIColor, colorButtons: [UIButton]) {
    func changeColor(color: UIColor) {
        switch selectedColorButtonTag {
        case 0: // text color selected
            colorButtonCollection[selectedColorButtonTag].backgroundColor = color
            textBlocks.textBlocksArray[selectedTextBlockIndex].textColorHexString = color.hexString
            fieldCollection[selectedTextBlockIndex].textColor = color
        case 1: // text background selected
            colorButtonCollection[selectedColorButtonTag].backgroundColor = color
            textBlocks.textBlocksArray[selectedTextBlockIndex].backgroundColorHexString = color.hexString
            fieldCollection[selectedTextBlockIndex].backgroundColor = color
        case 2: // screen color selected
            colorButtonCollection[selectedColorButtonTag].backgroundColor = color
            screenView.backgroundColor = color
        default:
            print("😡ERROR: Unexpected case in function changeColor")
        }
        hexTextField.text = color.hexString
        
        // Remove frames from all color buttons, then add frame to selected color button
        for colorButtonFrame in colorFrameViewCollection {
            colorButtonFrame.layer.borderWidth = 0.0
        }
        colorFrameViewCollection[selectedColorButtonTag].layer.borderWidth = 1.0
    }
    
    func updateFieldBasedOnStyleButtons() {
        if boldButton.isSelected {
            fieldCollection[selectedTextBlockIndex].font = fieldCollection[selectedTextBlockIndex].font?.setBoldFnc()
        }
        if italicsButton.isSelected {
            fieldCollection[selectedTextBlockIndex].font = fieldCollection[selectedTextBlockIndex].font?.setItalicFnc()
        }
        if underlineButton.isSelected {
            let field = fieldCollection[selectedTextBlockIndex]
            fieldCollection[selectedTextBlockIndex].attributedText = NSAttributedString(string: field.text!, attributes:
                [.underlineStyle: NSUnderlineStyle.single.rawValue])
        }
    }
    
    func cameraOrLibraryAlert() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { _ in
            self.accessCamera()
        }
        let photoLibraryAction = UIAlertAction(title: "Photo Library", style: .default) { _ in
            self.accessLibrary()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cameraAction)
        alertController.addAction(photoLibraryAction)
        alertController.addAction(cancelAction)
        
        if backgroundImageView.image!.size.width > 0 { // if there is an image to remove
            let deleteAction = UIAlertAction(title: "Delete Background", style: .destructive) { _ in
                self.backgroundImageView.image = UIImage()
                self.backgroundImageStatus = .delete
            }
            alertController.addAction(deleteAction)
        }
        
        present(alertController, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "ShowFonts":
            let destination = segue.destination as! FontListViewController
            destination.delegate = self
            destination.selectedFont = fieldCollection[selectedTextBlockIndex].font
        case "UwindFromScreenDesign":
            portkiNode.needsUpdate = false
            print("just lettin' you know I'm unwinding from screen design")
        default:
            print("😡 ERROR: unexpectedly hit the default case in ScreenDesignViewController's prepareForSegue")
        }
    }
    
    // event handler when a field(view) is dragged
    @objc func draggedView(_ sender:UIPanGestureRecognizer){
        if (sender.state == UIGestureRecognizer.State.began) {
            sender.view!.becomeFirstResponder()
            let selectedView = sender.view as! UITextField
            selectedTextBlockIndex = fieldCollection.firstIndex(of: selectedView)!
            selectedView.bringSubviewToFront(selectedView)
            selectedColorButtonTag = 0 // when selecting new field, start w/textColor selected
            updateInterfaceForSelectedTextField()
            deleteTextButton.isEnabled = true
            editStyleBarButton.isEnabled = true
        }
        let translation = sender.translation(in: screenView)
        sender.view!.center = CGPoint(x: sender.view!.center.x + translation.x, y: sender.view!.center.y + translation.y)
        sender.setTranslation(CGPoint.zero, in: screenView)
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            scrollView.contentInset = .zero
        } else {
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }
        
        scrollView.scrollIndicatorInsets = scrollView.contentInset
    }
    
    @IBAction func addFieldPressed(_ sender: UIButton) {
        newTextFieldPressed = true
        createNewField()
    }
    
    @IBAction func addImageButtonPressed(_ sender: UIBarButtonItem) {
        cameraOrLibraryAlert()
    }
    
    
    @IBAction func editStylePressed(_ sender: UIBarButtonItem) {
        fieldCollection[selectedTextBlockIndex].resignFirstResponder()
    }
    
    @IBAction func deleteTextPressed(_ sender: UIButton) {
        let fieldRemoved = fieldCollection[selectedTextBlockIndex]
        for subview in screenView.subviews {
            if subview == fieldRemoved {
                subview.removeFromSuperview()
            }
        }
        fieldCollection.remove(at: selectedTextBlockIndex)
        textBlocks.textBlocksArray.remove(at: selectedTextBlockIndex)
        if fieldCollection.count == 0 { // deleted the only row
            createNewField()
        } else if fieldCollection.count <= selectedTextBlockIndex {
            selectedTextBlockIndex = selectedTextBlockIndex - 1
        } // else unchanged since row that was selectedTextBlockIndex + 1 is now one below, where the deleted row used to be
        updateInterfaceForSelectedTextField()
    }
    
    @IBAction func alignmentSegmentSelected(_ sender: UISegmentedControl) {
        textBlocks.textBlocksArray[selectedTextBlockIndex].alignment = sender.selectedSegmentIndex
        switch sender.selectedSegmentIndex {
        case 0: // left
            fieldCollection[selectedTextBlockIndex].textAlignment = NSTextAlignment.left
        case 1: // center
            fieldCollection[selectedTextBlockIndex].textAlignment = NSTextAlignment.center
        case 2: // right
            fieldCollection[selectedTextBlockIndex].textAlignment = NSTextAlignment.right
        default:
            print("😡 ERROR: unexpected case in alignmentSegmentSelected!")
        }
    }
    
    @IBAction func styleButtonSelected(_ sender: ToggleButton) {
        sender.isSelected = !sender.isSelected
        switch sender.tag {
        case 0: // bold
            textBlocks.textBlocksArray[selectedTextBlockIndex].isBold = sender.isSelected
            if sender.isSelected {
                fieldCollection[selectedTextBlockIndex].font = fieldCollection[selectedTextBlockIndex].font?.setBoldFnc()
                sender.configureButtonState(state: .selected)
            } else {
                fieldCollection[selectedTextBlockIndex].font = fieldCollection[selectedTextBlockIndex].font?.toggleBoldFnc()
                sender.configureButtonState(state: .normal)
            }
        case 1: // italics
            textBlocks.textBlocksArray[selectedTextBlockIndex].isItalic = sender.isSelected
            if sender.isSelected {
                fieldCollection[selectedTextBlockIndex].font = fieldCollection[selectedTextBlockIndex].font?.setItalicFnc()
                sender.configureButtonState(state: .selected)
            } else {
                fieldCollection[selectedTextBlockIndex].font = fieldCollection[selectedTextBlockIndex].font?.deleteItalicFont()
                sender.configureButtonState(state: .normal)
            }
        case 2: // underline
            textBlocks.textBlocksArray[selectedTextBlockIndex].isUnderlined = sender.isSelected
            if sender.isSelected {
                sender.configureButtonState(state: .selected)
                let field = fieldCollection[selectedTextBlockIndex]
                fieldCollection[selectedTextBlockIndex].attributedText = NSAttributedString(string: field.text!, attributes:
                    [.underlineStyle: NSUnderlineStyle.single.rawValue])
                sender.configureButtonState(state: .selected)
            } else {
                sender.configureButtonState(state: .normal)
                let field = fieldCollection[selectedTextBlockIndex]
                
                fieldCollection[selectedTextBlockIndex].attributedText = NSAttributedString(string: field.text!, attributes:
                    [.underlineStyle: 0])
                sender.configureButtonState(state: .normal)
            }
        default:
            print("😡 ERROR: unexpected case in styleButtonSelected.")
        }
    }
    
    @IBAction func stepperPressed(_ sender: UIStepper) {
        let newFontSize = Int(sender.value)
        textBlocks.textBlocksArray[selectedTextBlockIndex].fontSize = CGFloat(newFontSize)
        fieldCollection[selectedTextBlockIndex].font = fieldCollection[selectedTextBlockIndex].font?.withSize(CGFloat(newFontSize))
        updateInterfaceForSelectedTextField()
    }
    
    func leaveViewController() {
        let isPresentingInAddMode = presentingViewController is UINavigationController
        if isPresentingInAddMode {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        leaveViewController()
    }
    
    // upload Lily's physical form to CampMinder. Questions: 617-680-3389 Nurse: Andrea
    
    func buildButtonArray() -> [ButtonInfo] {
        if portkiNode.nodeType != "Home" { // if it's not the Home screen, then it must have a parent, so find this so it can be used to find prev, next (if needed) and back buttons.
            let parentID = portkiNode.parentID
            let foundParent = portkiNodes.first(where: {$0.documentID == parentID})
            guard let parent = foundParent else { // unwrap found parent
                if portkiNode.nodeType != "Home" {
                    print("😡 ERROR: could not get the node's parent")
                }
                return [ButtonInfo]()
            }
            
            // var siblingIDs = foundParent?.childrenIDs
            siblingButtonIDArray = parent.childrenIDs
            
            if previousButton.isHidden == false { // add a previousButton
                let newButton = ButtonInfo()
                newButton.buttonName = "xLeft"
                newButton.buttonRect = previousButton.frame
                var indexOfCurrentScreen = siblingButtonIDArray.firstIndex(of: portkiNode.documentID)
                var prevButtonIndex = 0 // this 0 is a placeholder - the 0 may change.
                if indexOfCurrentScreen == nil {
                    // This happens when screen is a new screen & there's not yet a record for it
                    print("😡 I don't think this should have happened. Look for the comment: This happens when screen is a new screen & there's not yet a record for it")
                    prevButtonIndex = siblingButtonIDArray.count-1
                    indexOfCurrentScreen = siblingButtonIDArray.count
                    
                } else {
                    prevButtonIndex = indexOfCurrentScreen! - 1
                }
                if prevButtonIndex < 0 {
                    prevButtonIndex = siblingButtonIDArray.count-1
                }
                newButton.idToLoad = siblingButtonIDArray[prevButtonIndex] // prev button will be at the current index minus one.
                // TODO: at this point I don't have an .idToLoad or documentID
                buttonInfoArray.append(newButton)
            }
            
            if nextButton.isHidden == false { // add a nextButton
                let newButton = ButtonInfo()
                newButton.buttonName = "xRight"
                newButton.buttonRect = nextButton.frame
                var indexOfCurrentScreen = siblingButtonIDArray.firstIndex(of: portkiNode.documentID)
                
                var nextButtonIndex = 0 // this 0 is a placeholder - the 0 may change.
                if indexOfCurrentScreen == nil {
                    // This happens when screen is a new screen & there's not yet a record for it
                    print("😡 I don't think this should have happened. Look for the comment near nextButton.isHidden labeled: This happens when screen is a new screen & there's not yet a record for it")
                    nextButtonIndex = siblingButtonIDArray.count+1
                    indexOfCurrentScreen = siblingButtonIDArray.count
                } else {
                    nextButtonIndex = indexOfCurrentScreen! + 1
                }
                if indexOfCurrentScreen! >= siblingButtonIDArray.count-1 { // already at end, so "next" should restart at index 0
                    nextButtonIndex = 0
                }
                newButton.idToLoad = siblingButtonIDArray[nextButtonIndex] // two previous
                buttonInfoArray.append(newButton)
            }
            
        }
        
        // add action buttons to buttonInfoArray
        if portkiNode.childrenIDs.count == actionButtons.count {
            for childIndex in 0..<portkiNode.childrenIDs.count { // loop through all childIDs
                let newButton = ButtonInfo()
                newButton.buttonName = actionButtons[childIndex].titleLabel!.text!
                newButton.buttonRect = actionButtons[childIndex].frame
                let buttonDocumentID = portkiNode.childrenIDs[childIndex]
                print(">> Looking for buttonDocumentID: \(buttonDocumentID)")
                if let foundButtonNode = portkiNodes.first(where: {$0.documentID == buttonDocumentID}) {
                    newButton.idToLoad = foundButtonNode.childrenIDs[0] // load the first child page. There's often only one, but if you have a bunch at the same level, load the first
                    print(">> FOUND buttonDocumentID: \(buttonDocumentID) and it's first childrenIDs is \(newButton.idToLoad)")
                } else {
                    print("😡 ERROR: for some reason foundButtonNode couldn't be found!")
                }
                buttonInfoArray.append(newButton)
            }
        } else {
            print("ERROR: For some reason portkiNode.childrenIDs.count \(portkiNode.childrenIDs.count) does not equal actionButtons.count \(actionButtons.count)")
        }
        return buttonInfoArray
    }
    
    func deselectAllFields() {
        // deselect any selected field to get rid of the rounded-rect box around it, so this doesn't save as part of the screen image.
        for field in fieldCollection {
            if field.isSelected {
                field.isSelected = false
            }
        }
    }
    
    func saveNodesAsJson() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let encoded = try? encoder.encode(portkiNodes) {
            if let jsonString = String(data: encoded, encoding: .utf8) {
                print(jsonString)
                
                let parameters = ["value": jsonString]
                guard let json = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
                    print("😡 Grr. json conversion didn't work")
                    return
                }
                print("** JSON Conversion Worked !!!")
                print(json)
                
                let filename = getDocumentsDirectory().appendingPathComponent("portkiNodes.json")
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
    
    func saveImageToFile(fileName: String, imageData: Data, imageType: String) {
        let filename = getDocumentsDirectory().appendingPathComponent("\(fileName).\(imageType)")
        do {
            try imageData.write(to: filename, options: .atomic)
            print("😀 Successfully wrote filename: \(filename)")
        } catch {
            print("😡 Drat! image named \(fileName).\(imageType) couldn't be written to file \(error.localizedDescription)")
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func saveBackgroundImage() {
        switch self.backgroundImageStatus {
        case .delete:
            portkiNode.backgroundImageUUID = ""
            // TODO: actually delete the file from disk (and the cloud if you store it there, too)
            return
        case .save:
            // For now I'm allowing only one backgroundImage, and
            // give it the same name as the element and screen documents.
            portkiNode.backgroundImageUUID = portkiNode.documentID
            guard let image = backgroundImageView.image else {
                print("🛑 Tried to saveBackgroundImage when backgroundImageView.image is nil")
                return
            }
            // orientation 0 is supposed to be up. w/o this some images were rotated 90 degrees
            guard let data = image.toJpegData(compressionQuality: 1.0, hasAlpha: false, orientation: 0) else {
                print("🛑 Couldn't create jpegData from screenView.bounds")
                return
            }
            saveImageToFile(fileName: "background.\(portkiNode.backgroundImageUUID)",imageData: data , imageType: "jpeg")
        case .unchanged:
            return
        }
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        // Save background image first. You'll want to update backgroundImageUUID
        // in the portkiNode before savign the current node, below.
        saveBackgroundImage()
        
        if let currentScreenIndex = self.portkiNodes.firstIndex(where: {$0.documentID == portkiNode.documentID}) {
            // update currentScreen
            portkiNodes[currentScreenIndex] = portkiNode
        } else {
            print("😡 just before saveNodeAsJson - should never have arrived here. Used to append the node")
            portkiNodes.append(portkiNode)
        }
        saveNodesAsJson()
        
        for index in 0..<fieldCollection.count {
            textBlocks.textBlocksArray[index].fontNameString = fieldCollection[index].font!.familyName
            textBlocks.textBlocksArray[index].fontSize = fieldCollection[index].font!.pointSize
            textBlocks.textBlocksArray[index].text = fieldCollection[index].text!
            textBlocks.textBlocksArray[index].textColorHexString = fieldCollection[index].textColor?.hexString ?? UIColor.black.hexString
            textBlocks.textBlocksArray[index].backgroundColorHexString = fieldCollection[index].backgroundColor?.hexString ?? UIColor.clear.hexString
            textBlocks.textBlocksArray[index].originPoint = fieldCollection[index].frame.origin
        }
        
        portkiNode.saveTextBlocks(textBlocks: textBlocks)
        buttonInfoArray = buildButtonArray()
        
        // Now create a bmp of whatever's on screen.
        deselectAllFields()
        
        let renderer = UIGraphicsImageRenderer(size: screenView.bounds.size)
        let grabbedImage = renderer.image { ctx in
            screenView.drawHierarchy(in: screenView.bounds, afterScreenUpdates: true)
        }
        
        // you'll need to scale the image down since Retina displays show points at 2x or 3x the pixel size.
        // if you don't do this, your bmp will be scale times larger than you'd like.
        let scale = UIScreen.main.scale
        let newSize = CGSize(width: screenView.bounds.width * (1/scale), height: screenView.bounds.height * (1/scale))
        let resizedImage = grabbedImage.resized(to: newSize)
        
        // stuff I'm trying based on HackingWithSwift
        // orientation 0 is supposed to be up
        guard let jpegData = resizedImage.toJpegData(compressionQuality: 1.0, hasAlpha: false, orientation: 0) else {
            print("🛑🛑 Couldn't create jpegData")
            return
        }
        saveImageToFile(fileName: portkiNode.documentID, imageData: jpegData, imageType: "jpeg")
        performSegue(withIdentifier: "UwindFromScreenDesign", sender: nil)
        
        // TODO: Save your TextBlocks here!!
        //        textBlocks.saveData(element: element) { success in
        //            if success {
        //                // self.leaveViewController()
        //                switch self.backgroundImageStatus {
        //                case .delete:
        //                    // TODO: Something will go here, but for now, break
        //                    self.leaveViewController()
        //                case .save:
        //                    // self.element.backgroundImageUUID = UUID().uuidString
        //                    // if this works, you can delete above. Allow only one backgroundImage, and
        //                    // give it the same name as the element and screen documents.
        //                    self.element.backgroundImageUUID = self.element.documentID
        //                    self.element.saveData { (success) in
        //                        if success {
        //                            self.element.saveImage { (success) in
        //                                print(" ^^ Successfully element.saveImage")
        //                                self.leaveViewController()
        //                            }
        //                        } else {
        //                            print("😡 ERROR: Could not add backgroundImageUUID to elment \(self.element.elementName)")
        //                            self.leaveViewController()
        //                        }
        //                    }
        //                case .unchanged:
        //                    self.leaveViewController()
        //                }
        //            } else {
        //                print("*** ERROR: Couldn't leave this view controller because data wasn't saved.")
        //            }
        //        }
    }
    
    @IBAction func allowTextBackgroundPressed(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        enableTextBackgroundColor(sender.isSelected)
        
        textBackgroundButton.isEnabled = sender.isSelected
        textBackgroundStaticLabel.textColor = (sender.isSelected ? UIColor.black : UIColor.gray)
        
        if sender.isSelected {
            hexTextField.text = ""
            // colorButtonPressed(colorButtonCollection[1])
            // changed below to zero b/c color button on color line was showing
            // when enabling background text color for the first time.
            colorButtonPressed(colorButtonCollection[0])
        } else {
            textBlocks.textBlocksArray[selectedTextBlockIndex].backgroundColorHexString = UIColor.clear.hexString
            fieldCollection[selectedTextBlockIndex].backgroundColor = UIColor.clear
            colorButtonPressed(colorButtonCollection[0])
        }
    }
}

// Takes advantage of protocol user-selected font to be passed from the FontListViewController back to this view controller.
extension ScreenDesignViewController: PassFontDelegate {
    func getSelectedFont(selectedFont: UIFont) {
        let pointSizeBeforeChange = fieldCollection[selectedTextBlockIndex].font?.pointSize ?? CGFloat(17.0)
        textBlocks.textBlocksArray[selectedTextBlockIndex].fontNameString = selectedFont.familyName
        textBlocks.textBlocksArray[selectedTextBlockIndex].fontSize = CGFloat(pointSizeBeforeChange)
        fieldCollection[selectedTextBlockIndex].font = selectedFont
        fieldCollection[selectedTextBlockIndex].font = fieldCollection[selectedTextBlockIndex].font?.withSize(CGFloat(pointSizeBeforeChange))
        updateInterfaceForSelectedTextField()
    }
}

extension ScreenDesignViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    func resizedImage(image: UIImage, for size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { (context) in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    func calculateImageSize(image: UIImage) {
        // let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        let imgData = NSData(data: (image).jpegData(compressionQuality: 1)!)
        let imageSize: Int = imgData.count
        print("actual size of image in KB: %f ", Double(imageSize) / 1000.0)
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        // prepare to scale the image
        let scaleFactor = UIScreen.main.scale
        let scale = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        let size = backgroundImageView.bounds.size.applying(scale)
        if let image = info[.editedImage] as? UIImage {
            backgroundImageView.image = image
        } else if let image = info[.originalImage] as? UIImage {
            backgroundImageView.image = image
        } else {
            print("😡 ERROR: Neither .editedImage nor .originalImage was returned. This should not have happened.")
        }
        deselectAllFields()
        backgroundImageStatus = .save
        dismiss(animated: true) {
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func accessLibrary() {
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    func accessCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePicker.sourceType = .camera
            present(imagePicker, animated: true, completion: nil)
        } else {
            self.showAlert(title: "Camera Not Available", message: "There is no camera available on this device.")
        }
    }
}

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

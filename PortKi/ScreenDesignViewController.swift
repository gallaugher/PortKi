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
    // The content view is inside the screenView, all interface elements are configured to the contentView, so any shifting of contentView will shift all elements by the same amount.
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var grayBackgroundView: UIView!
    @IBOutlet var fieldCollection: [UITextField]! // Not connected, fields created programmatically
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
    
    var element: Element!
    var elements: Elements!
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
        
        // sets up observers to alert code when keyboard is shown or hidden
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        // hide keyboard if we tap outside of a field
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
        
        deleteTextButton.isEnabled = false
        editStyleBarButton.isEnabled = false
        loadTextBlocks()
    }
    
    func configureUserInterface() {
        // TODO: eventually will update this to whatever is saved
        configurePreviousNextButtons()
        screenView.backgroundColor = element.backgroundColor
        grayBackgroundView.sendSubviewToBack(backgroundImageView)
        grayBackgroundView.sendSubviewToBack(screenView)
        configureColorSlider()
        // initially disable textBackgroundColor
        enableTextBackgroundColor(false)
        createButtons()
    }
    
    func createFieldCollectionFromTextBlocks(){
        for textBlock in textBlocks.textBlocksArray {
            let newFieldRect = CGRect(x: textBlock.originPoint.x, y: textBlock.originPoint.y, width: 320, height: 30)
            let newField = PaddedTextField(frame: newFieldRect)
            newField.font = UIFont(name: textBlock.font.fontName, size: textBlock.fontSize)
            newField.text = textBlock.text
            newField.textColor = textBlock.textColor
            newField.backgroundColor = textBlock.backgroundColor
            setUpBlockAndField(newBlock: textBlock, newField: newField)
        }
    }
    
    func loadTextBlocks() {
        // get all the text blocks that make up the selected screen
        textBlocks.loadData(element: element) {
            if self.textBlocks.textBlocksArray.count == 0 {
                self.createNewField()
                self.configureUserInterface()
            } else {
                self.createFieldCollectionFromTextBlocks()
                self.configureUserInterface()
            }
        }
        backgroundImageView.image = UIImage()
        if element.backgroundImageUUID != "" {
            element.loadBackgroundImage {
                self.backgroundImageView.image = self.element.backgroundImage
            }
        }
    }
    
    func configurePreviousNextButtons(){
        // Hide the back button if you're looking at the "Home" screen (because there's no way to go back if you're at home, the root of the tree hierarchy.
        if element.elementType == "Home" {
            backButton.isHidden = true
            previousButton.isHidden = true
            nextButton.isHidden = true
        }
        
        let parentID = element.parentID
        let foundParent = elements.elementArray.first(where: {$0.documentID == parentID})
        guard let parent = foundParent else { // unwrap found parent
            if element.elementType != "Home" {
                print("😡 ERROR: could not get the element's parent")
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
        colorSlider.color = textColorButton.backgroundColor!
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
            textBlocks.textBlocksArray[selectedTextBlockIndex].textColor = color
            fieldCollection[selectedTextBlockIndex].textColor = color
        case 1: // text background selected
            colorButtonCollection[selectedColorButtonTag].backgroundColor = color
            textBlocks.textBlocksArray[selectedTextBlockIndex].backgroundColor = color
            fieldCollection[selectedTextBlockIndex].backgroundColor = color
        case 2: // screen color selected
            colorButtonCollection[selectedColorButtonTag].backgroundColor = color
            screenView.backgroundColor = color
        default:
            print("😡ERROR: Unexpected case in function changedColor")
        }
    }
    
    @IBAction func colorButtonPressed(_ sender: UIButton) {
        for subview in self.contentView.subviews {
            if subview is ColorSlider {
                colorSlider = subview as? ColorSlider
            }
        }
        if colorSlider == nil { // this is the case if a new field is added
            configureColorSlider()
        }
        if selectedColorButtonTag == 1 && colorButtonCollection[sender.tag].backgroundColor == UIColor.clear {
            hexTextField.text = ""
        } else {
            hexTextField.text = colorButtonCollection[sender.tag].backgroundColor?.hexString
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
        // TODO: Check to see if we should remocve the comments, below
        colorSlider.layoutSubviews()
    }
    
    func setUpBlockAndField(newBlock: TextBlock, newField: UITextField) {
        selectedTextBlockIndex = textBlocks.textBlocksArray.count-1
        newField.borderStyle = .roundedRect
        newField.isUserInteractionEnabled = true
        newField.addGestureRecognizer(addGestureToField())
        newField.sizeToFit()
        let newFieldHeight = newField.frame.height
        var newFieldRect = newField.frame
        newFieldRect = CGRect(x: newFieldRect.origin.x, y: newFieldRect.origin.y, width: 320, height: newFieldHeight)
        newField.frame = newFieldRect
        newField.textColor = newBlock.textColor
        newField.backgroundColor = newBlock.backgroundColor
        screenView.addSubview(newField)
        screenView.bringSubviewToFront(newField)
        selectedColorButtonTag = 0 // New field? Select textColor button
        if fieldCollection == nil {
            fieldCollection = [newField]
        } else {
            fieldCollection.append(newField)
        }
        newField.delegate = self
        newField.becomeFirstResponder()
        if newField.backgroundColor == UIColor.clear {
            enableTextBackgroundColor(false)
        } else {
            enableTextBackgroundColor(true)
        }
        changeColor(color: newField.textColor!)
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
        
        let clickedButtonID = element.childrenIDs[clickedButtonIndex]
        let clickedButtonElement = elements.elementArray.first(where: {$0.documentID == clickedButtonID})
        clickedButtonElement?.elementName = sender.titleLabel?.text ?? "<ERROR CHANGING BUTTON TITLE>"
        
        clickedButtonElement?.saveData() {success in
            if !success { // if not successful
                print("😡 ERROR: couldn't save change to clicked button at documentID = \(clickedButtonElement!.documentID)")
            } else {
                print("-> Yeah, properly updated button title!")
            }
        }
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
        guard element.childrenIDs.count > 0 else {
            return
        }
        
        var buttonNames = [String]() // clear out button names
        for childID in element.childrenIDs { // loop through all childIDs
            if let buttonElement = elements.elementArray.first(where: {$0.documentID == childID}) { // if you can find an element with that childID
                buttonNames.append(buttonElement.elementName) // add it's name to buttonNames
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
        if element.elementType == "Home" {
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
        textBlocks.textBlocksArray.append(newBlock)
        
        let newFieldRect = CGRect(x: newBlock.originPoint.x, y: newBlock.originPoint.y, width: 320, height: 30)
        let newField = PaddedTextField(frame: newFieldRect)
        newField.font?.withSize(newBlock.fontSize)
        newField.text = newBlock.text
        newField.textColor = newBlock.textColor
        newField.backgroundColor = newBlock.backgroundColor
        setUpBlockAndField(newBlock: newBlock, newField: newField)
    }
    
    func enableTextBackgroundColor(_ enable: Bool) {
        if enable {
            // enable textBackgroundColor
            colorButtonCollection[1].isSelected = true // call below will set it to false
            colorButtonCollection[1].isEnabled = true
            // colorButtonCollection[1].backgroundColor = UIColor.clear
            colorButtonCollection[1].backgroundColor = fieldCollection[selectedTextBlockIndex].backgroundColor
            textBackgroundStaticLabel.textColor = UIColor.black
            colorFrameViewCollection[1].layer.borderWidth = 1.0
            selectedColorButtonTag = 1
            allowTextBackgroundCheckButton.isSelected = true
            // move setting hex to empty string to confirmed press disabling.
            //            hexTextField.text = ""
        } else {
            // initially disable textBackgroundColor
            colorButtonCollection[1].backgroundColor = UIColor.white
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
        if fieldCollection[selectedTextBlockIndex].backgroundColor == UIColor.clear {
            // initially disable textBackgroundColor
            enableTextBackgroundColor(false)
            //            colorButtonCollection[1].isSelected = true // call below will set it to false
            //            allowTextBackgroundPressed(allowTextBackgroundCheckButton)
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
            textBlocks.textBlocksArray[selectedTextBlockIndex].textColor = color
            fieldCollection[selectedTextBlockIndex].textColor = color
        case 1: // text background selected
            colorButtonCollection[selectedColorButtonTag].backgroundColor = color
            textBlocks.textBlocksArray[selectedTextBlockIndex].backgroundColor = color
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
        if segue.identifier == "ShowFonts" { // then tableView cell was clicked
            let destination = segue.destination as! FontListViewController
            destination.delegate = self
            destination.selectedFont = fieldCollection[selectedTextBlockIndex].font
        } else {
            print("😡 ERROR: Should not have arrived in the else in prepareForSegue")
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
        
        // If reuse and want the text view to readjust itself so the user doesn't lose their place while editing, uncomment two lines below.
        // let selectedRange = scrollView
        // scrollView.scrollRangeToVisible(selectedRange)
    }
    
    @IBAction func addFieldPressed(_ sender: UIButton) {
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
    
    func buildButtonArray() -> [ButtonInfo] {
        
        
        if element.elementName != "Home" { // if it's not the Home screen, then it must have a parent, so find this so it can be used to find prev, next (if needed) and back buttons.
            let parentID = element.parentID
            let foundParent = elements.elementArray.first(where: {$0.documentID == parentID})
            guard let parent = foundParent else { // unwrap found parent
                if element.elementType != "Home" {
                    print("😡 ERROR: could not get the element's parent")
                }
                return [ButtonInfo]()
            }
            var siblingIDs = foundParent?.childrenIDs
            
            if previousButton.isHidden == false { // add a previousButton
                let newButton = ButtonInfo()
                newButton.buttonName = "xPrevious"
                newButton.buttonRect = previousButton.frame
                let indexOfCurrentScreen = siblingButtonIDArray.firstIndex(of: element.documentID)
                var prevButtonIndex = indexOfCurrentScreen! - 1
                if indexOfCurrentScreen! < 0 {
                    prevButtonIndex = siblingButtonIDArray.count-1
                }
                newButton.idToLoad = siblingButtonIDArray[prevButtonIndex] // two previous
                buttonInfoArray.append(newButton)
            }
            
            if nextButton.isHidden == false { // add a previousButton
                let newButton = ButtonInfo()
                newButton.buttonName = "xNext"
                newButton.buttonRect = nextButton.frame
                let indexOfCurrentScreen = siblingButtonIDArray.firstIndex(of: element.documentID)
                var nextButtonIndex = indexOfCurrentScreen! + 1
                if indexOfCurrentScreen! >= siblingButtonIDArray.count {
                    nextButtonIndex = 0
                }
                newButton.idToLoad = siblingButtonIDArray[nextButtonIndex] // two previous
                buttonInfoArray.append(newButton)
            }
            
        }
        
        // add action buttons to buttonInfoArray
        if element.childrenIDs.count == actionButtons.count {
            for childIndex in 0..<element.childrenIDs.count { // loop through all childIDs
                let newButton = ButtonInfo()
                newButton.buttonName = actionButtons[childIndex].titleLabel!.text!
                newButton.buttonRect = actionButtons[childIndex].frame
                let buttonDocumentID = element.childrenIDs[childIndex]
                print(">> Looking for buttonDocumentID: \(buttonDocumentID)")
                if let foundButtonElement = elements.elementArray.first(where: {$0.documentID == buttonDocumentID}) {
                    newButton.idToLoad = foundButtonElement.childrenIDs[0] // load the first child page. There's often only one, but if you have a bunch at the same level, load the first
                    print(">> FOUND buttonDocumentID: \(buttonDocumentID) and it's first childrenIDs is \(newButton.idToLoad)")
                } else {
                    print("😡 ERROR: for some reason foundButtonElement couldn't be found!")
                }
                buttonInfoArray.append(newButton)
            }
        } else {
            print("ERROR: For some reason element.childrenIDs.count \(element.childrenIDs.count) does not equal actionButtons.count \(actionButtons.count)")
        }
        return buttonInfoArray
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        for index in 0..<fieldCollection.count {
            let field = fieldCollection[index]
            let textBlock = textBlocks.textBlocksArray[index]
            textBlock.font = field.font!
            textBlock.fontSize = field.font!.pointSize
            textBlock.text = field.text!
            textBlock.textColor = field.textColor ?? UIColor.black
            textBlock.backgroundColor = field.backgroundColor ?? UIColor.clear
            textBlock.originPoint = field.frame.origin
        }
        
        buttonInfoArray = buildButtonArray()
        let renderer = UIGraphicsImageRenderer(size: screenView.bounds.size)
        let grabbedImage = renderer.image { ctx in
            screenView.drawHierarchy(in: screenView.bounds, afterScreenUpdates: true)
        }
        // backgroundImageView.image = grabbedImage
        screen.screenImage = grabbedImage
        screen.saveData { (success) in
            if success {
                self.screen.saveImage{ (success) in
                    if success {
                        print("!!! JUST FINISHED .saveImage")
                    } else {
                        print(" *** WHOA! didn't .saveImage ***")
                        
                    }
                }
            } else {
                print("*** DANG! no success at screen.saveData!")
            }
        }
        
        for buttonInfo in buttonInfoArray {
            buttonInfo.saveData { (success) in
                if !success {
                    print("*** DANG! didn't buttonInfo.saveData!")
                }
            }
        }
        
        textBlocks.saveData(element: element) { success in
            if success {
                // self.leaveViewController()
                switch self.backgroundImageStatus {
                case .delete:
                    // TODO: Something will go here, but for now, break
                    self.leaveViewController()
                case .save:
                    self.element.backgroundImageUUID = UUID().uuidString
                    self.element.saveData { (success) in
                        if success {
                            self.element.saveImage { (success) in
                                self.leaveViewController()
                            }
                        } else {
                            print("😡 ERROR: Could not add backgroundImageUUID to elment \(self.element.elementName)")
                            self.leaveViewController()
                        }
                    }
                case .unchanged:
                    self.leaveViewController()
                }
            } else {
                print("*** ERROR: Couldn't leave this view controller because data wasn't saved.")
            }
        }
    }
    
    @IBAction func allowTextBackgroundPressed(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        enableTextBackgroundColor(sender.isSelected)
        
        textBackgroundButton.isEnabled = sender.isSelected
        textBackgroundStaticLabel.textColor = (sender.isSelected ? UIColor.black : UIColor.gray)
        
        if sender.isSelected {
            hexTextField.text = ""
            colorButtonPressed(colorButtonCollection[1])
        } else {
            textBlocks.textBlocksArray[selectedTextBlockIndex].backgroundColor = UIColor.clear
            fieldCollection[selectedTextBlockIndex].backgroundColor = UIColor.clear
            colorButtonPressed(colorButtonCollection[0])
        }
    }
}

// Takes advantage of protocol user-selected font to be passed from the FontListViewController back to this view controller.
extension ScreenDesignViewController: PassFontDelegate {
    func getSelectedFont(selectedFont: UIFont) {
        let pointSizeBeforeChange = fieldCollection[selectedTextBlockIndex].font?.pointSize ?? CGFloat(17.0)
        textBlocks.textBlocksArray[selectedTextBlockIndex].font = selectedFont
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
        var imageSize: Int = imgData.count
        print("actual size of image in KB: %f ", Double(imageSize) / 1000.0)
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        // prepare to scale the image
        let scaleFactor = UIScreen.main.scale
        let scale = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        let size = backgroundImageView.bounds.size.applying(scale)
        backgroundImageView.image = (info[UIImagePickerController.InfoKey.originalImage] as! UIImage)
        calculateImageSize(image: backgroundImageView.image!)
        
        // scale & show the selected image in the app's backgroundImageView
        //  backgroundImageView.image = (info[UIImagePickerController.InfoKey.originalImage] as! UIImage)
        backgroundImageView.image = resizedImage(image: backgroundImageView.image!, for: size)
        element.backgroundImage = backgroundImageView.image! // and store image in element
        print("** BEFORE COMPRESSION")
        calculateImageSize(image: element.backgroundImage)
        
        backgroundImageView.image = (info[UIImagePickerController.InfoKey.originalImage] as! UIImage)
        let renderer = UIGraphicsImageRenderer(size: screenView.bounds.size)
        let grabbedImage = renderer.image { ctx in
            screenView.drawHierarchy(in: screenView.bounds, afterScreenUpdates: true)
        }
        backgroundImageView.image = grabbedImage
        element.backgroundImage = backgroundImageView.image! // and store image in element
        print("** AFTER COMPRESSION")
        calculateImageSize(image: element.backgroundImage)
        backgroundImageStatus = .save
        dismiss(animated: true) {
            // TODO: image saving here
            //            photo.saveData(spot: self.spot) { (success) in
            //            }
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

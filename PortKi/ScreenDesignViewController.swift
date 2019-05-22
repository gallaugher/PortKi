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
    
    @IBOutlet weak var screenView: UIView! // a view with fixed dimensions, same size as the PyPortal's screen
    // The content view is inside the screenView, all interface elements are configured to the contentView, so any shifting of contentView will shift all elements by the same amount.
    @IBOutlet weak var contentView: UIView!
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
    
    var selectedColorButtonTag = 0 // 0 = text, 1 = text background, 2 = screen background
    var textBlocks: [TextBlock] = []
    var selectedTextBlockIndex = 0
    var element: Element!
    var elements: Elements!
    var originalScrollViewFrame: CGRect!
    var colorSlider: ColorSlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hexTextField.delegate = self
        
        // sets up observers to alert code when keyboard is shown or hidden
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        // hide keyboard if we tap outside of a field
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        deleteTextButton.isEnabled = false
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
        
        // TODO: eventually will update this to whatever is saved
        screenView.backgroundColor = UIColor.white
        createNewField()
        configureColorSlider()
        // initially disable textBackgroundColor
        colorButtonCollection[1].isSelected = true // call below will set it to false
        allowTextBackgroundPressed(allowTextBackgroundCheckButton)
    }
    
    func configureColorSlider() {
        textColorFrameView.layer.borderColor = Colors.buttonTint.cgColor
        textBackgroundFrameView.layer.borderColor = Colors.buttonTint.cgColor
        
        textColorButton.backgroundColor = fieldCollection[selectedTextBlockIndex].textColor
        textBackgroundButton.backgroundColor = fieldCollection[selectedTextBlockIndex].backgroundColor
        
        screenBackgroundColorButton.backgroundColor = screenView.backgroundColor
        
        configureSlider()
        
        textColorFrameView.layer.borderWidth = 1.0
        textColorButton.layer.borderWidth = 0.5
        textColorButton.layer.borderColor = UIColor.lightGray.cgColor
        textBackgroundButton.layer.borderWidth = 0.5
        textBackgroundButton.layer.borderColor = UIColor.lightGray.cgColor
        screenBackgroundColorButton.layer.borderWidth = 0.5
        screenBackgroundColorButton.layer.borderColor = UIColor.lightGray.cgColor
    }
    
    func configureSlider() {
        // TODO: test if bottom is still true
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
        // colorSlider.addTarget(self, action: #selector(changedColor(_: )), for: .valueChanged)
    }
    
    @objc func changedColor(_ colorSlider: ColorSlider) {
        let color = colorSlider.color
        hexTextField.text = colorSlider.color.hexString
        switch selectedColorButtonTag {
        case 0: // text color selected
            colorButtonCollection[selectedColorButtonTag].backgroundColor = color
            textBlocks[selectedTextBlockIndex].textColor = color
            fieldCollection[selectedTextBlockIndex].textColor = color
        case 1: // text background selected
            colorButtonCollection[selectedColorButtonTag].backgroundColor = color
            textBlocks[selectedTextBlockIndex].backgroundColor = color
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
        hexTextField.text = colorButtonCollection[sender.tag].backgroundColor?.hexString
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
    
    // UITextField created & added to fieldCollection
    func createNewField() {
        let newBlock = TextBlock()
        textBlocks.append(newBlock)
        selectedTextBlockIndex = textBlocks.count-1
        var newFieldRect = CGRect(x: 0, y: 0, width: 320, height: 30)
        let newField = PaddedTextField(frame: newFieldRect)
        newField.borderStyle = .roundedRect
        newField.isUserInteractionEnabled = true
        newField.addGestureRecognizer(addGestureToField())
        newField.sizeToFit()
        let newFieldHeight = newField.frame.height
        newFieldRect = CGRect(x: 0, y: 0, width: 320, height: newFieldHeight)
        newField.frame = newFieldRect
        newField.textColor = UIColor.black
        newField.backgroundColor = UIColor.clear
        hexTextField.text = ""
        screenView.addSubview(newField)
        if fieldCollection == nil {
            fieldCollection = [newField]
        } else {
            fieldCollection.append(newField)
        }
        newField.delegate = self
        newField.becomeFirstResponder()
        // initially disable textBackgroundColor
        colorButtonCollection[1].isSelected = false // call below will set it to false
        colorButtonCollection[1].isEnabled = false
        colorButtonCollection[1].backgroundColor = UIColor.clear
        textBackgroundStaticLabel.textColor = UIColor.gray
        colorFrameViewCollection[1].layer.borderWidth = 0.0
        selectedColorButtonTag = 0
        allowTextBackgroundCheckButton.isSelected = false
        changeColor(color: newField.textColor!, colorButtons: colorButtonCollection)
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
            colorButtonCollection[1].isSelected = true // call below will set it to false
            allowTextBackgroundPressed(allowTextBackgroundCheckButton)
        }
    }
    
    // Select / deselect text fields
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.superview == screenView {
            textField.borderStyle = .roundedRect
            selectedTextBlockIndex = fieldCollection.firstIndex(of: textField)!
            updateInterfaceForSelectedTextField()
            deleteTextButton.isEnabled = true
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.superview == screenView {
            textField.borderStyle = .none
            deleteTextButton.isEnabled = false
        }
        
        if textField == hexTextField {
            print("********* YOU ENDED THE HEX COLOR CELL!!!!")
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
        
        alignmentSegmentedControl.selectedSegmentIndex = textBlocks[selectedTextBlockIndex].alignment
        alignmentSegmentedControl.sendActions(for: .valueChanged)
        let textBlock = textBlocks[selectedTextBlockIndex]
        textBlock.isBold ? boldButton.configureButtonState(state: .selected) : boldButton.configureButtonState(state: .normal)
        textBlock.isItalic ? italicsButton.configureButtonState(state: .selected) : italicsButton.configureButtonState(state: .normal)
        textBlock.isUnderlined ? underlineButton.configureButtonState(state: .selected) : underlineButton.configureButtonState(state: .normal)
    }
    
    func configureSizeCell() {
        let size = Int(fieldCollection[selectedTextBlockIndex].font?.pointSize ?? 17)
        fontSizeLabel.text = "\(size) pt."
        sizeStepper.value = Double(size)
    }
    
    // func changeColorSelected(slider: ColorSlider, colorButtons: [UIButton], colorHexValueField: UITextField) {
    //    func changeColorSelected() {
    //        let color = colorSlider.color
    //        colorSlider.layoutSubviews()
    //        if hexTextField.text! != "" {
    //            hexTextField.text = color.hexString
    //            changeColor(color: color, colorButtons: colorButtons)
    //        } else {
    //            changeColor(color: UIColor.clear, colorButtons: colorButtons)
    //        }
    //    }
    
    func changeColorFromHex(hexString: String, slider: ColorSlider, colorButtons: [UIButton]) {
        slider.color = UIColor(hexString: hexString)
        // slider.color = UIColor(hex: hexString) ?? UIColor.clear
        changeColor(color: slider.color, colorButtons: colorButtons)
    }
    
    func changeColor(color: UIColor, colorButtons: [UIButton]) {
        switch selectedColorButtonTag {
        case 0: // text color selected
            colorButtons[selectedColorButtonTag].backgroundColor = color
            textBlocks[selectedTextBlockIndex].textColor = color
            fieldCollection[selectedTextBlockIndex].textColor = color
        case 1: // text background selected
            colorButtons[selectedColorButtonTag].backgroundColor = color
            textBlocks[selectedTextBlockIndex].backgroundColor = color
            fieldCollection[selectedTextBlockIndex].backgroundColor = color
        case 2: // screen color selected
            colorButtons[selectedColorButtonTag].backgroundColor = color
            screenView.backgroundColor = color
        default:
            print("😡ERROR: Unexpected case in function changeColor")
        }
        hexTextField.text = color.hexString
    }
    
    // Puts a border around color indicator to show which is selected: text font or text background
    //    func setSelectedFrame(sender: UIButton, colorButtons: [UIButton], colorButtonFrames: [UIView], selectedButtonTag: Int, colorHexValueField: UITextField, slider: ColorSlider) {
    //        selectedColorButtonTag = selectedButtonTag
    //        for colorButtonFrame in colorButtonFrames {
    //            colorButtonFrame.layer.borderWidth = 0.0
    //        }
    //        colorButtonFrames[selectedButtonTag].layer.borderWidth = 1.0
    //        // slider.layoutSubviews()
    //    }
    
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
            // TODO: This was where tableView was reloaded. Update UI here based on what was selected.
            updateInterfaceForSelectedTextField()
            deleteTextButton.isEnabled = true
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
        textBlocks.remove(at: selectedTextBlockIndex)
        if fieldCollection.count == 0 { // deleted the only row
            createNewField()
        } else if fieldCollection.count <= selectedTextBlockIndex {
            selectedTextBlockIndex = selectedTextBlockIndex - 1
        } // else unchanged since row that was selectedTextBlockIndex + 1 is now one below, where the deleted row used to be
        updateInterfaceForSelectedTextField()
    }
    
    @IBAction func alignmentSegmentSelected(_ sender: UISegmentedControl) {
        textBlocks[selectedTextBlockIndex].alignment = sender.selectedSegmentIndex
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
            textBlocks[selectedTextBlockIndex].isBold = sender.isSelected
            if sender.isSelected {
                fieldCollection[selectedTextBlockIndex].font = fieldCollection[selectedTextBlockIndex].font?.setBoldFnc()
                sender.configureButtonState(state: .selected)
            } else {
                fieldCollection[selectedTextBlockIndex].font = fieldCollection[selectedTextBlockIndex].font?.toggleBoldFnc()
                sender.configureButtonState(state: .normal)
            }
        case 1: // italics
            textBlocks[selectedTextBlockIndex].isItalic = sender.isSelected
            if sender.isSelected {
                fieldCollection[selectedTextBlockIndex].font = fieldCollection[selectedTextBlockIndex].font?.setItalicFnc()
                sender.configureButtonState(state: .selected)
            } else {
                fieldCollection[selectedTextBlockIndex].font = fieldCollection[selectedTextBlockIndex].font?.deleteItalicFont()
                sender.configureButtonState(state: .normal)
            }
        case 2: // underline
            textBlocks[selectedTextBlockIndex].isUnderlined = sender.isSelected
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
        textBlocks[selectedTextBlockIndex].fontSize = CGFloat(newFontSize)
        fieldCollection[selectedTextBlockIndex].font = fieldCollection[selectedTextBlockIndex].font?.withSize(CGFloat(newFontSize))
        updateInterfaceForSelectedTextField()
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        let isPresentingInAddMode = presentingViewController is UINavigationController
        if isPresentingInAddMode {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
    }
    
    @IBAction func allowTextBackgroundPressed(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        textBackgroundButton.isEnabled = sender.isSelected
        textBackgroundStaticLabel.textColor = (sender.isSelected ? UIColor.black : UIColor.gray)
        
        if sender.isSelected {
            hexTextField.text = ""
            colorButtonPressed(colorButtonCollection[1])
        } else {
            colorButtonCollection[1].backgroundColor = UIColor.white
            textBlocks[selectedTextBlockIndex].backgroundColor = UIColor.clear
            fieldCollection[selectedTextBlockIndex].backgroundColor = UIColor.clear
            colorButtonPressed(colorButtonCollection[0])
        }
    }
}

// Takes advantage of protocol user-selected font to be passed from the FontListViewController back to this view controller.
extension ScreenDesignViewController: PassFontDelegate {
    func getSelectedFont(selectedFont: UIFont) {
        let pointSizeBeforeChange = fieldCollection[selectedTextBlockIndex].font?.pointSize ?? CGFloat(17.0)
        textBlocks[selectedTextBlockIndex].font = selectedFont
        textBlocks[selectedTextBlockIndex].fontSize = CGFloat(pointSizeBeforeChange)
        fieldCollection[selectedTextBlockIndex].font = selectedFont
        fieldCollection[selectedTextBlockIndex].font = fieldCollection[selectedTextBlockIndex].font?.withSize(CGFloat(pointSizeBeforeChange))
        updateInterfaceForSelectedTextField()
        
//        textBlocks[selectedTextBlockIndex].font = selectedFont
//        fieldCollection[selectedTextBlockIndex].font = selectedFont
//        textBlocks[selectedTextBlockIndex].font.withSize(pointSizeBeforeChange)
//        fieldCollection[selectedTextBlockIndex].font!.withSize(pointSizeBeforeChange)
    }
}

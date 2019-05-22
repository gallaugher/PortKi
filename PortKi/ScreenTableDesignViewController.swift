//
//  ScreenDesignViewController.swift
//  PortKi
//
//  Created by John Gallaugher on 5/14/19.
//  Copyright © 2019 John Gallaugher. All rights reserved.
//

import UIKit
import ColorSlider

class ScreenTableDesignViewController: UIViewController, UITextFieldDelegate {
    
    // Be sure these Strings match with the cell's identifier in Attribute Inspector
    enum ScreenCells: String, CaseIterable {
        case alignment = "AlignmentCell"
        case font = "FontCell"
        case size = "SizeCell"
        case color = "ColorCell"
    }
    
    enum StyleButtons: Int {
        case bold = 0
        case italic = 1
        case underline = 2
    }
    
    @IBOutlet weak var screenView: UIView! // a view with fixed dimensions, same size as the PyPortal's screen
    @IBOutlet var fieldCollection: [UITextField]! // Not connected, fields created programmatically
    @IBOutlet weak var deleteTextButton: UIButton!
    @IBOutlet weak var editStyleBarButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var selectedColorButtonTag = 0 // 0 = text, 1 = text background, 2 = screen background
    var cells: [ScreenCells]!
    var textBlocks: [TextBlock] = []
    var selectedTextBlockIndex = 0
    var element: Element!
    var elements: Elements!
    var originalScrollViewFrame: CGRect!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // sets up observers to alert code when keyboard is shown or hidden
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        tableView.delegate = self
        tableView.dataSource = self
        // hide keyboard if we tap outside of a field
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        deleteTextButton.isEnabled = false
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
        
        // TODO: eventually will update this to whatever is saved
        screenView.backgroundColor = UIColor.white
        cells = ScreenCells.allCases // get an array of all Strings in enum ScreenCells and put it in variable named cells
        createNewField()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        originalScrollViewFrame = scrollView.frame
    }
    
    // Select / deselect text fields
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.superview == screenView {
            textField.borderStyle = .roundedRect
            selectedTextBlockIndex = fieldCollection.firstIndex(of: textField)!
            tableView.reloadData()
            deleteTextButton.isEnabled = true
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.superview == screenView {
            textField.borderStyle = .none
            deleteTextButton.isEnabled = false
        }
        
        if textField.superview != screenView {
            print("********* YOU ENDED THE HEX COLOR CELL!!!!")
        }
        textField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.superview != screenView {
            print("********* YOU ENDED THE HEX COLOR CELL!!!!")
        }
        textField.resignFirstResponder()
        return true
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
        screenView.addSubview(newField)
        if fieldCollection == nil {
            fieldCollection = [newField]
        } else {
            fieldCollection.append(newField)
        }
        newField.delegate = self
        newField.becomeFirstResponder()
    }
    
    @objc func keyboardWillShow(notification:NSNotification){
        for field in fieldCollection { // make sure you don't shift keyboard for any of the textFields in the screen view
            if field.isFirstResponder {
                return
            }
        }
        //give room at the bottom of the scroll view, so it doesn't cover up anything the user needs to tap
        var userInfo = notification.userInfo!
        var keyboardFrame:CGRect = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)
        let adjustmentHeight = keyboardFrame.height + 20
        let contentInset:UIEdgeInsets = scrollView.contentInset
        let offsetPoint = CGPoint(x: 0, y: contentInset.bottom + adjustmentHeight)
        scrollView.setContentOffset(offsetPoint, animated: true)
    }
    
    @objc func keyboardWillHide(notification:NSNotification){
        for field in fieldCollection { // make sure you don't shift keyboard for any of the textFields in the screen view
            if field.isFirstResponder {
                return
            }
        }
        scrollView.contentInset = UIEdgeInsets.zero
        let adjustmentHeight = CGFloat(20)
        scrollView.contentInset.bottom = scrollView.contentInset.bottom - adjustmentHeight
        originalScrollViewFrame = CGRect(x: originalScrollViewFrame.origin.x, y: originalScrollViewFrame.origin.y, width: originalScrollViewFrame.width, height: originalScrollViewFrame.height + adjustmentHeight)
        scrollView.frame = originalScrollViewFrame
    }
    
    // Allows text field to be moved via click & drag
    func addGestureToField() -> UIPanGestureRecognizer {
        var panGesture = UIPanGestureRecognizer()
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(draggedView(_:)))
        return panGesture
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
    
    func formatAlignmentCell(cell: AlignmentTableViewCell) {
        cell.styleView.layer.cornerRadius = 5.0
        cell.styleView.layer.borderWidth = 1.0
        cell.styleView.layer.borderColor = Colors.buttonTint.cgColor
        
        cell.alignmentSegmentedControl.selectedSegmentIndex = textBlocks[selectedTextBlockIndex].alignment
        cell.alignmentSegmentedControl.sendActions(for: .valueChanged)
        let textBlock = textBlocks[selectedTextBlockIndex]
        textBlock.isBold ? cell.boldButton.configureButtonState(state: .selected) : cell.boldButton.configureButtonState(state: .normal)
        textBlock.isItalic ? cell.italicsButton.configureButtonState(state: .selected) : cell.italicsButton.configureButtonState(state: .normal)
        textBlock.isUnderlined ? cell.underlineButton.configureButtonState(state: .selected) : cell.underlineButton.configureButtonState(state: .normal)
    }
    
    // event handler when a field(view) is dragged
    @objc func draggedView(_ sender:UIPanGestureRecognizer){
        if (sender.state == UIGestureRecognizer.State.began) {
            sender.view!.becomeFirstResponder()
            let selectedView = sender.view as! UITextField
            selectedTextBlockIndex = fieldCollection.firstIndex(of: selectedView)!
            selectedView.bringSubviewToFront(selectedView)
            tableView.reloadData()
            deleteTextButton.isEnabled = true
        }
        let translation = sender.translation(in: screenView)
        sender.view!.center = CGPoint(x: sender.view!.center.x + translation.x, y: sender.view!.center.y + translation.y)
        sender.setTranslation(CGPoint.zero, in: screenView)
    }
    
    @IBAction func addFieldPressed(_ sender: UIButton) {
        createNewField()
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
        tableView.reloadData()
    }
    
    // Click the "Two As and a pencil" bar button in the navigation controller
    @IBAction func editStylePressed(_ sender: UIBarButtonItem) {
        fieldCollection[selectedTextBlockIndex].resignFirstResponder()
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
}

class PaddedTextField: UITextField {
    let padding = UIEdgeInsets(top: 0, left: 7, bottom: 0, right: 8)
    let noPadding = UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        if self.borderStyle == .none {
            let content = bounds.inset(by: padding)
            return content
        } else {
            return bounds.inset(by: noPadding)
        }
    }
}

extension ScreenTableDesignViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }
    
    func updateFieldBasedOnStyleButtons(cell: AlignmentTableViewCell) {
        if cell.boldButton.isSelected {
            fieldCollection[selectedTextBlockIndex].font = fieldCollection[selectedTextBlockIndex].font?.setBoldFnc()
        }
        if cell.italicsButton.isSelected {
            fieldCollection[selectedTextBlockIndex].font = fieldCollection[selectedTextBlockIndex].font?.setItalicFnc()
        }
        if cell.underlineButton.isSelected {
            let field = fieldCollection[selectedTextBlockIndex]
            fieldCollection[selectedTextBlockIndex].attributedText = NSAttributedString(string: field.text!, attributes:
                [.underlineStyle: NSUnderlineStyle.single.rawValue])
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch cells[indexPath.row].rawValue {
        case ScreenCells.alignment.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: ScreenCells.alignment.rawValue, for: indexPath) as! AlignmentTableViewCell
            formatAlignmentCell(cell: cell)
            updateFieldBasedOnStyleButtons(cell: cell)
            cell.delegate = self
            return cell
        case ScreenCells.font.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: ScreenCells.font.rawValue, for: indexPath) as! FontTableViewCell
            cell.configureFontCell(selectedFont: textBlocks[selectedTextBlockIndex].font)
            return cell
        case ScreenCells.size.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: ScreenCells.size.rawValue, for: indexPath) as! SizeTableViewCell
            cell.delegate = self
            cell.configureSizeCell(size: Int(textBlocks[selectedTextBlockIndex].fontSize))
            fieldCollection[selectedTextBlockIndex].font = fieldCollection[selectedTextBlockIndex].font?.withSize(CGFloat(textBlocks[selectedTextBlockIndex].fontSize))
            fieldCollection[selectedTextBlockIndex].adjustHeight()
            return cell
        case ScreenCells.color.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: ScreenCells.color.rawValue, for: indexPath) as! ColorTableViewCell
            cell.delegate = self
            cell.configureColorCell(field: fieldCollection[selectedTextBlockIndex], screenColor: screenView.backgroundColor!)
            return cell
        default:
            print("😡 ERROR: unexpected case in cellForRowAt")
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 3 {
            return 96 // hard coded, not the best practice :(
        } else {
            return 44
        }
    }
    
    // Clicking the fonts cell (the only one with a disclosure icon) segues to a list of fonts
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if cells[indexPath.row] == ScreenCells.font {
            performSegue(withIdentifier: "ShowFonts", sender: nil)
        }
    }
}

// Custom protocols handle clicks within custom cells
extension ScreenTableDesignViewController: AlignmentCellDelegate, SizeCellDelegate, ColorCellDelegate {
    
    func alignmentSegmentSelected(selectedSegment: Int) {
        textBlocks[selectedTextBlockIndex].alignment = selectedSegment
        switch selectedSegment {
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
    
    func styleButtonSelected(_ sender: ToggleButton) {
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
    
    func fontSizeStepperPressed(_ newFontSize: Int) {
        textBlocks[selectedTextBlockIndex].fontSize = CGFloat(newFontSize)
        fieldCollection[selectedTextBlockIndex].font = fieldCollection[selectedTextBlockIndex].font?.withSize(CGFloat(newFontSize))
        tableView.reloadData()
    }
    
    // func changeColorSelected(slider: ColorSlider, colorButtons: [UIButton], colorHexValueField: UITextField) {
    func changeColorSelected(slider: ColorSlider, colorButtons: [UIButton], colorHexValueField: UITextField, colorHexValueString: String) {
        let color = slider.color
        slider.layoutSubviews()
        if colorHexValueString != "" {
            colorHexValueField.text = color.hexString
            changeColor(color: color, colorButtons: colorButtons)
        } else {
            changeColor(color: UIColor.clear, colorButtons: colorButtons)
        }
    }
    
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
            print("😡ERROR: Unexpected case in function changeColorSelected")
        }
    }
    
    // Puts a border around color indicator to show which is selected: text font or text background
    func setSelectedFrame(sender: UIButton, colorButtons: [UIButton], colorButtonFrames: [UIView], selectedButtonTag: Int, colorHexValueField: UITextField, slider: ColorSlider) {
        selectedColorButtonTag = selectedButtonTag
        for colorButtonFrame in colorButtonFrames {
            colorButtonFrame.layer.borderWidth = 0.0
        }
        colorButtonFrames[selectedButtonTag].layer.borderWidth = 1.0
        // slider.layoutSubviews()
    }
}

// Takes advantage of protocol user-selected font to be passed from the FontListViewController back to this view controller.
extension ScreenTableDesignViewController: PassFontDelegate {
    func getSelectedFont(selectedFont: UIFont) {
        textBlocks[selectedTextBlockIndex].font = selectedFont
        fieldCollection[selectedTextBlockIndex].font = selectedFont
        tableView.reloadData()
    }
}

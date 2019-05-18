//
//  ScreenDesignViewController.swift
//  PortKi
//
//  Created by John Gallaugher on 5/14/19.
//  Copyright © 2019 John Gallaugher. All rights reserved.
//

import UIKit
import ColorSlider

class ScreenDesignViewController: UIViewController, UITextFieldDelegate {
    
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
    
    var textColorSelected = true // if not, then textBackground must be selected
    var cells: [ScreenCells]!
    var textBlocks: [TextBlock] = []
    var selectedTextBlockIndex = 0
    var element: Element!
    var elements: Elements!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        // hide keyboard if we tap outside of a field
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        deleteTextButton.isEnabled = false
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
        cells = ScreenCells.allCases // get an array of all Strings in enum ScreenCells and put it in variable named cells
        createNewField()
    }
    
    // Select / deselect text fields
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.borderStyle = .roundedRect
        selectedTextBlockIndex = fieldCollection.firstIndex(of: textField)!
        tableView.reloadData()
        deleteTextButton.isEnabled = true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.borderStyle = .none
        deleteTextButton.isEnabled = false
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
        screenView.addSubview(newField)
        if fieldCollection == nil {
            fieldCollection = [newField]
        } else {
            fieldCollection.append(newField)
        }
        newField.delegate = self
        newField.becomeFirstResponder()
    }
    
    //    func sizeOfString (string: String, constrainedToWidth width: Double) -> CGSize {
    //        let attributes = [NSAttributedString.Key.font:self,]
    //        let attString = NSAttributedString(string: string,attributes: attributes)
    //        let framesetter = CTFramesetterCreateWithAttributedString(attString)
    //        return CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRange(location: 0,length: 0), nil, CGSize(width: width, height: Double.infinity), nil)
    //    }
    
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
    
    @IBAction func deleteFieldPressed(_ sender: UIButton) {
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
        } else if fieldCollection.count < selectedTextBlockIndex {
            selectedTextBlockIndex = selectedTextBlockIndex - 1
        } // else unchanged since row that was selectedTextBlockIndex + 1 is now one below, where the deleted row used to be
        tableView.reloadData()
    }
    
    // Click the "Two As and a pencil" bar button in the navigation controller
    @IBAction func editStylePressed(_ sender: UIBarButtonItem) {
        fieldCollection[selectedTextBlockIndex].resignFirstResponder()
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        
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

extension ScreenDesignViewController: UITableViewDataSource, UITableViewDelegate {
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
            cell.configureColorCell(textBlock: textBlocks[selectedTextBlockIndex])
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
extension ScreenDesignViewController: AlignmentCellDelegate, SizeCellDelegate, ColorCellDelegate {
    
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
    
    func changeColorSelected(slider: ColorSlider, textColorButton: UIButton, textBackgroundButton: UIButton) {
        let color = slider.color
        if textColorSelected {
            textColorButton.backgroundColor = color
            textBlocks[selectedTextBlockIndex].textColor = color
            fieldCollection[selectedTextBlockIndex].textColor = color
        } else {
            textBackgroundButton.backgroundColor = color
            textBlocks[selectedTextBlockIndex].backgroundColor = color
            fieldCollection[selectedTextBlockIndex].backgroundColor = color
        }
    }
    
    // Puts a border around color indicator to show which is selected: text font or text background
    func setSelectedFrame(sender: UIButton, textColorSelected: Bool, textColorFrame: UIView, textBackgroundFrame: UIView) {
        if textColorSelected {
            textColorFrame.layer.borderWidth = 1.0
            textBackgroundFrame.layer.borderWidth = 0.0
        } else {
            textColorFrame.layer.borderWidth = 0.0
            textBackgroundFrame.layer.borderWidth = 1.0
        }
        self.textColorSelected = textColorSelected
    }
}

// Takes advantage of protocol user-selected font to be passed from the FontListViewController back to this view controller.
extension ScreenDesignViewController: PassFontDelegate {
    func getSelectedFont(selectedFont: UIFont) {
        textBlocks[selectedTextBlockIndex].font = selectedFont
        fieldCollection[selectedTextBlockIndex].font = selectedFont
        tableView.reloadData()
    }
}

extension UITextField {
    func adjustHeight () {
        let originalFrame = self.frame
        self.sizeToFit()
        self.frame = CGRect(x: originalFrame.origin.x, y: self.frame.origin.y, width: originalFrame.width, height: self.frame.height)
    }
}

extension UIFont {
    func withTraits(traits:UIFontDescriptor.SymbolicTraits) -> UIFont {
        let descriptor = fontDescriptor.withSymbolicTraits(traits)
        return UIFont(descriptor: descriptor!, size: 0) //size 0 means keep the size as it is
    }
    
    func bold() -> UIFont {
        return withTraits(traits: .traitBold)
    }
    
    func italic() -> UIFont {
        return withTraits(traits: .traitItalic)
    }
}

extension UIFont {
    
    var isBold: Bool  {
        return fontDescriptor.symbolicTraits.contains(.traitBold)
    }
    
    var isItalic: Bool {
        return fontDescriptor.symbolicTraits.contains(.traitItalic)
    }
    
    //    var isUnderlined: Bool
    //    {
    //        return fontDescriptor.symbolicTraits.contains(.traitBold)
    //    }
    
    func setBoldFnc() -> UIFont {
        if (isBold) {
            return self
        } else {
            var fontAtrAry = fontDescriptor.symbolicTraits
            fontAtrAry.insert([.traitBold])
            let fontAtrDetails = fontDescriptor.withSymbolicTraits(fontAtrAry)
            guard fontAtrDetails != nil else {
                return self
            }
            return UIFont(descriptor: fontAtrDetails!, size: 0)
        }
    }
    
    func setItalicFnc()-> UIFont {
        if (isItalic) {
            return self
        } else {
            var fontAtrAry = fontDescriptor.symbolicTraits
            fontAtrAry.insert([.traitItalic])
            let fontAtrDetails = fontDescriptor.withSymbolicTraits(fontAtrAry)
            guard fontAtrDetails != nil else {
                return self
            }
            return UIFont(descriptor: fontAtrDetails!, size: 0)
        }
    }
    
    func setBoldItalicFnc()-> UIFont {
        return setBoldFnc().setItalicFnc() ?? self
    }
    
    func detBoldFnc() -> UIFont {
        if(!isBold) {
            return self
        } else {
            var originalFontDescriptor = fontDescriptor
            var fontAtrAry = fontDescriptor.symbolicTraits
            fontAtrAry.remove([.traitBold])
            var fontAtrDetails = fontDescriptor.withSymbolicTraits(fontAtrAry)
            if fontAtrDetails == nil {
                fontAtrDetails = originalFontDescriptor
            }
            return UIFont(descriptor: fontAtrDetails!, size: 0) ?? self
        }
    }
    
    func deleteItalicFont()-> UIFont {
        if(!isItalic) {
            return self
        } else {
            var originalFontDescriptor = fontDescriptor
            var fontAtrAry = fontDescriptor.symbolicTraits
            fontAtrAry.remove([.traitItalic])
            var fontAtrDetails = fontDescriptor.withSymbolicTraits(fontAtrAry)
            if fontAtrDetails == nil {
                fontAtrDetails = originalFontDescriptor
            }
            return UIFont(descriptor: fontAtrDetails!, size: 0)
        }
    }
    
    func setNormalFnc()-> UIFont {
        return detBoldFnc().deleteItalicFont() ?? self
    }
    
    func toggleBoldFnc()-> UIFont {
        if (isBold) {
            return detBoldFnc() ?? self
        } else {
            return setBoldFnc() ?? self
        }
    }
    
    func toggleItalicFnc()-> UIFont {
        if (isItalic) {
            return deleteItalicFont() ?? self
        } else {
            return setItalicFnc() ?? self
        }
    }
    
    //    func toggleUnderline() -> UIFont {
    //        fieldCollection[selectedTextBlockIndex].attributedText = NSAttributedString(string: field.text!, attributes:
    //            [.underlineStyle: NSUnderlineStyle.single.rawValue])
    //        attr.removeAttribute(NSStrikethroughStyleAttributeName , range:NSMakeRange(0, attr.length))
    //    }
}

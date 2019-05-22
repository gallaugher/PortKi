//
//  ToggleButton.swift
//  PortKi
//
//  Created by John Gallaugher on 5/15/19.
//  Copyright © 2019 John Gallaugher. All rights reserved.
//

import UIKit

class ToggleButton: UIButton {
    // default blue in hex: 4585F0
    // RGB: 69, 133, 240
    
    var buttonTextColor = UIColor.blue // UIColor.init(red: 69, green: 133, blue: 240, alpha: 1.0)
    var buttonBackgroundColor = UIColor.white
    var buttonSelected = false
    var underlinedButton = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initButton()
    }
    
    func initButton() {
        setTitleColor(Colors.buttonTint, for: .normal)
        setTitleColor(UIColor.white, for: .selected)
        
        if tag == 2 { // It's the underline button
            let stringAttributes : [NSAttributedString.Key : Any] = [
                NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14.0),
                NSAttributedString.Key.foregroundColor : Colors.buttonTint,
                NSAttributedString.Key.backgroundColor : UIColor.white,
                NSAttributedString.Key.underlineStyle : NSUnderlineStyle.single.rawValue
            ]
            let attributeString = NSMutableAttributedString(string: "U",
                                                            attributes: stringAttributes)
            setAttributedTitle(attributeString, for: .normal)
            
            let selectedStringAttributes : [NSAttributedString.Key : Any] =  [
                NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14.0),
                NSAttributedString.Key.foregroundColor : UIColor.white,
                NSAttributedString.Key.backgroundColor : Colors.buttonTint,
                NSAttributedString.Key.underlineStyle : NSUnderlineStyle.single.rawValue
            ]
            let selectedAttributeString = NSMutableAttributedString(string: "U",
                                                                    attributes: selectedStringAttributes)
            setAttributedTitle(selectedAttributeString, for: .selected)
            
            
        } else {
            setTitleColor(Colors.buttonTint, for: .normal)
        }
        backgroundColor = UIColor.white
        addTarget(self, action: #selector(ToggleButton.buttonPressed(_:)), for: .touchUpInside)
    }
    
    @objc func buttonPressed(_ sender: UIButton) {
        buttonSelected.toggle()
        buttonBackgroundColor = buttonSelected ?  Colors.buttonTint: UIColor.white
        backgroundColor = buttonBackgroundColor
        self.sendActions(for: .valueChanged)
    }
    
    func configureButtonState(state: UIControl.State) {
        if state == .selected {
            self.isSelected = true
            buttonTextColor = UIColor.white
            buttonBackgroundColor = Colors.buttonTint
            if tag == 2 {
                let stringAttributes : [NSAttributedString.Key : Any] = [
                    NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14.0),
                    NSAttributedString.Key.foregroundColor : UIColor.white,
                    NSAttributedString.Key.backgroundColor : Colors.buttonTint,
                    NSAttributedString.Key.underlineStyle : NSUnderlineStyle.single.rawValue
                ]
                let attributeString = NSMutableAttributedString(string: "U",
                                                                attributes: stringAttributes)
                setAttributedTitle(attributeString, for: .normal)
            }
        } else {
            self.isSelected = false
            buttonTextColor = Colors.buttonTint
            buttonBackgroundColor = UIColor.white
            if tag == 2 {
                let stringAttributes : [NSAttributedString.Key : Any] = [
                    NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14.0),
                    NSAttributedString.Key.foregroundColor : Colors.buttonTint,
                    NSAttributedString.Key.backgroundColor : UIColor.white,
                    NSAttributedString.Key.underlineStyle : NSUnderlineStyle.single.rawValue
                ]
                let attributeString = NSMutableAttributedString(string: "U",
                                                                attributes: stringAttributes)
                setAttributedTitle(attributeString, for: .normal)
            }
        }
        self.setTitleColor(buttonTextColor, for: state)
        self.backgroundColor = buttonBackgroundColor
        self.sendActions(for: .valueChanged)
    }
}

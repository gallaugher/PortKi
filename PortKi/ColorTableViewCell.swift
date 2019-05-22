//
//  ColorTableViewCell.swift
//  PortKi
//
//  Created by John Gallaugher on 5/15/19.
//  Copyright © 2019 John Gallaugher. All rights reserved.
//

import UIKit
import ColorSlider

class ColorTableViewCell: UITableViewCell, ColorSliderPreviewing, UITextFieldDelegate {
    @IBOutlet weak var textColorFrame: UIView!
    @IBOutlet weak var textColorButton: UIButton!
    @IBOutlet weak var textBackgroundFrame: UIView!
    @IBOutlet weak var textBackgroundButton: UIButton!
    @IBOutlet weak var colorHexValueField: UITextField!
    @IBOutlet weak var screenColorFrame: UIView!
    @IBOutlet weak var screenColorButton: UIButton!
    @IBOutlet var colorButtons: [UIButton]!
    @IBOutlet var colorButtonFrames: [UIView]!
    weak var delegate: ColorCellDelegate?
    
    func colorChanged(to color: UIColor) {
        // changes background color of slider. Not needed. May be able to delete. Check.
        print("nothing needed here")
    }
    
    func transition(to state: PreviewState) {
        print("nothing needed here")
    }
    
    func configureColorCell(field: UITextField, screenColor: UIColor) {
        textColorFrame.layer.borderColor = Colors.buttonTint.cgColor
        textBackgroundFrame.layer.borderColor = Colors.buttonTint.cgColor
        
        textColorButton.backgroundColor = field.textColor
        textBackgroundButton.backgroundColor = field.backgroundColor
        
        screenColorButton.backgroundColor = screenColor
        
        configureSlider()
        
        textColorFrame.layer.borderWidth = 1.0
        textColorButton.layer.borderWidth = 0.5
        textColorButton.layer.borderColor = UIColor.lightGray.cgColor
        textBackgroundButton.layer.borderWidth = 0.5
        textBackgroundButton.layer.borderColor = UIColor.lightGray.cgColor
        screenColorButton.layer.borderWidth = 0.5
        screenColorButton.layer.borderColor = UIColor.lightGray.cgColor
    }
    
    func configureSlider() {
        // Remove the prior slider. If you don't do this, you'll see a buildup of accumulating sliders in the view hierarchy (click debug view hierarcy to see, if you comment out the loop below
        for subview in self.contentView.subviews {
            if subview is ColorSlider {
                subview.removeFromSuperview()
            }
        }
        var colorSlider = ColorSlider()
        let cellFrame = CGRect(x: 0 + 16, y: 40, width: UIScreen.main.bounds.width - 16*2 , height: 20)
        let previewView = DefaultPreviewView(side: .top)
        previewView.offsetAmount = 10.0
        colorSlider = ColorSlider(orientation: .horizontal, previewView: previewView)
        colorSlider.color = textColorButton.backgroundColor!
        colorSlider.frame = cellFrame
        contentView.addSubview(colorSlider)
        colorSlider.addTarget(self, action: #selector(changedColor(_:)), for: .valueChanged)
    }
    
    @objc func changedColor(_ slider: ColorSlider) {
        colorHexValueField.text = slider.color.hexString
        delegate?.changeColorSelected(slider: slider, colorButtons: colorButtons, colorHexValueField: colorHexValueField, colorHexValueString: colorHexValueField.text!)
    }
    
    @IBAction func colorButtonPressed(_ sender: UIButton) {
        var slider = ColorSlider()
        for subview in self.contentView.subviews {
            if subview is ColorSlider {
                slider = subview as! ColorSlider
            }
        }
        
        colorHexValueField.text = colorButtons[sender.tag].backgroundColor?.hexString
        delegate?.setSelectedFrame(sender: sender, colorButtons: colorButtons, colorButtonFrames: colorButtonFrames, selectedButtonTag: sender.tag, colorHexValueField: colorHexValueField, slider: slider)
    }
    
    @IBAction func colorFieldDidChange(_ sender: AllowedCharsTextField) {
        var slider = ColorSlider()
        for subview in self.contentView.subviews {
            if subview is ColorSlider {
                slider = subview as! ColorSlider
            }
        }
        
        if sender.text! == "" {
            slider.color = UIColor.clear
            delegate?.changeColorSelected(slider: slider, colorButtons: colorButtons, colorHexValueField: colorHexValueField, colorHexValueString: "")
        } else if sender.text!.count == 6 {
            slider.color = UIColor.init(hexString: sender.text!)
            delegate?.changeColorSelected(slider: slider, colorButtons: colorButtons, colorHexValueField: colorHexValueField, colorHexValueString: colorHexValueField.text!)
        }
    }
    
}

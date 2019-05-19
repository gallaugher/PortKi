//
//  ColorTableViewCell.swift
//  PortKi
//
//  Created by John Gallaugher on 5/15/19.
//  Copyright © 2019 John Gallaugher. All rights reserved.
//

import UIKit
import ColorSlider

class ColorTableViewCell: UITableViewCell, ColorSliderPreviewing {
    @IBOutlet weak var textColorFrame: UIView!
    @IBOutlet weak var textColorButton: UIButton!
    @IBOutlet weak var textBackgroundFrame: UIView!
    @IBOutlet weak var textBackgroundButton: UIButton!
    @IBOutlet weak var colorHexValueField: UITextField!
    @IBOutlet weak var screenColorFrame: UIView!
    @IBOutlet weak var screenColorButton: UIButton!
    
    weak var delegate: ColorCellDelegate?
    
    func colorChanged(to color: UIColor) {
        print("nothing needed here")
    }
    
    func transition(to state: PreviewState) {
        print("nothing needed here")
    }
    
    func configureColorCell(textBlock: TextBlock) {
        textColorFrame.layer.borderColor = Colors.buttonTint.cgColor
        textBackgroundFrame.layer.borderColor = Colors.buttonTint.cgColor
        
        textColorButton.backgroundColor = textBlock.textColor
        textBackgroundButton.backgroundColor = textBlock.backgroundColor
        
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
        delegate?.changeColorSelected(slider: slider, textColorButton: textColorButton, textBackgroundButton: textBackgroundButton)
    }
    
    @IBAction func textColorPressed(_ sender: UIButton) {
        delegate?.setSelectedFrame(sender: sender, textColorSelected: true, textColorFrame: textColorFrame, textBackgroundFrame: textBackgroundFrame)
    }
    
    @IBAction func textBackgroundPressed(_ sender: UIButton) {
        delegate?.setSelectedFrame(sender: sender, textColorSelected: false, textColorFrame: textColorFrame, textBackgroundFrame: textBackgroundFrame)
    }
    
}

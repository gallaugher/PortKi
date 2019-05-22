//
//  UIFont+helpers.swift
//  PortKi
//
//  Created by John Gallaugher on 5/21/19.
//  Copyright © 2019 John Gallaugher. All rights reserved.
//

import UIKit

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


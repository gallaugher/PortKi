//
//  UIColor+toHex+initHex.swift
//  PortKi
//
//  Created by John Gallaugher on 5/20/19.
//  Copyright © 2019 John Gallaugher. All rights reserved.
//

import UIKit

extension UIColor {
    
    convenience init(hex: Int) {
        self.init(hex: hex, a: 1.0)
    }
    
    convenience init(hex: Int, a: CGFloat) {
        self.init(r: (hex >> 16) & 0xff, g: (hex >> 8) & 0xff, b: hex & 0xff, a: a)
    }
    
    convenience init(r: Int, g: Int, b: Int) {
        self.init(r: r, g: g, b: b, a: 1.0)
    }
    
    convenience init(r: Int, g: Int, b: Int, a: CGFloat) {
        self.init(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: a)
    }
    
    convenience init(hexString: String) {
        
        if hexString.count == 0 {
            self.init(red: 0, green: 0, blue: 0, alpha: 0)
        } else {
            let hexString = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
            let scanner = Scanner(string: hexString)
            
            if hexString.hasPrefix("#") {
                scanner.scanLocation = 1
            }
            
            var color: UInt32 = 0
            scanner.scanHexInt32(&color)
            
            let mask = 0x000000FF
            let r = Int(color >> 16) & mask
            let g = Int(color >> 8) & mask
            let b = Int(color) & mask
            
            let red   = CGFloat(r) / 255.0
            let green = CGFloat(g) / 255.0
            let blue  = CGFloat(b) / 255.0
            
            self.init(red: red, green: green, blue: blue, alpha: 1)
        }
    }
    
    var hexString: String {
        
        if self == UIColor.clear {
            return ""
        }
        
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb: Int = (Int)(r * 255) << 16 | (Int)(g * 255) << 8 | (Int)(b * 255) << 0
        
        // return String(format: "#%06x", rgb)
        return String(format: "%06x", rgb).uppercased()
    }
}

extension String {
    var hex: Int? {
        return Int(self, radix: 16)
    }
}


//extension UIColor {
//
//    // MARK: - Initialization
//
//    convenience init?(hex: String) {
//        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
//        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
//
//        var rgb: UInt32 = 0
//
//        var r: CGFloat = 0.0
//        var g: CGFloat = 0.0
//        var b: CGFloat = 0.0
//        var a: CGFloat = 1.0
//
//        let length = hexSanitized.count
//
//        guard Scanner(string: hexSanitized).scanHexInt32(&rgb) else { return nil }
//
//        if length == 6 {
//            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
//            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
//            b = CGFloat(rgb & 0x0000FF) / 255.0
//
//        } else if length == 8 {
//            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
//            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
//            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
//            a = CGFloat(rgb & 0x000000FF) / 255.0
//
//        } else {
//            return nil
//        }
//
//        self.init(red: r, green: g, blue: b, alpha: a)
//    }
//
//    // MARK: - Computed Properties
//
//    var toHex: String? {
//        return toHex()
//    }
//
//    // MARK: - From UIColor to String
//
//    func toHex(alpha: Bool = false) -> String? {
//        guard let components = cgColor.components, components.count >= 3 else {
//            return nil
//        }
//
//        let r = Float(components[0])
//        let g = Float(components[1])
//        let b = Float(components[2])
//        var a = Float(1.0)
//
//        if components.count >= 4 {
//            a = Float(components[3])
//        }
//
//        if alpha {
//            return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
//        } else {
//            return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
//        }
//    }
//
//}

//
//  String+removeEverythingAfter.swift
//  PortKi
//
//  Created by John Gallaugher on 7/28/19.
//  Copyright © 2019 John Gallaugher. All rights reserved.
//

import Foundation

extension String {
    func removeEverythingAfter(lastOccuranceOf: String) -> String {
        var fileName = self
        var fileNameComponents = fileName.components(separatedBy: lastOccuranceOf)
        if fileNameComponents.count > 1 {
            fileNameComponents.removeLast()
            fileName = fileNameComponents.joined(separator: ".")
        }
        return fileName
    }
}

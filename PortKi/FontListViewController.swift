//
//  FontListViewController.swift
//  PortKi
//
//  Created by John Gallaugher on 5/15/19.
//  Copyright © 2019 John Gallaugher. All rights reserved.
//

import UIKit

protocol PassFontDelegate {
    func getSelectedFont(selectedFont: UIFont)
}

class FontListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    var fontList: [String] = []
    var selectedFontIndex: Int!
    var selectedFont: UIFont!
    let fontSizeForCells: CGFloat = 20.0
    var delegate: PassFontDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        if selectedFont == nil {
            print("😡 ERROR: For some reason a font wasn't passed into FontListViewController.")
            selectedFont = UIFont.systemFont(ofSize: fontSizeForCells)
        }
        fontList = UIFont.familyNames
        fontList.append(UIFont.systemFont(ofSize: fontSizeForCells).familyName)
        fontList.sort()
        tableView.reloadData()
        let foundFontIndex = fontList.firstIndex(of: selectedFont.familyName)
        if foundFontIndex == nil {
            print("😡 ERROR: Font \(selectedFont.fontName) cannot be found on this device. Using System Font")
            selectedFontIndex = 0
        } else {
            selectedFontIndex = foundFontIndex!
        }
        selectedFont = UIFont(name: fontList[selectedFontIndex], size: fontSizeForCells)
        
        tableView.estimatedRowHeight = 600
        tableView.rowHeight = UITableView.automaticDimension
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let indexPathOfSelected = IndexPath(row: selectedFontIndex, section: 0)
        tableView.selectRow(at: indexPathOfSelected, animated: true, scrollPosition: .middle)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Make sure the selectedFont variable has been updated with the current selection, since this value is about to be passed back to the prior viewController in unwindFromFonts
        selectedFont = UIFont(name: fontList[selectedFontIndex], size: fontSizeForCells)
        delegate.getSelectedFont(selectedFont: selectedFont)
    }
}

extension FontListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fontList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CheckmarkTableViewCell
        configureCheckmark(for: cell, at: indexPath)
        let cellFont = UIFont(name: fontList[indexPath.row], size: 20.0)
        cell.fontLabel?.font = cellFont
        cell.fontLabel?.text = fontList[indexPath.row]
        cell.fontLabel.sizeToFit()
        return cell
    }
    
    func configureCheckmark(for cell: CheckmarkTableViewCell, at indexPath: IndexPath) {
        let selectedFontIndexPath = IndexPath(row: selectedFontIndex, section: 0)
        if selectedFontIndexPath == indexPath {
            // add check
            cell.checkMarkLabel.text = "✔️"
        } else {
            cell.checkMarkLabel.text = ""
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let oldSelectedIndexPath = IndexPath(row: selectedFontIndex, section: 0)
        let oldCell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: oldSelectedIndexPath) as! CheckmarkTableViewCell
        configureCheckmark(for: oldCell, at: oldSelectedIndexPath)
        selectedFontIndex = indexPath.row
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CheckmarkTableViewCell
        configureCheckmark(for: cell, at: indexPath)
        tableView.reloadData()
    }
}

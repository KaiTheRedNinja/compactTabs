//
//  CompactTabsToolbarView.swift
//  compactTabs
//
//  Created by TAY KAI QUAN on 25/8/22.
//

import Cocoa

class CompactTabsToolbarView: NSView {

    var textField: NSTextField

    override init(frame frameRect: NSRect) {
        textField = NSTextField(frame: frameRect)
        super.init(frame: frameRect)
        addViews(rect: frameRect)
    }

    required init?(coder: NSCoder) {
        textField = NSTextField()
        super.init(coder: coder)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }

    func addViews(rect: NSRect) {
        // init the go back button
        let goLeftTab = NSButton(image: NSImage(named: "chevron.left")!, target: self, action: #selector(goLeft))
        goLeftTab.isBordered = false
        goLeftTab.frame = CGRect(x: rect.width-50, y: (rect.height-12)/2, width: 25, height: 12)
        goLeftTab.bezelStyle = .regularSquare
        self.addSubview(goLeftTab)

        // init the go forward button
        let goRightTab = NSButton(image: NSImage(named: "chevron.right")!, target: self, action: #selector(goRight))
        goRightTab.isBordered = false
        goRightTab.frame = CGRect(x: rect.width-25, y: (rect.height-12)/2, width: 25, height: 12)
        goRightTab.bezelStyle = .regularSquare
        self.addSubview(goRightTab)

        // init the address bar
        textField = NSTextField(frame: NSRect(x: 0, y: 0, width: rect.width-50, height: rect.height))
        if let window = self.window?.windowController as? MainWindowController {
            textField.stringValue = window.urlBarAddress
        } else {
            textField.stringValue = ""
        }
        textField.delegate = self
        addSubview(textField)
    }

    @objc func goLeft() {
        print("Changing tabs")
        if let controller = self.window?.windowController as? MainWindowController {
            print("Changing tab")
            controller.goLeftOneTab()
        } else {
            print("No controller found")
        }
    }

    @objc func goRight() {
        print("Changing tabs")
        if let controller = self.window?.windowController as? MainWindowController {
            print("Changing tab")
            controller.goRightOneTab()
        } else {
            print("No controller found")
        }
    }
}

extension CompactTabsToolbarView: NSTextFieldDelegate {
    func controlTextDidEndEditing(_ obj: Notification) {
        // save the text
        if let controller = self.window?.windowController as? MainWindowController {
            controller.loadPage(address: textField.stringValue)
        }
    }
}

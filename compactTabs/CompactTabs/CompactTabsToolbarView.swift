//
//  CompactTabsToolbarView.swift
//  compactTabs
//
//  Created by TAY KAI QUAN on 25/8/22.
//

import Cocoa

class CompactTabsToolbarView: NSView {

    var textField: NSTextField
    var viewController: ViewController?
    var goLeftButton: NSButton?
    var goRightButton: NSButton?
    var tab: NSView?

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
        goLeftButton = goLeftTab
        self.addSubview(goLeftTab)

        // init the go forward button
        let goRightTab = NSButton(image: NSImage(named: "chevron.right")!, target: self, action: #selector(goRight))
        goRightTab.isBordered = false
        goRightTab.frame = CGRect(x: rect.width-25, y: (rect.height-12)/2, width: 25, height: 12)
        goRightTab.bezelStyle = .regularSquare
        goRightButton = goRightTab
        self.addSubview(goRightTab)

        // init the address bar
        textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300/*rect.width-50*/, height: rect.height))
        if let window = self.window?.windowController as? MainWindowController {
            textField.stringValue = window.urlBarAddress
        } else {
            textField.stringValue = ""
        }
        textField.delegate = self
        addSubview(textField)

        // TEMP: Init a tab
        let tab = NSView()
        tab.frame = CGRect(x: textField.frame.maxX + 10, y: 2, width: 70, height: rect.height-4)
        tab.wantsLayer = true
        tab.layer?.backgroundColor = NSColor.gray.cgColor
        tab.layer?.cornerRadius = 4
        self.tab = tab
        addSubview(tab)
    }

    @objc func goLeft() {
        if let controller = self.window?.windowController as? MainWindowController {
            controller.goLeftOneTab()
        }
    }

    @objc func goRight() {
        if let controller = self.window?.windowController as? MainWindowController {
            print("Changing tab")
            controller.goRightOneTab()
        }
    }

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        goLeftButton?.frame = NSRect(x: frame.width-50, y: (frame.height-12)/2, width: 25, height: 12)
        goRightButton?.frame = NSRect(x: frame.width-25, y: (frame.height-12)/2, width: 25, height: 12)
        textField.frame = NSRect(x: 0, y: 0, width: 300, height: frame.height)
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

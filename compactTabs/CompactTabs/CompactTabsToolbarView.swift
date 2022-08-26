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
    var tabs: [TabView]

    override init(frame frameRect: NSRect) {
        textField = NSTextField(frame: frameRect)
        tabs = []
        super.init(frame: frameRect)
        addViews(rect: frameRect)
    }

    required init?(coder: NSCoder) {
        tabs = []
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
        textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 230, height: rect.height))
        if let window = self.window?.windowController as? MainWindowController {
            textField.stringValue = window.urlBarAddress
        } else {
            textField.stringValue = ""
        }
        textField.delegate = self
        addSubview(textField)
    }

    // TODO: Don't recreate the tabs every time
    func updateTabs() {
        guard let viewController = viewController else { return }
        tabs.forEach({ $0.removeFromSuperview() })
        tabs = []
        for (index, tab) in viewController.tabs.enumerated() {
            let distance = tabs.last?.frame.maxX ?? textField.frame.maxX
            let tabView = TabView(frame: CGRect(x: distance + 10, y: 2, width: 70, height: frame.height-4))
            if viewController.focusedTab == index {
                tabView.becomeMain()
            }

            tabView.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(focusTab(sender:))))
            tabs.append(tabView)
            tabView.updateWith(url: tab.wkView?.url)
            addSubview(tabView)
        }
    }

    @objc func focusTab(sender: TabView) {
//        var toFocus = 0
//        for (index, tab) in tabs.enumerated() {
//            if sender.id == tab.id {
//                toFocus = index
//                tab.becomeMain()
//            } else {
//                tab.resignMain()
//            }
//        }
//        print("Focusing tab \(toFocus)")
//        viewController?.focusTab(tabIndex: toFocus)
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
        textField.frame = NSRect(x: 0, y: 0, width: 230, height: frame.height)
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

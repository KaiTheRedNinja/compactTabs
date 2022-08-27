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
        print("Updating tabs")
        guard let viewController = viewController else { return }
        tabs.forEach({ $0.removeFromSuperview() })
        tabs = []
        for (index, tab) in viewController.tabs.enumerated() {
            let distance = tabs.last?.frame.maxX ?? textField.frame.maxX
            let tabView = TabView(frame: CGRect(x: distance + 10, y: 2, width: 70, height: frame.height-4))
            tabView.compactTabsItem = self
            if viewController.focusedTab == index {
                tabView.becomeMain()
            }

            tabs.append(tabView)
            tabView.updateWith(wkView: tab.wkView)
            addSubview(tabView)
        }
        updateTabFrames()
    }

    let mainTabWidth = CGFloat(140.0)
    func updateTabFrames() {
        guard let mainTabIndex = viewController?.focusedTab else { return }
        let spaceForTabs = frame.width - textField.frame.maxX - 10
        let spaceForNonMainTabs = spaceForTabs - mainTabWidth
        let nonMainTabWidth = (spaceForNonMainTabs/CGFloat(tabs.count-1)) - 10
        print("non main width: \(nonMainTabWidth)")

        for (index, tab) in tabs.enumerated() {
            let distance = index == 0 ? textField.frame.maxX : tabs[index-1].frame.maxX
            tab.frame = CGRect(x: distance + 10, y: 2,
                               width: index == mainTabIndex ? mainTabWidth : nonMainTabWidth,
                               height: frame.height-4)
        }
    }

    @objc func focusTab(sender: TabView) {
        guard let toFocus = tabs.firstIndex(of: sender) else { return }
        viewController?.focusTab(tabIndex: toFocus)
    }

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        textField.frame = NSRect(x: 0, y: 0, width: 230, height: frame.height)
        updateTabFrames()
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

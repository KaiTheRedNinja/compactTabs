//
//  CompactTabsToolbarView.swift
//  compactTabs
//
//  Created by TAY KAI QUAN on 25/8/22.
//

import Cocoa

class CompactTabsToolbarView: NSView {

    var textField: NSTextField
    var reloadButton: NSButton?
    var viewController: ViewController?
    var scrollView: NSScrollView?
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

        // init the reload button
        let reloadButton = NSButton(image: NSImage(named: "reload")!, target: self, action: #selector(reloadCurrentPage))
        reloadButton.isBordered = false
        reloadButton.frame = CGRect(x: textField.frame.maxX - 20, y: 5, width: rect.height-10, height: rect.height-10)
        reloadButton.bezelStyle = .regularSquare
        self.reloadButton = reloadButton
        addSubview(reloadButton)

        // init the scroll view
        scrollView = NSScrollView(frame: NSRect(x: textField.frame.maxX+10, y: 2,
                                                width: rect.width-textField.frame.maxX-10,
                                                height: rect.height-4))
        scrollView?.documentView = NSView()
        scrollView?.wantsLayer = true
        scrollView?.layer?.cornerRadius = 4 // just a small attention to detail so that tabs don't look abruptly cut off
        addSubview(scrollView!)
    }

    /// Soft reload the tab bar by editing tabs
    func updateTabs() {
        guard let viewController = viewController else { return }
        // get the number of tabs there are, creating and removing tabs as needed
        if tabs.count < viewController.tabs.count {
            print("Creating missing tabs")
            // missing tabs, just create the remaining tabs
            let originalTabCount = tabs.count
            for (tabIndex, tab) in viewController.tabs.enumerated() {
                if tabIndex < originalTabCount { continue }
                let distance = tabs.last?.frame.maxX ?? 0
                let tabView = TabView(frame: CGRect(x: distance + 10, y: 2, width: 70, height: frame.height-4))
                tabView.compactTabsItem = self

                tabs.append(tabView)
                tabView.updateWith(wkView: tab.wkView)
                scrollView?.documentView?.addSubview(tabView)
            }
        } else if tabs.count > viewController.tabs.count {
            print("Deleting excess tabs")
            // too many tabs, delete extra tabs
            for (tabIndex, tab) in tabs.enumerated() {
                if tabIndex >= viewController.tabs.count {
                    tab.removeFromSuperview()
                } else {
                    tab.updateWith(wkView: viewController.tabs[tabIndex].wkView)
                }
            }
            tabs = Array(tabs[0..<viewController.tabs.count])
        }

        // update the tab body
        for (index, tabView) in tabs.enumerated() {
            tabView.updateWith(wkView: viewController.tabs[index].wkView)
        }
        updateTabFrames()
    }

    let mainTabWidth = CGFloat(140.0)

    /// Completely reload the tab bar by deleting all tabs and reloading
    func hardUpdateTabs() {
        // load the web view
        guard let viewController = viewController else { return }
        tabs.forEach({ $0.removeFromSuperview() })
        tabs = []
        for (index, tab) in viewController.tabs.enumerated() {
            let distance = tabs.last?.frame.maxX ?? 0
            let tabView = TabView(frame: CGRect(x: distance + 10, y: 2, width: 70, height: frame.height-4))
            tabView.compactTabsItem = self
            if viewController.focusedTab == index {
                tabView.becomeMain()
            }

            tabs.append(tabView)
            tabView.updateWith(wkView: tab.wkView)
            scrollView?.documentView?.addSubview(tabView)
        }
        updateTabFrames()
    }

    func updateTabFrames() {
        guard let mainTabIndex = viewController?.focusedTab else { return }
        let spaceForTabs = frame.width - textField.frame.maxX - 10
        let spaceForNonMainTabs = spaceForTabs - mainTabWidth
        let nonMainTabWidth = max((spaceForNonMainTabs/CGFloat(tabs.count-1)) - 10, 20)

        for (index, tab) in tabs.enumerated() {
            let distance = index == 0 ? -10 : tabs[index-1].frame.maxX
            tab.frame = CGRect(x: distance + 10, y: 0,
                               width: index == mainTabIndex ? mainTabWidth : nonMainTabWidth,
                               height: frame.height-4)
            if mainTabIndex == index {
                tab.becomeMain()
            } else {
                tab.resignMain()
            }
        }

        scrollView?.documentView?.frame = NSRect(x: 0, y: 0,
                                                 width: (tabs.last?.frame.maxX ?? 0) - (tabs.first?.frame.minX ?? 0),
                                                 height: frame.height-4)
    }

    func focusTab(sender: TabView) {
        guard let toFocus = tabs.firstIndex(of: sender) else { return }
        viewController?.focusTab(tabIndex: toFocus)
    }

    func closeTab(sender: TabView) {
        guard let toClose = tabs.firstIndex(of: sender) else { return }
        viewController?.closeTab(tabIndex: toClose)
    }

    @objc func reloadCurrentPage() {
        viewController?.reloadTab()
    }

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        textField.frame = NSRect(x: 0, y: 0, width: 230, height: frame.height)
        reloadButton?.frame = CGRect(x: textField.frame.maxX - 20, y: 5, width: frame.height-10, height: frame.height-10)
        scrollView?.frame = NSRect(x: textField.frame.maxX+10, y: 2,
                                   width: frame.width-textField.frame.maxX-10,
                                   height: frame.height-4)
        updateTabs()
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

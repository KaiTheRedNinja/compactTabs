//
//  CompactTabsToolbarView.swift
//  compactTabs
//
//  Created by TAY KAI QUAN on 25/8/22.
//

import Cocoa

class CompactTabsToolbarView: NSView {

    var viewController: ViewController?

    var textField: NSTextField
    var reloadButton: NSButton?
    var scrollView: NSScrollView?
    var addTabButton: NSButton?
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
        // the frames of all the items don't actually have to be created yet. They're set when the window inevitably resizes.

        // init the address bar
        textField = NSTextField()
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
        reloadButton.bezelStyle = .regularSquare
        self.reloadButton = reloadButton
        addSubview(reloadButton)

        // init the add tab button
        let addTabButton = NSButton(image: NSImage(named: "plus")!, target: self, action: #selector(addTab))
        addTabButton.isBordered = false
        addTabButton.bezelStyle = .regularSquare
        self.addTabButton = addTabButton
        addSubview(addTabButton)

        // init the scroll view
        scrollView = NSScrollView()
        scrollView?.documentView = NSView()
        scrollView?.wantsLayer = true
        scrollView?.layer?.cornerRadius = 4 // just a small attention to detail so that tabs don't look abruptly cut off
        addSubview(scrollView!)
    }

    // MARK: Tab actions
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
                scrollView?.documentView?.addSubview(tabView)
                tabView.updateWith(wkView: tab.wkView)
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

    @objc func addTab() {
        viewController?.createTab()
    }

    // MARK: Resizing functions

    let defaultMainTabWidth = CGFloat(140.0)
    let minimumNonMainTabWidth = CGFloat(30.0)
    func updateTabFrames() {
        guard let mainTabIndex = viewController?.focusedTab, let scrollView = scrollView else { return }
        var mainTabWidth = defaultMainTabWidth
        var nonMainTabWidth = minimumNonMainTabWidth

        // check if theres enough space for everything to be full width
        if (mainTabWidth + 10) * CGFloat(tabs.count) - 10 <= scrollView.frame.width {
            // resize everything to fit the view
            mainTabWidth = (scrollView.frame.width+10) / CGFloat(tabs.count) - 10
            nonMainTabWidth = mainTabWidth
        } else {
            // the main tab must be 140 wide, so constrain the non main tabs
            let availableSpace = scrollView.frame.width-mainTabWidth
            nonMainTabWidth = max((availableSpace / CGFloat(tabs.count-1)) - 10,
                                  minimumNonMainTabWidth)
        }

        for (index, tab) in tabs.enumerated() {
            print("Updating frame for \(tab.textView.stringValue). Width: \(index == mainTabIndex ? mainTabWidth : nonMainTabWidth)")
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

        scrollView.documentView?.frame = NSRect(x: 0, y: 0,
                                                 width: (tabs.last?.frame.maxX ?? 0) - (tabs.first?.frame.minX ?? 0),
                                                 height: frame.height-4)
    }

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        textField.frame = NSRect(x: 0, y: 0, width: 230, height: frame.height)
        reloadButton?.frame = CGRect(x: textField.frame.maxX - 20, y: 5, width: frame.height-10, height: frame.height-10)
        addTabButton?.frame = CGRect(x: frame.maxX - frame.height-10, y: 5, width: frame.height-10, height: frame.height-10)
        scrollView?.frame = NSRect(x: textField.frame.maxX+10, y: 2,
                                   width: (addTabButton?.frame.minX ?? 0) - textField.frame.maxX - 20,
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

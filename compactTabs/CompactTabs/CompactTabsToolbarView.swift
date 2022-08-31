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

    func addViews(rect: NSRect) {
        // the frames of all the items don't actually have to be created yet. They're set when the window inevitably resizes.

        // init the address bar
        textField.stringValue = ""
        textField.delegate = self
        textField.target = self
        textField.action = #selector(updateURL)
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
        scrollView?.verticalScrollElasticity = .none
    }

    // MARK: Tab actions
    /// Soft reload the tab bar by adding new tabs and marking removed ones as to be removed
    func updateTabs() {
        guard let viewController = viewController else { return }

        // get the number of tabs there are, creating and removing tabs as needed
        if tabs.filter({ !$0.willBeDeleted }).count < viewController.tabs.count {
            // missing tabs, just create the remaining tabs
            // Due to the way the code is implemented, tabs can only be created as the last item.
            let originalTabCount = tabs.filter({ !$0.willBeDeleted }).count
            for (tabIndex, tab) in viewController.tabs.enumerated() {
                if tabIndex < originalTabCount { continue }
                let distance = tabs.last?.frame.maxX ?? 0
                let tabView = TabView(frame: CGRect(x: distance + 10, y: 0, width: tabs.count == 0 ? 70 : 0,
                                                    height: scrollView?.documentView?.frame.height ?? 15))
                tabView.updateWith(webPageView: tab)
                tabView.compactTabsItem = self

                tabs.append(tabView)
                scrollView?.documentView?.addSubview(tabView)
                tabView.updateWith(webPageView: tab)
            }
        } else if tabs.filter({ !$0.willBeDeleted }).count > viewController.tabs.count {
            // too many tabs, delete extra tabs
            var deletedTabs = 0
            for tab in tabs {
                // Mark the extra tab as will be deleted. This view will be animated out and removed in the updateTabFrames function.
                if let webPage = tab.ascociatedWebPageView, !viewController.tabs.contains(webPage) {
                    tab.willBeDeleted = true
                    deletedTabs += 1
                }
            }
        }

        // update the tab body. Skip tabs that are marked as will be deleted.
        var deletedTabs = 0
        for (index, tabView) in tabs.enumerated() {
            if !tabView.willBeDeleted {
                tabView.updateWith(webPageView: viewController.tabs[index-deletedTabs])
            } else {
                deletedTabs += 1
            }
        }

        updateAddressBarText()

        // most of the time if the tabs' frames are animated, its due to a tab being added or removed.
        updateTabFrames(animated: true)
    }

    @objc
    func updateURL() {
        viewController?.loadPage(address: textField.stringValue)
    }

    func updateAddressBarText() {
        if let viewController = viewController, viewController.tabs.count > 0 {
            textField.stringValue = viewController.tabs[viewController.focusedTab].wkView?.url?.debugDescription ?? ""
        } else {
            textField.stringValue = ""
        }
    }

    // MARK: View Controller Tab Actions
    func focusTab(sender: TabView) {
        print("Focusing tab \(sender.textView.stringValue)")
        guard let toFocus = tabs.filter({ !$0.willBeDeleted }).firstIndex(of: sender) else { return }
        if toFocus == viewController?.focusedTab ?? -1 {
            textField.becomeFirstResponder()
        } else {
            viewController?.focusTab(tabIndex: toFocus)
        }
    }

    func closeTab(sender: TabView) {
        guard let toClose = tabs.filter({ !$0.willBeDeleted }).firstIndex(of: sender) else { return }
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
}

extension CompactTabsToolbarView: NSTextFieldDelegate {

    /// Act on the text in the address bar when editing finished.
    /// - Parameter obj: A notification
    func controlTextDidEndEditing(_ obj: Notification) {
        // remove any invalid characters
        textField.stringValue = textField.stringValue.replacingOccurrences(of: "\n", with: "")
    }
}

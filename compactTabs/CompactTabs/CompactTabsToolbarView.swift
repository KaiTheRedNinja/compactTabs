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
                tabView.updateWith(webPageView: tab)
            }
        } else if tabs.count > viewController.tabs.count {
            print("Deleting excess tabs")
            // too many tabs, delete extra tabs
            var deletedTabs = 0
            for (tabIndex, tab) in tabs.enumerated() {
                if let webPage = tab.ascociatedWebPageView, !viewController.tabs.contains(webPage) {
                    print("Tab \(tab.textView.stringValue) to be removed/")
                    tab.willBeDeleted = true
                    deletedTabs += 1
                } else {
                    tab.updateWith(webPageView: viewController.tabs[tabIndex-deletedTabs])
                }
            }
        }

        // update the tab body
        var deletedTabs = 0
        for (index, tabView) in tabs.enumerated() {
            if !tabView.willBeDeleted {
                tabView.updateWith(webPageView: viewController.tabs[index-deletedTabs])
            } else {
                deletedTabs += 1
            }
        }

        updateTabFrames(animated: true)
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
    func updateTabFrames(animated: Bool = false) {
        guard let mainTabIndex = viewController?.focusedTab, let scrollView = scrollView else { return }
        var mainTabWidth = defaultMainTabWidth
        var nonMainTabWidth = minimumNonMainTabWidth
        let numberOfRealTabs = tabs.filter({ !$0.willBeDeleted }).count

        // check if theres enough space for everything to be full width
        if (mainTabWidth + 10) * CGFloat(numberOfRealTabs) - 10 <= scrollView.frame.width {
            // resize everything to fit the view
            mainTabWidth = (scrollView.frame.width+10) / CGFloat(numberOfRealTabs) - 10
            nonMainTabWidth = mainTabWidth
        } else {
            // the main tab must be 140 wide, so constrain the non main tabs
            let availableSpace = scrollView.frame.width-mainTabWidth
            nonMainTabWidth = max((availableSpace / CGFloat(numberOfRealTabs-1)) - 10,
                                  minimumNonMainTabWidth)
        }

        var distance = CGFloat(-10)
        var index = 0
        for tab in tabs {
            var newWidth = tab.willBeDeleted ? -10 : (index == mainTabIndex ? mainTabWidth : nonMainTabWidth)
            if animated {
                print("Animating frame for \(tab.textView.stringValue). Width: \(index == mainTabIndex ? mainTabWidth : nonMainTabWidth)")
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.2

                    // Change the width
                    tab.animator().frame = CGRect(x: distance + 10, y: 0,
                                                  width: newWidth,
                                                  height: frame.height-4)
                }) {
                    if tab.willBeDeleted {
                        print("Deleting tab")
                        tab.removeFromSuperview()
                        self.tabs.removeAll(where: {
                            $0 == tab
                        })
                    }
                }
            } else {
                print("Updating frame for \(tab.textView.stringValue). Width: \(index == mainTabIndex ? mainTabWidth : nonMainTabWidth)")
                tab.frame = CGRect(x: distance + 10, y: 0,
                                              width: newWidth,
                                              height: frame.height-4)
                if tab.willBeDeleted {
                    tab.removeFromSuperview()
                }
            }
            distance = distance + 10 + newWidth
            if mainTabIndex == index {
                tab.becomeMain()
            } else {
                tab.resignMain()
            }

            if !tab.willBeDeleted {
                index += 1
            }
        }

        scrollView.documentView?.frame = NSRect(x: 0, y: 0,
                                                 width: distance,
                                                 height: frame.height-4)
    }

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        textField.frame = NSRect(x: 0, y: 0, width: 230, height: frame.height)
        reloadButton?.frame = CGRect(x: textField.frame.maxX - 20, y: 5, width: frame.height-10, height: frame.height-10)
        addTabButton?.frame = CGRect(x: frame.maxX - frame.height-10, y: 5, width: frame.height-10, height: frame.height-10)
        scrollView?.frame = NSRect(x: textField.frame.maxX+10, y: 2,
                                   width: (addTabButton?.frame.minX ?? 0) - textField.frame.maxX - 20,
                                   height: frame.height-4)
        updateTabFrames(animated: false)
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

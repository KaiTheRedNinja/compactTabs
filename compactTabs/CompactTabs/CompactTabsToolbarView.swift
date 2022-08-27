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
    /// Soft reload the tab bar by adding new tabs and marking removed ones as to be removed
    func updateTabs() {
        guard let viewController = viewController else { return }

        // get the number of tabs there are, creating and removing tabs as needed
        if tabs.count < viewController.tabs.count {
            print("Creating missing tabs")
            // missing tabs, just create the remaining tabs
            // Due to the way the code is implemented, tabs can only be created as the last item.
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
                // Mark the extra tab as will be deleted. This view will be animated out and removed in the updateTabFrames function.
                if let webPage = tab.ascociatedWebPageView, !viewController.tabs.contains(webPage) {
                    print("Tab \(tab.textView.stringValue) to be removed/")
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

        // most of the time if the tabs' frames are animated, its due to a tab being added or removed.
        updateTabFrames(animated: true)
    }

    // MARK: View Controller Tab Actions
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
    /// Update the frames of the ``TabView``s
    /// - Parameter animated: If the frames should be animated or not
    func updateTabFrames(animated: Bool = false) {
        guard let mainTabIndex = viewController?.focusedTab, let scrollView = scrollView else { return }
        var mainTabWidth = defaultMainTabWidth
        var nonMainTabWidth = minimumNonMainTabWidth
        let numberOfRealTabs = tabs.filter({ !$0.willBeDeleted }).count // only "real" (not to be deleted) tabs count towards the width by the end of the animation

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

        var distance = CGFloat(-10) // To know where to place the tab
        var index = 0
        for tab in tabs {
            // if the tab will be deleted, set its width to -10.
            // Else, set it to the main tab width or non main tab width depending on if its the current tab.
            let newWidth = tab.willBeDeleted ? -10 : (index == mainTabIndex ? mainTabWidth : nonMainTabWidth)
            if animated {
                print("Animating frame for \(tab.textView.stringValue). Width: \(index == mainTabIndex ? mainTabWidth : nonMainTabWidth)")
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = animationDuration

                    // Change the width
                    tab.animator().frame = CGRect(x: distance + 10, y: 0,
                                                  width: newWidth,
                                                  height: frame.height-4)
                }) {
                    // if the tab is to be deleted, remove the tab from the superview and array when it has been animated out.
                    if tab.willBeDeleted {
                        print("Deleting tab")
                        tab.removeFromSuperview()
                        self.tabs.removeAll(where: { $0 == tab })
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

            // Increase the distance accordingly. The tab's maxX cannot be used because it might be being animated.
            distance = distance + 10 + newWidth

            // Set the tab to main or not main depending if its the currently selected tab
            if mainTabIndex == index {
                tab.becomeMain()
            } else {
                tab.resignMain()
            }

            // If the tab is to be deleted, don't count it because it technically doesn't exist.
            if !tab.willBeDeleted {
                index += 1
            }
        }

        // Set the scroll view's document view to be the total tabs width
        scrollView.documentView?.frame = NSRect(x: 0, y: 0,
                                                 width: distance,
                                                 height: frame.height-4)
    }

    /// Resize the text field, reload button, add tab button and tabs button to fit a new size.
    /// - Parameter oldSize: The old size of the view
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

    /// Act on the text in the address bar when editing finished.
    /// - Parameter obj: A notification
    func controlTextDidEndEditing(_ obj: Notification) {
        // save the text
        if let controller = self.window?.windowController as? MainWindowController {
            controller.loadPage(address: textField.stringValue)
        }
    }
}

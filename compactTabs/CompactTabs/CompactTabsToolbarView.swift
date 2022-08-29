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
        textField.stringValue = ""
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
                let tabView = TabView(frame: CGRect(x: distance + 10, y: 2, width: 0, height: frame.height-4))
                tabView.compactTabsItem = self

                tabs.append(tabView)
                scrollView?.documentView?.addSubview(tabView)
                tabView.updateWith(webPageView: tab)
            }
        } else if tabs.count > viewController.tabs.count {
            print("Deleting excess tabs")
            // too many tabs, delete extra tabs
            var deletedTabs = 0
            for tab in tabs {
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

    func updateAddressBarText() {
        print("Updating address bar text")
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
        viewController?.focusTab(tabIndex: toFocus)
    }

    func closeTab(sender: TabView) {
        textField.resignFirstResponder()
        guard let toClose = tabs.filter({ !$0.willBeDeleted }).firstIndex(of: sender) else { return }
        viewController?.closeTab(tabIndex: toClose)
    }

    @objc func reloadCurrentPage() {
        viewController?.reloadTab()
    }

    @objc func addTab() {
        textField.resignFirstResponder()
        viewController?.createTab()
    }

    // MARK: Resizing functions

    let defaultMainTabWidth = CGFloat(140.0)
    let minimumNonMainTabWidth = CGFloat(30.0)
    /// Update the frames of the ``TabView``s
    /// - Parameter animated: If the frames should be animated or not
    private func updateTabFrames(animated: Bool = false) {
        guard let mainTabIndex = viewController?.focusedTab, let scrollView = scrollView else { return }
        var nonMainTabWidth = minimumNonMainTabWidth
        let numberOfRealTabs = tabs.filter({ !$0.willBeDeleted }).count // only "real" (not to be deleted) tabs count towards the width by the end of the animation

        // the main tab must be 140 wide, so constrain the non main tabs
        let availableSpace = scrollView.frame.width-defaultMainTabWidth
        nonMainTabWidth = min(defaultMainTabWidth,
                              max((availableSpace / CGFloat(numberOfRealTabs-1)) - 10,
                                  minimumNonMainTabWidth))

        var distance = CGFloat(-10) // To know where to place the tab
        var index = 0
        for tab in tabs {
            // if the tab will be deleted, set its width to -10.
            // Else, set it to the main tab width or non main tab width depending on if its the current tab.
            let newWidth = tab.willBeDeleted ? -10 : (index == mainTabIndex ? defaultMainTabWidth : nonMainTabWidth)
            if animated {
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = animationDuration

                    // Change the width
                    tab.animator().frame = CGRect(x: distance + (tab.willBeDeleted ? 5 : 10), y: 0,
                                                  width: max(0, newWidth),
                                                  height: frame.height-4)
                }) {
                    // if the tab is to be deleted, remove the tab from the superview and array when it has been animated out.
                    if tab.willBeDeleted {
                        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration, execute: {
                            tab.removeFromSuperview()
                            self.tabs.removeAll(where: { $0 == tab })
                        })
                    }
                }
            } else {
                tab.frame = CGRect(x: distance + 10, y: 0,
                                              width: newWidth,
                                              height: frame.height-4)
                if tab.willBeDeleted {
                    tab.removeFromSuperview()
                    self.tabs.removeAll(where: { $0 == tab })
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
        if animated {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = animationDuration
                scrollView.animator().documentView?.frame = NSRect(x: 0, y: 0,
                                                                   width: max(scrollView.contentView.frame.width, distance),
                                                                   height: self.frame.height-4)
            })
        } else {
            scrollView.documentView?.frame = NSRect(x: 0, y: 0,
                                                    width: max(scrollView.contentView.frame.width, distance),
                                                    height: frame.height-4)
        }
    }

    /// Resize the text field, reload button, add tab button and tabs button to fit a new size.
    /// - Parameter oldSize: The old size of the view
    override func resizeSubviews(withOldSize oldSize: NSSize) {
        updateViews(animate: false)
    }

    func updateViews(animate: Bool = false) {
        updateAddressBarText()

        // if theres no tabs open, then just show the URL bar with no tabs
        if (viewController?.tabs.count ?? 0) == 0 {
            textField.becomeFirstResponder()
            if animate {
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = animationDuration
                    textField.animator().frame = NSRect(x: 20, y: 0, width: frame.width-60, height: frame.height)
                    reloadButton?.animator().frame = CGRect(x: frame.width-60, y: 5, width: frame.height-10, height: frame.height-10)
                    addTabButton?.animator().frame = CGRect(x: frame.maxX - frame.height-10, y: 5, width: frame.height-10, height: frame.height-10)
                    scrollView?.animator().frame = NSRect(x: frame.maxX - frame.height-10, y: 2,
                                                          width: 0,
                                                          height: frame.height-4)
                })
            } else {
                textField.frame = NSRect(x: 20, y: 0, width: frame.width-60, height: frame.height)
                reloadButton?.frame = CGRect(x: frame.width-60, y: 5, width: frame.height-10, height: frame.height-10)
                addTabButton?.frame = CGRect(x: frame.maxX - frame.height-10, y: 5, width: frame.height-10, height: frame.height-10)
                scrollView?.frame = NSRect(x: frame.maxX - frame.height-10, y: 2,
                                           width: 0,
                                           height: frame.height-4)
            }

        // else, show the tabs
        } else {
            if animate {
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = animationDuration
                    textField.animator().frame = NSRect(x: 0, y: 0, width: 230, height: frame.height)
                    reloadButton?.animator().frame = CGRect(x: 210, y: 5, width: frame.height-10, height: frame.height-10)
                    addTabButton?.animator().frame = CGRect(x: frame.maxX - frame.height-10, y: 5, width: frame.height-10, height: frame.height-10)
                    scrollView?.animator().frame = NSRect(x: 240, y: 2,
                                                          width: frame.maxX - frame.height - 260,
                                                          height: frame.height-4)
                })
            } else {
                textField.frame = NSRect(x: 0, y: 0, width: 230, height: frame.height)
                reloadButton?.frame = CGRect(x: 210, y: 5, width: frame.height-10, height: frame.height-10)
                addTabButton?.frame = CGRect(x: frame.maxX - frame.height-10, y: 5, width: frame.height-10, height: frame.height-10)
                scrollView?.frame = NSRect(x: 240, y: 2,
                                           width: frame.maxX - frame.height - 260,
                                           height: frame.height-4)
            }
        }

        if animate {
            updateTabs()
        } else {
            updateTabFrames()
        }
    }
}

extension CompactTabsToolbarView: NSTextFieldDelegate {

    /// Act on the text in the address bar when editing finished.
    /// - Parameter obj: A notification
    func controlTextDidEndEditing(_ obj: Notification) {
        // Load the page
        viewController?.loadPage(address: textField.stringValue)
    }
}

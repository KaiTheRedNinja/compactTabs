//
//  CompactTabsToolbar+Resize.swift
//  compactTabs
//
//  Created by TAY KAI QUAN on 29/8/22.
//

import Cocoa

extension CompactTabsToolbarView {
    /// Update the frames of the ``TabView``s
    /// - Parameter animated: If the frames should be animated or not
    func updateTabFrames(animated: Bool = false, reposition: Bool = true) {
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
            var newWidth = index == mainTabIndex ? defaultMainTabWidth : nonMainTabWidth
            if tab.willBeDeleted { newWidth = -10 }
            newWidth += defaultMainTabWidth * tab.zoomAmount
            if animated {
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = animationDuration

                    // Change the width
                    tab.animator().frame = CGRect(x: distance + (tab.willBeDeleted ? 5 : 10), y: 0,
                                                  width: max(0, newWidth),
                                                  height: frame.height-4)
                    // Change the opacity
                    if tab.willBeDeleted {
                        tab.animator().alphaValue = 0.0
                    }
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

        guard reposition else { return } // only move the scroll view to show the current tab if the function isn't told otherwise

        var scrollTo: NSPoint? = nil
        // scroll the document view to reveal the current tab
        if let currentTab = tabs.first(where: { $0.isMain }) {
            // check if the current tab is smaller than the content view,
            // and if the current tab is not fully in the visible section of the scroll view
            if currentTab.frame.width < scrollView.contentView.frame.width &&
                !(currentTab.frame.minX >= scrollView.documentVisibleRect.minX &&
                    currentTab.frame.maxX <= scrollView.documentVisibleRect.maxX) {
                // check if it is possible to scroll to the start of the tab
                if (scrollView.contentView.frame.width - currentTab.frame.minX) >=
                    scrollView.documentVisibleRect.width {
                    print("Scrolling to full visible")
                    scrollTo = NSPoint(x: currentTab.frame.minX, y: 0)
                } else {
                    print("Scrolling to end visible")
                    scrollTo = NSPoint(x: currentTab.frame.maxX, y: 0)
                }

            // if the tab's width isn't smaller than the visible rect
            // check if the current tab's starting point isn't within the visible section
            } else if !(currentTab.frame.minX >= scrollView.documentVisibleRect.minX) {
                // it will always be possible to scroll to the start of the tab if the tab width
                // is smaller than the visible rect.
                print("Scrolling to start visible")
                scrollTo = NSPoint(x: currentTab.frame.minX, y: 0)
            }
        }
        if let scrollTo = scrollTo {
            print("Scrolling to \(scrollTo)")
            scrollView.contentView.scroll(scrollTo)
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
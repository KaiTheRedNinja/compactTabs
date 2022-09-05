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
        // the view controller and scrollview must exist to be able to update tab frames
        guard let viewController = viewController, let scrollView = scrollView else { return }

        // get the current tab index and WebPageView
        let mainTabIndex = viewController.focusedTab
        let currentTab: WebPageView? = (viewController.tabs.count > 0) ? viewController.tabs[mainTabIndex] : nil

        // only "real" (not to be deleted) tabs count towards the width by the end of the animation
        let numberOfRealTabs = tabs.realTabCount

        // the main tab must be 140 wide, so constrain the non main tabs
        let availableSpace = scrollView.frame.width-defaultMainTabWidth
        var nonMainTabWidth = min(defaultMainTabWidth,
                                  max((availableSpace / CGFloat(numberOfRealTabs-1)) - 10,
                                      minimumNonMainTabWidth))

        // Keeps track of how far away from (0,0) the tabs are, so that the program knows where to place them
        var distance = CGFloat(-10)
        var index = 0

        for tab in tabs {
            // if the tab will be deleted, set its width to -10.
            // Else, set it to the main tab width or non main tab width depending on if its the current tab.
            var newWidth = CGFloat(-10)
            if !tab.willBeDeleted {
                newWidth = index == mainTabIndex ? defaultMainTabWidth : nonMainTabWidth
                // Increase its width by its zoom amount
                newWidth += defaultMainTabWidth * max(0, tab.zoomAmount)
            }

            if animated {
                tab.isAnimating = true // flip a flag that marks the tab as animating
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = animationDuration

                    // Change the width
                    if tab.isPanning { // if the tab is being dragged, don't change its view x and y because its handling it itself
                        tab.animator().frame = CGRect(x: tab.frame.minX, y: 0,
                                                      width: max(0, newWidth),
                                                      height: scrollView.documentView?.frame.height ?? 15)
                    } else {
                        tab.animator().frame = CGRect(x: distance + (tab.willBeDeleted ? 5 : 10), y: 0,
                                                      width: max(0, newWidth),
                                                      height: scrollView.documentView?.frame.height ?? 15)
                    }
                    // Change the opacity
                    if tab.willBeDeleted {
                        tab.animator().alphaValue = 0.0
                    }
                }) { // on completion, mark the tab as not animating
                    tab.isAnimating = false
                    // if the tab is to be deleted, remove the tab from the superview and array when it has been animated out.
                    if tab.willBeDeleted {
                        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration, execute: {
                            tab.removeFromSuperview()
                            self.tabs.removeAll(where: { $0 == tab })
                        })
                    }
                }
            } else {
                // if not animating, just delete the tab or set the frame straight away
                if tab.willBeDeleted {
                    tab.removeFromSuperview()
                    self.tabs.removeAll(where: { $0 == tab })
                } else {
                    tab.frame = CGRect(x: distance + 10, y: 0,
                                       width: newWidth,
                                       height: scrollView.documentView?.frame.height ?? 15)
                }
            }

            // Increase the distance accordingly. The tab's maxX cannot be used because it might be being animated.
            distance += newWidth + 10

            // Set the tab to main or not main depending if its the currently selected tab
            if currentTab == tab.ascociatedWebPageView {
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
                                                                   height: scrollView.frame.height)
            })
        } else {
            scrollView.documentView?.frame = NSRect(x: 0, y: 0,
                                                    width: max(scrollView.contentView.frame.width, distance),
                                                    height: scrollView.frame.height)
        }

        if reposition {
            // only move the scroll view to show the current tab if the function isn't told otherwise
            scrollToTabVisible()
        }
    }

    func scrollToTabVisible() {
        guard let scrollView = scrollView else { return }
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
                    scrollTo = NSPoint(x: currentTab.frame.minX, y: 0)
                } else {
                    // scroll to the end of the tab if its not possible to scroll to the start
                    scrollTo = NSPoint(x: currentTab.frame.maxX, y: 0)
                }

            // if the tab's width isn't smaller than the visible rect
            // check if the current tab's starting point isn't within the visible section
            } else if !(currentTab.frame.minX >= scrollView.documentVisibleRect.minX) {
                // it will always be possible to scroll to the start of the tab if the tab width
                // is smaller than the visible rect.
                scrollTo = NSPoint(x: currentTab.frame.minX, y: 0)
            }
        }
        if let scrollTo = scrollTo {
            scrollView.contentView.scroll(scrollTo)
        }
    }

    /// Repositions tabs when one is being dragged around
    /// - Parameters:
    ///   - movingTab: The tab being dragged
    ///   - state: The state of the pan gesture moving the tab
    func repositionTabs(movingTab: TabView, state: NSPanGestureRecognizer.State) {

        // the point that we use to determine if the tab should be moved
        let referencePoint = NSPoint(x: movingTab.frame.midX, y: 0)
        var repositioned = false

        for (index, tab) in tabs.enumerated() {
            // ignore deleting, panning, and animating tabs
            guard !tab.willBeDeleted && !tab.isPanning && !tab.isAnimating else { continue }
            if referencePoint.x < tab.frame.maxX && referencePoint.x >= tab.frame.midX {
                // the dragged point is on the right side of this tab
                repositioned = true
                if let movingTabPosition = tabs.firstIndex(of: movingTab) {
                    tabs.remove(at: movingTabPosition)
                    let goTo = tabs.firstIndex(of: tab) ?? (movingTabPosition - 1)
                    tabs.insert(movingTab, at: goTo + 1)
                }
                break
            } else if referencePoint.x > tab.frame.minX && referencePoint.x < tab.frame.midX {
                // the dragged point is on the left side of this tab
                repositioned = true
                if let movingTabPosition = tabs.firstIndex(of: movingTab) {
                    tabs.remove(at: movingTabPosition)
                    tabs.insert(movingTab, at: index)
                }
                break
            }
        }

        if state == .ended || repositioned {
            // reorder the tabs in view controller to match tab bar
            viewController?.tabs = viewController?.tabs.sorted(by: { vcTab1, vcTab2 in
                let firstLocation = tabs.firstIndex(where: { $0.ascociatedWebPageView == vcTab1 })
                let secondLocation = tabs.firstIndex(where: { $0.ascociatedWebPageView == vcTab2 })
                return firstLocation ?? -1 < secondLocation ?? -1
            }) ?? []
            if let toFocus = viewController?.tabs.firstIndex(where: { movingTab.ascociatedWebPageView == $0 }) {
                viewController?.focusTab(tabIndex: toFocus)
            }
        }

        updateTabFrames(animated: (state == .ended) ? true : repositioned, reposition: false)
    }

    /// Resize the text field, reload button, add tab button and tabs button to fit a new size.
    /// - Parameter oldSize: The old size of the view
    override func resizeSubviews(withOldSize oldSize: NSSize) {
        updateViews(animate: false)
    }

    func updateViews(animate: Bool = false) {
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
                                           height: frame.height-2)
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
                                                          height: frame.height-3)
                })
            } else {
                textField.frame = NSRect(x: 0, y: 0, width: 230, height: frame.height)
                reloadButton?.frame = CGRect(x: 210, y: 5, width: frame.height-10, height: frame.height-10)
                addTabButton?.frame = CGRect(x: frame.maxX - frame.height-10, y: 5, width: frame.height-10, height: frame.height-10)
                scrollView?.frame = NSRect(x: 240, y: 2,
                                           width: frame.maxX - frame.height - 260,
                                           height: frame.height-3)
            }
        }

        if animate {
            updateTabs()
        } else {
            updateTabFrames()
        }
    }
}

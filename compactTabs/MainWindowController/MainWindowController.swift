//
//  MainWindowController.swift
//  compactTabs
//
//  Created by TAY KAI QUAN on 25/8/22.
//

// Contains code from: https://github.com/marioaguzman/toolbar/blob/master/Toolbar/Main%20Window/MainWindowController.swift

import Cocoa

class MainWindowController: NSWindowController, NSToolbarItemValidation {

    var compactTabsItem: CompactTabsToolbarView?

    override func windowDidLoad() {
        super.windowDidLoad()

        self.window?.minSize = NSSize(width: 600, height: 400)
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.

        self.window?.delegate = self
        configToolbar()

        if let viewController = self.contentViewController as? ViewController {
            viewController.mainWindow = self
        }
    }

    override init(window: NSWindow?) {
        urlBarAddress = "Window init"
        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        urlBarAddress = "Coder init"
        super.init(coder: coder)
    }

    func configToolbar() {
        if  let unwrappedWindow = self.window {
            let toolbar = NSToolbar(identifier: UUID().uuidString)
            toolbar.delegate = self
            toolbar.allowsUserCustomization = false // TODO: Allow customisation of toolbar
            toolbar.autosavesConfiguration = true
            toolbar.displayMode = .default

            // Center-pin the compact tabs toolbar item
            toolbar.centeredItemIdentifier = .compactTabsToolbarItem

            // Hiding the title visibility in order to gain more toolbar space.
            // Set this property to .visible or delete this line to get it back.
            unwrappedWindow.titleVisibility = .hidden

            unwrappedWindow.toolbar = toolbar
        }
    }

    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        return true
    }

    func backButtonPressed(_ sender: Any) {
        if let contentViewController = contentViewController as? ViewController {
            contentViewController.goBack()
        }
    }

    func forwardButtonPressed(_ sender: Any) {
        if let contentViewController = contentViewController as? ViewController {
            contentViewController.goForward()
        }
    }

    func goLeftOneTab() {
        if let contentViewController = contentViewController as? ViewController {
            print("Current tab index: \(contentViewController.focusedTab)")
            guard contentViewController.focusedTab - 1 >= 0 else { return }
            print("Going left one tab")
            contentViewController.focusTab(tabIndex: contentViewController.focusedTab - 1)
        }
    }

    func goRightOneTab() {
        if let contentViewController = contentViewController as? ViewController {
            print("Current tab index: \(contentViewController.focusedTab)")
            guard contentViewController.focusedTab + 1 < contentViewController.tabs.count else { return }
            print("Going right one tab")
            contentViewController.focusTab(tabIndex: contentViewController.focusedTab + 1)
        }
    }

    func focusTab(index: Int) {
        if let contentViewController = contentViewController as? ViewController {
            guard index < contentViewController.tabs.count && index >= 0 else { return }
            contentViewController.focusTab(tabIndex: index)
        }
    }

    func loadPage(address: String) {
        if let contentViewController = contentViewController as? ViewController {
            contentViewController.loadPage(address: address)
        }
    }

    var urlBarAddress: String {
        didSet {
            if let contentViewController = contentViewController as? ViewController {
                compactTabsItem?.textField.stringValue = urlBarAddress
                contentViewController.loadPage(address: urlBarAddress)
            }
        }
    }
}

extension MainWindowController: NSWindowDelegate {
    func windowDidResize(_ notification: Notification) {
        // resize the tabs toolbar item

        // get the space before and after the compact tabs item
        // exclude flexible spaces, because they automatically expand

        var space: CGFloat = 120.0
        for item in self.window?.toolbar?.items ?? [] {
            guard item.itemIdentifier != .flexibleSpace && item.itemIdentifier != .compactTabsToolbarItem else { continue }
            space += item.maxSize.width
        }
        compactTabsItem?.frame = NSRect(x: 0, y: 0, width: (window?.frame.width ?? 800) - space, height: 25)
    }
}

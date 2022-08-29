//
//  MainWindowController.swift
//  compactTabs
//
//  Created by TAY KAI QUAN on 25/8/22.
//

// Contains code from: https://github.com/marioaguzman/toolbar/blob/master/Toolbar/Main%20Window/MainWindowController.swift

import Cocoa

let animationDuration = 0.3
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
            viewController.compactTabsItem = compactTabsItem
        }
    }

    override init(window: NSWindow?) {
        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    /// Configure the custom toolbar
    func configToolbar() {
        if  let unwrappedWindow = self.window {
            let toolbar = NSToolbar(identifier: UUID().uuidString)
            toolbar.delegate = self
            toolbar.allowsUserCustomization = false // TODO: Allow customisation of toolbar
            toolbar.autosavesConfiguration = true
            toolbar.displayMode = .default

            // Hiding the title visibility in order to gain more toolbar space.
            unwrappedWindow.titleVisibility = .hidden

            unwrappedWindow.toolbar = toolbar
        }
    }

    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        return true
    }

    // MARK: Toolbar Button Actions
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

    // MARK: Shortcut Detectors
    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command {
            print(event.keyCode)
            if event.keyCode == 13 { // cmd-w
                print("Cmd-w pressed")
                if let contentViewController = contentViewController as? ViewController {
                    contentViewController.closeTab()
                }
            } else if event.keyCode == 3 { // cmd-t
                print("Cmd-t pressed")
                if let contentViewController = contentViewController as? ViewController {
                    contentViewController.createTab()
                }
            }
        }
    }
}

extension MainWindowController: NSWindowDelegate {
    /// Update the compact tabs item based on how much space it can take up in the toolbar.
    func windowDidResize(_ notification: Notification) {
        // resize the tabs toolbar item

        // get the space before and after the compact tabs item
        // exclude flexible spaces, because they automatically expand

        var space: CGFloat = 110.0
        for item in self.window?.toolbar?.items ?? [] {
            guard item.itemIdentifier != .flexibleSpace && item.itemIdentifier != .compactTabsToolbarItem else { continue }
            space += item.maxSize.width
        }
        compactTabsItem?.frame = NSRect(x: 0, y: 0, width: (window?.frame.width ?? 800) - space, height: 25)

        print("Reloading tabs")
        compactTabsItem?.updateTabs()
    }
}

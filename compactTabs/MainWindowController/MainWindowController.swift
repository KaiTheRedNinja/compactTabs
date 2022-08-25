//
//  MainWindowController.swift
//  compactTabs
//
//  Created by TAY KAI QUAN on 25/8/22.
//

// Contains code from: https://github.com/marioaguzman/toolbar/blob/master/Toolbar/Main%20Window/MainWindowController.swift

import Cocoa

class MainWindowController: NSWindowController, NSToolbarItemValidation {

    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.

        configToolbar()
    }

    func configToolbar() {
        if  let unwrappedWindow = self.window {
            let toolbar = NSToolbar(identifier: UUID().uuidString)
            toolbar.delegate = self
            toolbar.allowsUserCustomization = true
            toolbar.autosavesConfiguration = true
            toolbar.displayMode = .default

            // Example on center-pinning a toolbar item
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

    @IBAction func backButtonPressed(_ sender: Any) {
        if let contentViewController = contentViewController as? ViewController {
            contentViewController.goBack()
        }
    }

    @IBAction func forwardButtonPressed(_ sender: Any) {
        if let contentViewController = contentViewController as? ViewController {
            contentViewController.goForward()
        }
    }
}

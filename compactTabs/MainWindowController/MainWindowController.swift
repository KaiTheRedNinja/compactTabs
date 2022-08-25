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
            let newToolbar = NSToolbar(identifier: NSToolbar.Identifier.mainWindowToolbarIdentifier)
            newToolbar.delegate = self
            newToolbar.allowsUserCustomization = true
            newToolbar.autosavesConfiguration = true
            newToolbar.displayMode = .default

            // Example on center-pinning a toolbar item
            newToolbar.centeredItemIdentifier = NSToolbarItem.Identifier.compactTabsToolbarItem

            // Hiding the title visibility in order to gain more toolbar space.
            // Set this property to .visible or delete this line to get it back.
            unwrappedWindow.titleVisibility = .hidden

            unwrappedWindow.toolbar = newToolbar
            unwrappedWindow.toolbar?.validateVisibleItems()
        }
    }

    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        return true
    }
}

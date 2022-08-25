//
//  MainWindowController+NSToolbarDelegate.swift
//  compactTabs
//
//  Created by TAY KAI QUAN on 25/8/22.
//

import Cocoa

extension MainWindowController: NSToolbarDelegate {
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        print("Asked for items (allowed)")
        return [
            .space,
            .flexibleSpace,
            .compactTabsToolbarItem
        ]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        print("Asked for items (default)")
        return [
            .flexibleSpace,
            .compactTabsToolbarItem,
            .flexibleSpace
        ]
    }

    func toolbar(_ toolbar: NSToolbar,
                 itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        print("Item inserted for \(itemIdentifier.rawValue)")
        if itemIdentifier.rawValue == "compactTabsToolbarItem" {
            let toolbarItem = NSToolbarItem(itemIdentifier: .compactTabsToolbarItem)
            toolbarItem.label = "Compact Tabs"
            toolbarItem.view = CompactTabsToolbarView()
            print("Toolbar item provided")
            return toolbarItem
        }
        return nil
    }
}

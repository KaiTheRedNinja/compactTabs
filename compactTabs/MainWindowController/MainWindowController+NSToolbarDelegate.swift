//
//  MainWindowController+NSToolbarDelegate.swift
//  compactTabs
//
//  Created by TAY KAI QUAN on 25/8/22.
//

import AppKit

extension MainWindowController: NSToolbarDelegate {
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [
            .backForwardButtons,
            .flexibleSpace,
            .compactTabsToolbarItem,
            .flexibleSpace
        ]
    }
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [
            .space,
            .flexibleSpace,
            .backForwardButtons,
            .compactTabsToolbarItem
        ]
    }

    func toolbar(_ toolbar: NSToolbar,
                 itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier {
        case .compactTabsToolbarItem:
            let toolbarItem = NSToolbarItem(itemIdentifier: NSToolbarItem.Identifier.compactTabsToolbarItem)
            let view = CompactTabsToolbarView(frame: CGRect(x: 0, y: 0, width: 300, height: 20))
            view.addItems()
            toolbarItem.label = "Compact Tabs"
            view.autoresizingMask = .width

            toolbarItem.view = view
            return toolbarItem
        case .backForwardButtons:
            let toolbarItem = NSToolbarItem(itemIdentifier: NSToolbarItem.Identifier.backForwardButtons)
            let view = NSView()
            toolbarItem.label = "Back/Forward"
            view.frame = CGRect(x: 0, y: 0, width: 50, height: 15)

            let leftButton = NSButton(image: NSImage(named: "chevron.left")!, target: nil, action: #selector(goBack))
            leftButton.isBordered = false
            leftButton.frame = CGRect(x: 0, y: 0, width: view.frame.width/2, height: view.frame.height)
            leftButton.bezelStyle = .regularSquare
            view.addSubview(leftButton)

            let rightButton = NSButton(image: NSImage(named: "chevron.right")!, target: nil, action: #selector(goForward))
            rightButton.isBordered = false
            rightButton.frame = CGRect(x: view.frame.width/2, y: 0, width: view.frame.width/2, height: view.frame.height)
            rightButton.bezelStyle = .regularSquare
            view.addSubview(rightButton)

            toolbarItem.view = view
            return toolbarItem
        default:
            return NSToolbarItem(itemIdentifier: itemIdentifier)
        }
    }

    @objc
    func goBack() {
        if let view = self.contentViewController as? ViewController {
            view.goBack()
        }
    }

    @objc
    func goForward() {
        if let view = self.contentViewController as? ViewController {
            view.goForward()
        }
    }
}

extension NSToolbarItem.Identifier {
    static let backForwardButtons = NSToolbarItem.Identifier("BackForwardButtons")
    static let compactTabsToolbarItem = NSToolbarItem.Identifier("CompactTabsToolbarItem")
}

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
            .extensionToolbarItem,
            .compactTabsToolbarItem,
            .extensionToolbarItem,
            .extensionToolbarItem,
        ]
    }
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [
            .space,
            .flexibleSpace,
            .backForwardButtons,
            .compactTabsToolbarItem,
            .extensionToolbarItem
        ]
    }

    func toolbar(_ toolbar: NSToolbar,
                 itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier {
        case .compactTabsToolbarItem: // the compact tabs toolbar item
            let toolbarItem = NSToolbarItem(itemIdentifier: NSToolbarItem.Identifier.compactTabsToolbarItem)

            // Init the custom view
            let view = CompactTabsToolbarView(frame: CGRect(x: 0, y: 0, width: (window?.frame.width ?? 800) - 100, height: 25))
            view.translatesAutoresizingMaskIntoConstraints = false
            view.autoresizingMask = [.width, .height]
            view.viewController = self.contentViewController as? ViewController
            toolbarItem.label = "Compact Tabs"

            toolbarItem.view = view

            // get a local reference
            self.compactTabsItem = view
            return toolbarItem

        case .backForwardButtons:
            let toolbarItem = NSToolbarItem(itemIdentifier: NSToolbarItem.Identifier.backForwardButtons)
            let view = NSView()
            toolbarItem.label = "Back/Forward"
            view.frame = CGRect(x: 0, y: 0, width: 50, height: 12)

            // init the go back button
            let leftButton = NSButton(image: NSImage(named: "chevron.left")!, target: nil, action: #selector(goBack))
            leftButton.isBordered = false
            leftButton.frame = CGRect(x: 0, y: 0, width: view.frame.width/2, height: view.frame.height)
            leftButton.bezelStyle = .regularSquare
            view.addSubview(leftButton)

            // init the go forward button
            let rightButton = NSButton(image: NSImage(named: "chevron.right")!, target: nil, action: #selector(goForward))
            rightButton.isBordered = false
            rightButton.frame = CGRect(x: view.frame.width/2, y: 0, width: view.frame.width/2, height: view.frame.height)
            rightButton.bezelStyle = .regularSquare
            view.addSubview(rightButton)

            toolbarItem.view = view
            return toolbarItem

        case .extensionToolbarItem:
            let toolbarItem = NSToolbarItem(itemIdentifier: NSToolbarItem.Identifier.extensionToolbarItem)
            toolbarItem.label = "Extension"
            toolbarItem.image = NSImage(named: "extension")
            return toolbarItem

        default:
            return NSToolbarItem(itemIdentifier: itemIdentifier)
        }
    }

    // MARK: Back/Forward Buttons

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
    static let extensionToolbarItem = NSToolbarItem.Identifier("ExtensionToolbarItem")
}

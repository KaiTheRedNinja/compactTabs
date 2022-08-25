//
//  CompactTabsToolbarView.swift
//  compactTabs
//
//  Created by TAY KAI QUAN on 25/8/22.
//

import Cocoa

class CompactTabsToolbarView: NSView {

    var textField: NSTextField

    override init(frame frameRect: NSRect) {
        textField = NSTextField(frame: frameRect)
        super.init(frame: frameRect)
        if let window = self.window?.windowController as? MainWindowController {
            textField.stringValue = window.urlBarAddress
        } else {
            textField.stringValue = "init from frame"
        }
        textField.delegate = self
    }

    required init?(coder: NSCoder) {
        textField = NSTextField()
        super.init(coder: coder)
        textField.frame = frame
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }

    func loadView() {
        addSubview(textField)
    }
}

extension CompactTabsToolbarView: NSTextFieldDelegate {
    func controlTextDidEndEditing(_ obj: Notification) {
        // save the text
        if let controller = self.window?.windowController as? MainWindowController {
            controller.loadPage(address: textField.stringValue)
        }
    }
}

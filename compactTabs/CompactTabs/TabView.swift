//
//  TabView.swift
//  compactTabs
//
//  Created by TAY KAI QUAN on 26/8/22.
//

import Cocoa
import WebKit

class TabView: NSView, Identifiable {

    var id = UUID()

    var favicon: NSImageView
    var textView: NSTextField

    var compactTabsItem: CompactTabsToolbarView?

    override init(frame frameRect: NSRect) {
        textView = NSTextField()
        favicon = NSImageView()
        super.init(frame: frameRect)
        addViews(rect: frameRect)
    }

    required init?(coder: NSCoder) {
        textView = NSTextField()
        favicon = NSImageView()
        super.init(coder: coder)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }

    func addViews(rect: NSRect) {
        wantsLayer = true
//        layer?.backgroundColor = NSColor.gray.cgColor
        layer?.cornerRadius = 4
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.gray.cgColor

        favicon.image = NSImage(named: "unknown")!
        favicon.frame = CGRect(x: 4, y: 4, width: rect.height-8, height: rect.height-8)

        textView.frame = CGRect(x: favicon.frame.maxX + 4, y: rect.minY-5, width: rect.width-favicon.frame.maxX-4, height: rect.height)
        textView.drawsBackground = false
        textView.isBezeled = false
        textView.stringValue = "IDK really"
        textView.cell?.lineBreakMode = .byTruncatingTail
        textView.isEditable = false
        addSubview(textView)
        addSubview(favicon)

        addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(focusTab)))
    }

    @objc func focusTab() {
        print("Focusing")
        compactTabsItem?.focusTab(sender: self)
    }

    func becomeMain() {
        layer?.backgroundColor = NSColor.gray.cgColor
    }

    func resignMain() {
        layer?.backgroundColor = .none
    }

    func updateWith(wkView: WKWebView?) {
        textView.stringValue = wkView?.title ?? (wkView?.url?.relativePath ?? "Unknown")
        favicon = NSImageView(image: NSImage(named: "unknown")!)
    }

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        subviews = []
        if frame.width > 60 {
            favicon.frame = CGRect(x: 4, y: 4, width: frame.height-8, height: frame.height-8)
            textView.isHidden = false
            textView.frame = CGRect(x: favicon.frame.maxX + 4, y: frame.minY-5, width: frame.width-favicon.frame.maxX-4, height: frame.height)
        } else {
            favicon.frame = CGRect(x: 0, y: 4, width: frame.width, height: frame.height-8)
            favicon.imageAlignment = .alignCenter
            textView.isHidden = true
        }
        addSubview(textView)
        addSubview(favicon)
    }
}

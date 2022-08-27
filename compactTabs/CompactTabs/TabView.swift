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

    var favicon: NSButton
    var faviconImage: NSImage
    var textView: NSTextField

    var compactTabsItem: CompactTabsToolbarView?

    static var faviconCache: [URL: NSImage] = [:]
    static let unknownFavicon = NSImage(named: "unknown")!

    override init(frame frameRect: NSRect) {
        textView = NSTextField()
        favicon = NSButton()
        faviconImage = NSImage()
        super.init(frame: frameRect)
        addViews(rect: frameRect)
    }

    required init?(coder: NSCoder) {
        textView = NSTextField()
        favicon = NSButton()
        faviconImage = NSImage()
        super.init(coder: coder)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }

    func addViews(rect: NSRect) {
        self.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(focusTab)))

        wantsLayer = true
//        layer?.backgroundColor = NSColor.gray.cgColor
        layer?.cornerRadius = 4
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.gray.cgColor

        faviconImage = NSImage(named: "unknown")!
        favicon.image = faviconImage
        favicon.isBordered = false
        favicon.bezelStyle = .regularSquare
        favicon.imageScaling = .scaleProportionallyDown
        favicon.frame = CGRect(x: 4, y: 4, width: rect.height-7, height: rect.height-8)
        favicon.target = self
        favicon.action = #selector(closeTab)

        textView.frame = CGRect(x: favicon.frame.maxX + 4, y: rect.minY-3, width: rect.width-favicon.frame.maxX-4, height: rect.height)
        textView.drawsBackground = false
        textView.isBezeled = false
        textView.stringValue = "IDK really"
        textView.cell?.lineBreakMode = .byTruncatingTail
        textView.isEditable = false
        addSubview(textView)
        addSubview(favicon)
    }

    @objc func closeTab() {
        compactTabsItem?.closeTab(sender: self)
    }

    @objc func focusTab() {
        if mouseHovering {
            closeTab()
        } else {
            compactTabsItem?.focusTab(sender: self)
        }
    }

    override func otherMouseDown(with: NSEvent) {
        if NSEvent.pressedMouseButtons == 4 { // middle click
            closeTab()
        }
    }

    func becomeMain() {
        layer?.backgroundColor = NSColor.gray.cgColor
    }

    func resignMain() {
        layer?.backgroundColor = .none
    }

    func updateWith(wkView: WKWebView?, attempt: Double = 0) {
        textView.stringValue = wkView?.title ?? (wkView?.url?.relativePath ?? "Unknown")
        if textView.stringValue == "" {
            textView.stringValue = "Loading"
            // keep on trying to see if the web view has loaded, larger delay between each attempt
            DispatchQueue.main.asyncAfter(deadline: .now() + attempt, execute: {
                self.updateWith(wkView: wkView, attempt: attempt + 1)
            })
        }
        if let url = wkView?.url, let cachedIcon = TabView.faviconCache[url] {
            faviconImage = cachedIcon
            favicon.image = faviconImage
        } else if let wkView = wkView, let url = wkView.url {
            faviconImage = faviconFor(url: url)
            favicon.image = faviconImage
            TabView.faviconCache[url] = favicon.image
        } else {
            favicon.image = TabView.unknownFavicon
        }
    }

    var isResizing = false
    override func resizeSubviews(withOldSize oldSize: NSSize) {
        if frame.width > 60 {
            textView.frame = CGRect(x: favicon.frame.maxX + 4, y: frame.minY-3, width: frame.width-favicon.frame.maxX-4, height: frame.height)

            if oldSize.width >= 60 {
                print("Animating to full")
                // NSView move animation
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.2

                    // Move the favicon to its new position
                    var origin = favicon.frame.origin
                    origin.x -= favicon.frame.minX - 4

                    favicon.animator().frame.origin = origin
                    textView.animator().alphaValue = 1
                }) {
                    print("Finished full")
                    self.favicon.frame = CGRect(x: 4, y: 4, width: self.frame.height-8, height: self.frame.height-8)
                    self.textView.frame = CGRect(x: self.favicon.frame.maxX + 4,
                                                 y: self.frame.minY-3,
                                                 width: self.frame.width-self.favicon.frame.maxX-4,
                                                 height: self.frame.height)
                }
            } else {
                textView.alphaValue = 1
            }
        } else {
            if oldSize.width > 60 {
                // NSView move animation
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.2

                    // Move the favicon to its new position
                    var origin = favicon.frame.origin
                    origin.x += (frame.width - (frame.height-8))/2 - 4

                    favicon.animator().frame.origin = origin
                    textView.animator().alphaValue = 0
                })
            } else {
                favicon.frame = CGRect(x: (frame.width - (frame.height-8))/2, y: 4, width: frame.height-7, height: frame.height-8)
                textView.alphaValue = 0
            }
        }
        updateTrackingAreas()
    }

    // MARK: Mouse hover

    private lazy var area = makeTrackingArea()

    private var mouseHovering = false {
        didSet {
            if mouseHovering {
                favicon.image = NSImage(named: "x")!
            } else {
                favicon.image = faviconImage
            }
        }
    }

    public override func updateTrackingAreas() {
        removeTrackingArea(area)
        area = makeTrackingArea()
        addTrackingArea(area)
    }

    private func makeTrackingArea() -> NSTrackingArea {
        return NSTrackingArea(rect: favicon.frame, options: [.mouseEnteredAndExited, .activeInKeyWindow], owner: self, userInfo: nil)
    }

    public override func mouseEntered(with event: NSEvent) {
        mouseHovering = true
    }

    public override func mouseExited(with event: NSEvent) {
        mouseHovering = false
    }
}

// This avoids the very odd "unknown hint identifier 'kCGImageSourceTypeIdentifierHint:dyn.age8u' -- ignoring..." error
func faviconFor(url: URL?, size: Int = 32) -> NSImage {
    guard let sourceURL = url else { return TabView.unknownFavicon }
    guard let faviconUrl = URL(string: "https://www.google.com/s2/favicons?sz=\(size)&domain=\(sourceURL.debugDescription)")
        else { return TabView.unknownFavicon }
    guard let data = try? Data(contentsOf: faviconUrl) else { return TabView.unknownFavicon }
    guard let image = NSImage(data: data) else { return TabView.unknownFavicon }
    return image
}

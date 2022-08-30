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
    var ascociatedWebPageView: WebPageView?

    var favicon: NSButton
    var faviconImage: NSImage
    var textView: NSTextField

    var willBeDeleted: Bool = false
    var isAnimating: Bool = false

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

    func addViews(rect: NSRect) {
        self.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(focusTab)))

        wantsLayer = true
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

        textView.drawsBackground = false
        textView.isBezeled = false
        textView.stringValue = "IDK really"
        textView.cell?.lineBreakMode = .byTruncatingTail
        textView.isEditable = false
        addSubview(textView)
        addSubview(favicon)

        let zoomRecogniser = NSMagnificationGestureRecognizer(target: self, action: #selector(didZoom(_:)))
        let panRecogniser = NSPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
        addGestureRecognizer(zoomRecogniser)
        addGestureRecognizer(panRecogniser)

        // if the tab is in expanded mode
        if rect.width > 60 {
            favicon.frame = CGRect(x: 4, y: 4, width: rect.height-8, height: rect.height-8)
            textView.frame = CGRect(x: rect.height-2, y: 0,
                                    width: rect.width-rect.height+8-4, height: rect.height-3)
            textView.alphaValue = 1
        // if the tab is in compact mode
        } else {
            favicon.frame = CGRect(x: (rect.width - (rect.height-8))/2, y: 4, width: rect.height-7, height: rect.height-8)
            textView.frame = CGRect(x: rect.height-2, y: 0,
                                    width: rect.width-rect.height+8-4, height: rect.height-3)
            textView.alphaValue = 0
        }
        updateTrackingAreas()
    }

    // MARK: Tab actions
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

    var zoomAmount = 0.0
    @objc func didZoom(_ sender: NSMagnificationGestureRecognizer?) {
        guard let gesture = sender else { return }
        if gesture.state == .ended {
            zoomAmount = 0
            compactTabsItem?.updateTabFrames(animated: true, reposition: false)
        } else {
            zoomAmount = gesture.magnification
            compactTabsItem?.updateTabFrames(animated: false, reposition: false)
        }
    }

    var isPanning = false
    var originalFrame: NSRect = .zero
    var clickPointOffset: CGFloat = 0.0
    @objc func didPan(_ sender: NSPanGestureRecognizer?) {
        guard let gesture = sender else { return }
        let location = gesture.location(in: self.superview)
        if gesture.state == .began {
            isPanning = true
            originalFrame = self.frame
            clickPointOffset = location.x - self.frame.minX
        } else if gesture.state == .ended {
            isPanning = false
        }
        frame = NSRect(x: location.x - clickPointOffset, y: 0, width: frame.width, height: frame.height)
        compactTabsItem?.repositionTabs(movingTab: self, state: gesture.state)
    }

    // detect middle click
    override func otherMouseDown(with: NSEvent) {
        if NSEvent.pressedMouseButtons == 4 { // middle click
            closeTab()
        }
    }

    var isMain = false
    func becomeMain() {
        isMain = true
        layer?.backgroundColor = NSColor.gray.cgColor
    }

    func resignMain() {
        isMain = false
        layer?.backgroundColor = .none
    }

    /// Update the tab view's text and favicon. The favicon is cached to avoid repeated fetching.
    /// - Parameters:
    ///   - webPageView: The ``WebPageView`` to load the title and favicon of
    ///   - attempt: How many attempts have been made before.
    func updateWith(webPageView: WebPageView?, attempt: Double = 0) {
        self.ascociatedWebPageView = webPageView
        let wkView = webPageView?.wkView
        textView.stringValue = wkView?.title ?? (wkView?.url?.relativePath ?? "Unknown")
        if textView.stringValue == "" {
            textView.stringValue = "Loading"
            // keep on trying to see if the web view has loaded, larger delay between each attempt
            DispatchQueue.main.asyncAfter(deadline: .now() + attempt, execute: {
                self.updateWith(webPageView: webPageView, attempt: attempt + 1)
            })
        }

        // Load the favicon from cache, or fetch and cache it if unavailable.
        faviconImage = TabView.unknownFavicon
        favicon.image = faviconImage
        DispatchQueue.main.async {
            if let url = wkView?.url, let cachedIcon = TabView.faviconCache[url] {
                self.faviconImage = cachedIcon
                self.favicon.image = self.faviconImage
            } else if let wkView = wkView, let url = wkView.url {
                self.faviconImage = faviconFor(url: url)
                self.favicon.image = self.faviconImage
                TabView.faviconCache[url] = self.favicon.image
            }
        }
    }

    /// Resize the favicon and title
    /// - Parameter oldSize: The old size of the view
    override func resizeSubviews(withOldSize oldSize: NSSize) {
        guard !willBeDeleted else { return } // don't update if the tab is about to be deleted

        let newTextViewFrame = CGRect(x: frame.height-2, y: 0,
                                      width: frame.width-frame.height+8-4, height: frame.height-3)

        // if the tab is in expanded mode
        if frame.width > 60 {
            // if the frame just only got expanded from compact mode, animate the changes
            if oldSize.width <= 60 {
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = animationDuration

                    // Move the favicon to its new position
                    var origin = favicon.frame.origin
                    origin.x -= favicon.frame.minX - 4

                    favicon.animator().frame.origin = origin
                    textView.animator().frame = newTextViewFrame
                    textView.animator().alphaValue = 1
                }) {
                    // In case the position the favicon should be at has changed, just set it when the animation has ended.
                    if self.frame.width > 60 {
                        self.favicon.frame = CGRect(x: 4, y: 4, width: self.frame.height-8, height: self.frame.height-8)
                    }
                    self.updateTrackingAreas()
                }
            } else { // no animation needed
                textView.alphaValue = 1
                favicon.frame = CGRect(x: 4, y: 4, width: frame.height-8, height: frame.height-8)
                textView.frame = newTextViewFrame
            }

        // if the tab is in compact mode
        } else {
            // if the frame just only got compacted from expanded mode, animate the changes
            if oldSize.width > 60 {
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = animationDuration

                    // Move the favicon to its new position
                    var origin = favicon.frame.origin
                    origin.x += (frame.width - (frame.height-8))/2 - 4

                    favicon.animator().frame.origin = origin
                    textView.animator().alphaValue = 0
                }) {
                    if self.frame.width <= 60 {
                        self.favicon.frame = CGRect(x: (self.frame.width - (self.frame.height-8))/2, y: 4,
                                                    width: self.frame.height-7, height: self.frame.height-8)
                    }
                    self.textView.frame = newTextViewFrame
                    self.updateTrackingAreas()
                }
            } else { // no animation needed
                favicon.frame = CGRect(x: (frame.width - (frame.height-8))/2, y: 4, width: frame.height-7, height: frame.height-8)
                textView.frame = newTextViewFrame
                textView.alphaValue = 0
            }
        }
        updateTrackingAreas()
    }

    // MARK: Mouse hover

    private lazy var area = makeTrackingArea()

    // Used to toggle between the close tab image and the favicon image
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

/// A function to get the favicon for a certain URL and return it as an NSImage. If no favicon could be found, it returns ``TabView.unknownFavicon``.
/// - Parameters:
///   - url: The URL to get the favicon for
///   - size: The size of the favicon in pixels. 32 by default.
/// - Returns: An NSImage containing the favicon
func faviconFor(url: URL?, size: Int = 32) -> NSImage {
    guard let sourceURL = url else { return TabView.unknownFavicon }
    guard let faviconUrl = URL(string: "https://www.google.com/s2/favicons?sz=\(size)&domain=\(sourceURL.debugDescription)")
        else { return TabView.unknownFavicon }
    guard let data = try? Data(contentsOf: faviconUrl) else { return TabView.unknownFavicon }
    guard let image = NSImage(data: data) else { return TabView.unknownFavicon }
    return image
}

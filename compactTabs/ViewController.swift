//
//  ViewController.swift
//  compactTabs
//
//  Created by TAY KAI QUAN on 25/8/22.
//

import Cocoa
import WebKit

class ViewController: NSViewController {

    var tabs: [WebPageView] = []
    var mainWindow: MainWindowController?
    var compactTabsItem: CompactTabsToolbarView?

    override func viewDidLoad() {
        super.viewDidLoad()

        focusTab(tabIndex: 0)

        compactTabsItem?.textField.becomeFirstResponder()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    // MARK: Web View Functions
    func goBack() {
        if let webView = view.subviews[1] as? WebPageView {
            webView.goBack()
        }
    }

    func goForward() {
        if let webView = view.subviews[1] as? WebPageView {
            webView.goForward()
        }
    }

    func reloadTab() {
        if let webView = view.subviews[1] as? WebPageView {
            // because they're reloading, we should probably reload the favicon as well
            if let url = webView.wkView?.url {
                TabView.faviconCache.removeValue(forKey: url)
            }
            webView.refresh()
        }
    }

    // MARK: Tab related functions
    let newTabPage = URL(string: "https://www.kagi.com")!
    func createTab(url: URL? = nil) {
        let url = url ?? newTabPage
        tabs.append(createNewWebView(url: url))
        focusTab(tabIndex: tabs.count-1)
    }

    /// Closes a tab. If supplied with a tab index, it closes that tab. If no tab was specified, the current tab will be closed.
    /// - Parameter tabIndex: The tab to close. If nothing was provided, then the current tab will be closed.
    func closeTab(tabIndex: Int? = nil) {
        let tabIndex = tabIndex ?? focusedTab
        let reposition = tabIndex == focusedTab
        if tabs.count <= 0 {
            // the last tab was just closed, close the window
            self.mainWindow?.close()
        } else {
            tabs.remove(at: tabIndex)
            // close the tab and focus the tab to the right
            if reposition {
                focusTab(tabIndex: tabIndex)
            } else {
                focusTab(tabIndex: tabIndex < focusedTab ? focusedTab-1 : focusedTab)
            }

            if tabs.count == 0 {
                compactTabsItem?.textField.becomeFirstResponder()
            }
        }
    }

    var focusedTab = 0
    /// Helper function to focus a specific tab given its index
    /// - Parameters:
    ///   - tabIndex: The index of the tab to update
    ///   - update: If the tab bar should be updated or not
    func focusTab(tabIndex: Int, update: Bool = true) {
        view.subviews = [view.subviews[0]]
        if tabs.count > 0 {
            let toFocus = tabIndex >= 0 ? (tabIndex < tabs.count ? tabIndex : tabs.count-1) : 0
            tabs[toFocus].frame = view.frame
            view.addSubview(tabs[toFocus])
            focusedTab = toFocus
        }
        if update {
            compactTabsItem?.updateViews(animate: true)
        }
    }

    // MARK: Loading

    /// If a web page has navigated, update the url bar.
    /// Most of the time it'll be a background tab that navigated to a new page, so it also runs
    /// the main window's update view function, which would tell the tab bar to reload.
    /// - Parameters:
    ///   - address: The address that was updated
    ///   - sender: The ``WebPageView`` that triggered the function
    func updateURLBar(toAddress address: String, sender: WebPageView) {
        if tabs[focusedTab] == sender {
            print("Update tab name to \(address)")
            print("Current tab: \(focusedTab)")
        } else {
            print("a background tab navigated to a new page")
        }
        compactTabsItem?.updateTabs()
    }

    /// A function that loads the address as a URL or as a search query depending on if it contains the needed characters.
    /// Note that currently a protocol is required for the regex to identify it as a proper URL.
    /// - Parameter address: The search query or URL.
    func loadPage(address: String) {
        guard !address.isEmpty else { return }
        // NOTE: If you dont include the protocol, the url will be searched instead.
        if let url = URL(string: address), url.debugDescription.range(of: "^.+://",
                                                         options: .regularExpression,
                                                         range: nil, locale: nil) != nil {
            loadWebPage(url: url)
        } else {
            let url = URL(string: "https://www.google.com/search?q=\(address.replacingOccurrences(of: " ", with: "%20"))")!
            loadWebPage(url: url)
        }
    }

    /// This function, if given a web page, will load a URL into that page.
    /// If no page is given, it will load the URL into the frontmost page.
    /// - Parameters:
    ///   - url: The URL to load
    ///   - webView: The web view to load, or the frontmost if left blank.
    private func loadWebPage(url: URL, webView: WebPageView? = nil) {
        if tabs.count <= 0 {
            createTab(url: url)
        } else if let webPageView = webView {
            webPageView.loadPage(address: url.debugDescription)
        } else if let webPageView = view.subviews.first(where: { $0 is WebPageView }) as? WebPageView {
            webPageView.loadPage(address: url.debugDescription)
        }
    }

    /// Helper function to create a new web view and set the frame
    /// - Parameter url: The initial URL of the new ``WebPageView``
    /// - Returns: A new ``WebPageView``
    func createNewWebView(url: URL? = nil) -> WebPageView {
        let webView = WebPageView()
        webView.viewController = self
        webView.frame = CGRect(
            x: 0, y: 0,
            width: view.frame.width,
            height: view.frame.height)
        webView.autoresizingMask = [.height, .width]
        webView.attachViews(address: url?.debugDescription, parentView: self.view)

        return webView
    }
}

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

        tabs = [
            createNewWebView(url: URL(string: "https://www.kagi.com")!),
            createNewWebView(url: URL(string: "https://browser.kagi.com")!),
            createNewWebView(url: URL(string: "https://browserbench.org/Speedometer2.1/")!),
            createNewWebView(url: URL(string: "https://developer.apple.com")!)
        ]

        focusTab(tabIndex: 0)

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func goBack() {
        if let webView = view.subviews.first as? WebPageView {
            webView.goBack()
        }
    }

    func goForward() {
        if let webView = view.subviews.first as? WebPageView {
            webView.goForward()
        }
    }

    func reloadTab() {
        if let webView = view.subviews.first as? WebPageView {
            // because they're reloading, we should probably reload the favicon as well
            if let url = webView.wkView?.url {
                TabView.faviconCache.removeValue(forKey: url)
            }
            webView.refresh()
        }
    }

    let newTabPage = URL(string: "https://www.kagi.com")!
    func createTab() {
        tabs.append(createNewWebView(url: newTabPage))
        compactTabsItem?.updateTabs()
    }

    func closeTab(tabIndex: Int) {
        let reposition = tabIndex == focusedTab
        if tabs.count == 1 {
            print("Last window closed")
            // the last tab was just closed, close the window
            self.mainWindow?.close()
        } else {
            // close the tab and focus the tab to the right
            view.subviews = [] // unfocus the current tab
            tabs.remove(at: tabIndex)
            if reposition {
                print("Repositioning")
                focusTab(tabIndex: tabIndex)
            } else {
                print("Focusing tab \(tabIndex < focusedTab+1 ? focusedTab-1 : focusedTab)")
                print("Tab index is before current: \(tabIndex < focusedTab+1)")
                focusTab(tabIndex: tabIndex < focusedTab ? focusedTab-1 : focusedTab)
            }
        }
        print("Closed tab \(tabIndex). \(tabs.count) left.")
    }

    // helper function to focus a specific tab index
    var focusedTab = 0
    func focusTab(tabIndex: Int, update: Bool = true) {
        let toFocus = tabIndex >= 0 ? (tabIndex < tabs.count ? tabIndex : tabs.count-1) : 0
        tabs[toFocus].frame = view.frame
        view.subviews = [tabs[toFocus]]
        mainWindow?.urlBarAddress = tabs[toFocus].wkView?.url?.debugDescription ?? ""
        focusedTab = toFocus
        if update {
            compactTabsItem?.updateTabs()
        }
    }

    // if a web page has navigated, update the url bar.
    func updateURLBar(toAddress address: String, sender: WebPageView) {
        if tabs[focusedTab] == sender, let window = mainWindow {
            print("Update tab name to \(address)")
            print("Current tab: \(focusedTab)")
            window.urlBarAddress = address
        } else {
            print("a background tab navigated to a new page")
        }
        mainWindow?.resizeWindow()
    }

    func loadPage(address: String) {
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

    private func loadWebPage(url: URL, webView: WebPageView? = nil) {
        if let webPageView = webView {
            webPageView.loadPage(address: url.debugDescription)
        } else if let webPageView = view.subviews.first as? WebPageView {
            webPageView.loadPage(address: url.debugDescription)
        }
    }

    /// Helper function to create a new web view
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

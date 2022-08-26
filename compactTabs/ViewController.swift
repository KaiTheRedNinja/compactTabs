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

    override func viewDidLoad() {
        super.viewDidLoad()

        tabs = [
            createNewWebView(url: URL(string: "https://www.kagi.com")!),
            createNewWebView(url: URL(string: "https://browser.kagi.com")!)
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

    var focusedTab = 0
    func focusTab(tabIndex: Int) {
        guard tabIndex < tabs.count else { return }
        print("Focusing \(focusedTab)")
        view.subviews = [tabs[tabIndex]]
        focusedTab = tabIndex
    }

    func updateURLBar(toAddress address: String, sender: WebPageView) {
        if tabs[focusedTab] == sender, let window = mainWindow {
            print("Update tab name to \(address)")
            window.urlBarAddress = address
        } else {
            print("a background tab navigated to a new page")
        }
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

//
//  ViewController.swift
//  compactTabs
//
//  Created by TAY KAI QUAN on 25/8/22.
//

import Cocoa
import WebKit

class ViewController: NSViewController {

    var tabs: [WKWebView] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        tabs = [
            createNewWebView(url: URL(string: "https://www.kagi.com")!, parentView: self.view),
            createNewWebView(url: URL(string: "https://browser.kagi.com")!, parentView: self.view)
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
        if let webView = view.subviews.first as? WKWebView {
            webView.goBack()
        }
    }

    func goForward() {
        if let webView = view.subviews.first as? WKWebView {
            webView.goForward()
        }
    }

    var focusedTab = 0
    func focusTab(tabIndex: Int) {
        guard tabIndex < tabs.count else { return }
        view.subviews = [tabs[tabIndex]]
        focusedTab = tabIndex
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

    private func loadWebPage(url: URL, webView: WKWebView? = nil) {
        let urlrequest = URLRequest(url: url)
        if let webView = webView {
            webView.load(urlrequest)
        } else if let webView = view.subviews.first as? WKWebView {
            webView.load(urlrequest)
        }
    }

    func createNewWebView(url: URL? = nil, parentView: NSView) -> WKWebView {
        let webView = WKWebView()
        webView.frame = CGRect(
            x: 0, y: 0,
            width: view.frame.width,
            height: view.frame.height)
        webView.autoresizingMask = [.height, .width]

        if let url = url {
            loadWebPage(url: url, webView: webView)
        }

        return webView
    }
}

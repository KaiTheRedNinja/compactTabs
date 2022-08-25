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

    func focusTab(tabIndex: Int) {
        guard tabIndex < tabs.count else { return }
        view.subviews = [tabs[tabIndex]]
    }

    func createNewWebView(url: URL? = nil, parentView: NSView) -> WKWebView {
        let webView = WKWebView()
        webView.frame = CGRect(
            x: 0, y: 0,
            width: view.frame.width,
            height: view.frame.height)
        webView.autoresizingMask = [.height, .width]

        if let url = url {
            print("Loaded url: \(url.debugDescription)")
            let urlrequest = URLRequest(url: url)
            webView.load(urlrequest)
        }

        return webView
    }
}

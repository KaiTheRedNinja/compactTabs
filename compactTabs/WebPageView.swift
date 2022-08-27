//
//  WebPageView.swift
//  compactTabs
//
//  Created by TAY KAI QUAN on 26/8/22.
//

import Cocoa
import WebKit

class WebPageView: NSView {

    var wkView: WKWebView?
    var viewController: ViewController?

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }

    /// Add a web view to the page
    func attachViews(address: String? = nil, parentView: NSView) {
        let wkView = WKWebView()
        // Configure the webView
        wkView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) " +
        "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15"
        wkView.navigationDelegate = self
        wkView.frame = CGRect(
            x: parentView.frame.minX, y: parentView.frame.minY,
            width: parentView.frame.width,
            height: parentView.frame.height)
        wkView.autoresizingMask = [.height, .width]
        self.wkView = wkView
        self.addSubview(wkView)

        if let address = address {
            loadPage(address: address)
        }
    }

    /// Safely load a page. If the url is invalid, treat it as a search query.
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

    private func loadWebPage(url: URL) {
        guard let wkView = wkView else { return }
        if let currentUrl = wkView.url, currentUrl.debugDescription == url.debugDescription { return }
        let urlrequest = URLRequest(url: url)
        wkView.load(urlrequest)
    }

    func goBack() {
        if let webView = wkView {
            webView.goBack()
        }
    }

    func goForward() {
        if let webView = wkView {
            webView.goForward()
        }
    }

    func refresh() {
        if let webView = wkView {
            webView.reload()
        }
    }
}

extension WebPageView: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Web view finished navigation")
        self.viewController?.updateURLBar(toAddress: webView.url?.debugDescription ?? "", sender: self)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Web view failed navigation")
        self.viewController?.updateURLBar(toAddress: webView.url?.debugDescription ?? "", sender: self)
    }
}

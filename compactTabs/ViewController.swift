//
//  ViewController.swift
//  compactTabs
//
//  Created by TAY KAI QUAN on 25/8/22.
//

import Cocoa
import WebKit

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        createNewWebView(url: URL(string: "https://www.kagi.com")!, parentView: self.view)

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func createNewWebView(url: URL? = nil, parentView: NSView) -> WKWebView {
        let webView = WKWebView()
        parentView.addSubview(webView)
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

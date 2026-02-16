//
//  WebViewSwiftController.swift
//  Universal
//
//  Created by Mark on 04/01/2019.
//  Copyright © 2019 Sherdle. All rights reserved.
//

import Foundation
import WebKit
import AMScrollingNavbar

let OFFLINE_FILE_EXTENSION = "html"
let HIDE_SHARE = true
let SWIPE_NAVIGATION = true

class WebViewSwiftController: UIViewController, WKNavigationDelegate, WKUIDelegate, UIScrollViewDelegate  {
    
    @IBOutlet var webView: WKWebView!
    @IBOutlet weak var shareButton: UIBarButtonItem?
    @IBOutlet weak var backButton: UIBarButtonItem?
    @IBOutlet weak var forwardButton: UIBarButtonItem?
    
    var params: [String]!
    var htmlString = ""
    var basicMode = false
    var loadingIndicator: UIActivityIndicatorView?
    @IBOutlet weak var loadingIndicatorContainner: UIView!
    var refreshControl: UIRefreshControl?
    var connectionView: NoConnectionView?
    
    @IBOutlet weak var topMarginConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Note: Jumping in WebView is cause of WKWebView and can potentially be resolved by disabling the dynamically 'hiding navigation'
        
        self.initActivityIndicator()
        
        webView.scrollView.delegate = self
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = SWIPE_NAVIGATION
        webView.allowsLinkPreview = false
        
        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(self.handleRefresh(_:)), for: .valueChanged)
        webView.scrollView.addSubview(refreshControl!) //<- this is point to use. Add "scrollView" property.
        
        if basicMode || AppDelegate.WEBVIEW_HIDE_NAVIGATION {
            navigationItem.rightBarButtonItems = nil
            if basicMode {
                refreshControl!.isEnabled = false
            }
        }
        
        if HIDE_SHARE {
            var toolbarButtons = navigationItem.rightBarButtonItems
            toolbarButtons?.removeAll(where: { element in element == shareButton })
            navigationItem.rightBarButtonItems = toolbarButtons
        }
        
        loadWebViewContent()
        
        //Hiding
        if (AppDelegate.HIDING_NAVIGATIONBAR && !AppDelegate.DISABLED_NAVIGATIONBAR) {
            if let navigationController = navigationController as? ScrollingNavigationController {
                navigationController.followScrollView(webView, delay: 50.0)
            }

            //TODO Still needed?
            topMarginConstraint.isActive = false
        }

    }
    
    fileprivate func initActivityIndicator() {if !(AppDelegate.APP_THEME_LIGHT) {
            loadingIndicator = UIActivityIndicatorView(style: .white)
        } else {
            loadingIndicator = UIActivityIndicatorView(style: .gray)
        }
        loadingIndicator!.startAnimating()
        
        if (AppDelegate.DISABLED_NAVIGATIONBAR) {
            // Configure the background containerView for the indicator
              loadingIndicatorContainner.layer.cornerRadius = 10
            
              // Configure the activity indicator
              self.loadingIndicator!.hidesWhenStopped = true
              self.loadingIndicator!.style = UIActivityIndicatorView.Style.whiteLarge
              loadingIndicatorContainner.addSubview(loadingIndicator!)

              self.loadingIndicator!.translatesAutoresizingMaskIntoConstraints = false
              self.loadingIndicator!.centerXAnchor.constraint(equalTo: loadingIndicatorContainner.centerXAnchor).isActive = true
              self.loadingIndicator!.centerYAnchor.constraint(equalTo: loadingIndicatorContainner.centerYAnchor).isActive = true
        } else {
            navigationItem.titleView = loadingIndicator
        }
        
    }
    
    func hideIndicator() {
        navigationItem.titleView = nil
        loadingIndicatorContainner.isHidden = true;
    }
    
    func showIndicator() {
        if (AppDelegate.DISABLED_NAVIGATIONBAR) {
            loadingIndicatorContainner.isHidden = false;
        } else {
            navigationItem.titleView = loadingIndicator
        }
    }
      
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
       scrollView.pinchGestureRecognizer?.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if let navigationController = navigationController as? ScrollingNavigationController, AppDelegate.HIDING_NAVIGATIONBAR && !AppDelegate.DISABLED_NAVIGATIONBAR {
            navigationController.stopFollowingScrollView()
        }
    }
    
    func loadWebViewContent() {
        //Set all the data
        //If the url begins with http (or https for that matter), load it as a webpage. Otherwise, load an asset
        let baseUrl = params![0]
        if (htmlString.count > 0) {
            webView.loadHTMLString(htmlString, baseURL: URL(string: baseUrl))
        } else {
            var url: URL?
            var urlString: String
            
            //If a string does not start with http, does end with .html and does not contain any slashes, we'll assume it's a local page.
            if !baseUrl.starts(with: "http") && (baseUrl).contains(".\(OFFLINE_FILE_EXTENSION)") && !(baseUrl).contains("/") {
                urlString = (baseUrl).replacingOccurrences(of: ".\(OFFLINE_FILE_EXTENSION)", with: "")
                url = URL(fileURLWithPath: Bundle.main.path(forResource: urlString, ofType: OFFLINE_FILE_EXTENSION, inDirectory: "Local") ?? "")
            } else {
                urlString = baseUrl
                
                url = URL(string: urlString)
            }
            
            if let url = url {
                webView.load(URLRequest(url: url))
            }
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let app = UIApplication.shared
        let url: URL? = navigationAction.request.url
        
        if url?.absoluteString.contains("https://disqus.com/next/login-success/") ?? false {
            loadWebViewContent()
            decisionHandler(WKNavigationActionPolicy.cancel)
            return
        }
        
        if AppDelegate.openTargetBlankSafari {
            if navigationAction.targetFrame == nil {
                if let url = url {
                    if app.canOpenURL(url) {
                        AppDelegate.openInBrowser(url: url.absoluteString, withNavigationController: self.navigationController)
                        decisionHandler(WKNavigationActionPolicy.cancel)
                        return
                    }
                }
            }
        }
        
        if (url?.absoluteString.starts(with: "file:") ?? false) {
            decisionHandler(WKNavigationActionPolicy.allow)
            return
        }
        
        
        if (!(url?.scheme?.isEqual("http") ?? false) && !(url?.scheme?.isEqual("https") ?? false)) || AppDelegate.OPEN_BROWSER.contains(where: url!.absoluteString.contains) {
            if let url = url {
                if app.canOpenURL(url) {
                    AppDelegate.openInBrowser(url: url.absoluteString, withNavigationController: self.navigationController)
                    decisionHandler(WKNavigationActionPolicy.cancel)
                    return
                }
            }
        }
        
        decisionHandler(WKNavigationActionPolicy.allow)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {

        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            completionHandler()
        }))

        present(alertController, animated: true, completion: nil)
    }


    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (Bool) -> Void) {

        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)

        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            completionHandler(true)
        }))

        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            completionHandler(false)
        }))

        present(alertController, animated: true, completion: nil)
    }


    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (String?) -> Void) {

        let alertController = UIAlertController(title: nil, message: prompt, preferredStyle: .actionSheet)

        alertController.addTextField { (textField) in
            textField.text = defaultText
        }

        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            if let text = alertController.textFields?.first?.text {
                completionHandler(text)
            } else {
                completionHandler(defaultText)
            }
        }))

        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            completionHandler(nil)
        }))

        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func goForward(_ sender: Any?) {
        webView.goForward()
    }
    
    @IBAction func goBack(_ sender: Any?) {
        webView.goBack()
    }
    
    @IBAction func share(_ sender: Any) {
        let activityItems = [webView.url!.absoluteString]
        //TODO only usage of presentActions. Replace this with something else and then remove Objc Library
        //presentActions(activityItems, sender: sender)
        
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        if let wPPC = activityVC.popoverPresentationController {
            wPPC.barButtonItem = navigationItem.rightBarButtonItems![0]
        }
        
        self.present(activityVC, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        URLCache.shared.removeAllCachedResponses()
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if !(refreshControl!.isRefreshing) {
            showIndicator()
        }
        
        if AppDelegate.INTERSTITIALS_FOR_WEBVIEW && webView.canGoBack {
            (UIApplication.shared.delegate as! AppDelegate).showInterstitial(controller: self)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        hideIndicator()
        
        if refreshControl != nil && refreshControl!.isRefreshing {
            refreshControl!.endRefreshing()
        }
        
        // Enable or disable back button
        backButton?.isEnabled = webView.canGoBack
        
        // Enable or disable forward button
        forwardButton?.isEnabled = webView.canGoForward
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame?.isMainFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code != NSURLErrorNotConnectedToInternet && (error as NSError).code != NSURLErrorNetworkConnectionLost {
            if !Reachability.connected() {
                update(forConnectivity: false)
            }
            //If the error is not a connection error, show a dialog
            //let alertController = UIAlertController(title: NSLocalizedString("error", comment: ""), message: NSLocalizedString("error_webview", comment: ""), preferredStyle: .alert)
            
            //let ok = UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: nil)
            //alertController.addAction(ok)
            //present(alertController, animated: true)
            let error = String(format: "%@ code: %@", NSLocalizedString("error_webview", comment: ""), error.localizedDescription)
            print(error)
        } else {
            //If the error is a connection error, and this is the page the user is now interacting with. Show a no connectivity warning.
            update(forConnectivity: false)
        }
        
        self.webView(webView, didFinish: navigation)
        
    }
    
    func load(_ request: URLRequest) {
        if webView.isLoading {
            webView.stopLoading()
        }
        webView.load(request)
    }
    
    func viewWillDisappear() {
        if webView.isLoading {
            webView.stopLoading()
        }
    }
    
    //Selectors cannot pass parameters, therefore we offer this utility method
    @objc func updateForConnectivityFromScreen() {
        update(forConnectivity: true)
    }
    
    func update(forConnectivity calledFromButton: Bool) {
        
        if !Reachability.connected() {
            //If the no connection view is not already displayed
            if !(connectionView?.superview != nil) {
                connectionView = Bundle.main.loadNibNamed("NoConnectionView", owner: self, options: nil)?.last as? NoConnectionView
                connectionView!.frame = view.frame
                //_connectionView.label.text = @"Error";
                connectionView!.retryButton.addTarget(self, action: #selector(self.updateForConnectivityFromScreen), for: .touchUpInside)
                
                view.addSubview(connectionView!)
                view.bringSubviewToFront(connectionView!)
            }
        } else {
            //If the view is shown, remove it.
            if (connectionView?.superview != nil) {
                connectionView!.removeFromSuperview()
                connectionView = nil
            }
            if webView.url != nil {
                webView.reload()
            } else {
                loadWebViewContent()
            }
        }
        
    }
    
    @objc func handleRefresh(_ refresh: UIRefreshControl?) {
        // Reload my data
        webView.reload()
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}

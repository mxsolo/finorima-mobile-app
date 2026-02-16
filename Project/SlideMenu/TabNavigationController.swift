//
//  TabNavigationController.swift
//  Universal
//
//  Created by Mark on 19/09/2019.
//  Copyright © 2019 Sherdle. All rights reserved.
//

import Foundation
import AMScrollingNavbar

class TabNavigationController : ScrollingNavigationController {
    private var prevShadowColor: UIColor?
    
    private var statusBarBackgroundView: UIView?
    
    //TODO When swiping back from a detailView (i.e. a wordpress post) to the main view (with big titl) but then cancelling the swipe action, the navigationbar is misformed.
    
    @IBOutlet private var gradientView: NavbarGradientView!
    
    var item: [AnyHashable] = []
    var hiddenTabBar = false
    var menuButton: UIButton?
    
    let NAVBAR_TRANSITION_BGCOLOR = UIColor.white
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.prevShadowColor = self.revealViewController()?.frontViewShadowColor
        
        self.configureNavbar()
    }
    
    func configureNavbar() {
        configureNavigationBar(transparent: false, forceDark: false)
        self.navigationBar.prefersLargeTitles = false
        self.navigationBar.shadowImage = UIImage()
        
        updateNavigationBarVisibilityIfNeeded(hidden: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // gradient view to cover both status bar (if present) and nav bar
        //CGRect barFrame = self.navigationBar.frame;
        //_gradientView.frame = CGRectMake(0, 0, barFrame.size.width, barFrame.origin.y + barFrame.size.height);
    }
    
    override func pushViewController(_ viewController:UIViewController, animated:Bool) {
        super.pushViewController(viewController, animated:animated)
        
        (UIApplication.shared.delegate as! AppDelegate).showInterstitial(controller: self)

        updateNavigationBarVisibilityIfNeeded(hidden: false)
    }
    
    func configureViewController(viewController:UIViewController){
        if let config = Config.config as [Section]? {
            let hasOneItem = config.count == 1 && config[0].items.count == 1
            
            // add reveal button to the first nav item on the stack
            if self.viewControllers.count == 1 && !hasOneItem {
                let leftBarButton:UIBarButtonItem! = UIBarButtonItem(image:UIImage(named: "menu"),  style:UIBarButtonItem.Style.plain, target:self, action:#selector(menuClicked))
                viewController.navigationItem.leftBarButtonItem = leftBarButton
            }
            
            if self.viewControllers.count > 1 {
                self.revealViewController().frontViewShadowColor = NAVBAR_TRANSITION_BGCOLOR
            }
            
        }
    }
        
    @objc func menuClicked() {
        self.revealViewController().revealToggle(animated: true)
    }
    
    override func popViewController(animated:Bool) -> UIViewController? {
        let poppedVC:UIViewController! = super.popViewController(animated: animated)
        
        (UIApplication.shared.delegate as! AppDelegate).showInterstitial(controller: self)
        
        // switch off navbar transparency
        if self.viewControllers.count <= 1 {
            self.enableTransparencyFunctions(enable: false)
            self.revealViewController().frontViewShadowColor = prevShadowColor
        }
        
        updateNavigationBarVisibilityIfNeeded(hidden: true)
        
        return poppedVC
    }
    
    func configureNavigationBar(transparent: Bool, forceDark: Bool) {
        let dark = !AppDelegate.APP_THEME_LIGHT || forceDark;
        
        var tintColor: UIColor
        let backgroundColor = AppDelegate.APP_THEME_LIGHT ? UIColor.white : AppDelegate.APP_THEME_COLOR;
                
        if (dark) {
            tintColor = UIColor.white;
            self.navigationBar.barStyle = UIBarStyle.black
            self.setStatusBar(style: .lightContent)
        } else {
            tintColor = UIColor.black
            self.navigationBar.barStyle = UIBarStyle.default
            setStatusBar(style: .default)
        }
        
        self.navigationBar.tintColor = tintColor
        self.navigationBar.barTintColor = backgroundColor
        
        if #available(iOS 13.0, *) {
            let app = UINavigationBarAppearance()
            if (transparent) {
                app.configureWithTransparentBackground()
            } else {
                app.configureWithOpaqueBackground()
                app.backgroundColor = backgroundColor
            }
            app.titleTextAttributes = [.foregroundColor: tintColor]
            app.largeTitleTextAttributes = [.foregroundColor: tintColor]
            
            if (!AppDelegate.APP_BAR_SHADOW) {
                app.shadowColor = .clear
                app.shadowImage = UIImage()
            }
            
            self.navigationBar.scrollEdgeAppearance = app
            self.navigationBar.compactAppearance = app
            self.navigationBar.standardAppearance = app

        } else {
            // Fallback on earlier versions
            
            self.navigationBar.titleTextAttributes = [.foregroundColor: tintColor];
            
            if (transparent) {
                self.navigationBar.backgroundColor = UIColor.clear
                self.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
                self.navigationBar.isTranslucent = true
            } else {
                self.navigationBar.backgroundColor = backgroundColor
                self.navigationBar.isTranslucent = false
                self.navigationBar.setBackgroundImage(nil, for: UIBarMetrics.default)
            }
        }
    
    }

    
    func updateNavigationBarVisibilityIfNeeded(hidden: Bool){

        if (AppDelegate.DISABLED_NAVIGATIONBAR) {
            self.setNavigationBarHidden(hidden, animated: false)
            self.navigationController?.isNavigationBarHidden = hidden
            gradientView.isHidden = hidden
            setNeedsStatusBarAppearanceUpdate()
            
            if (hidden) {
                if (statusBarBackgroundView == nil) {
                    let statusBarFrame = getStatusBarFrame()
                            
                    statusBarBackgroundView = UIView(frame: statusBarFrame)
                    let statusBarColor = AppDelegate.APP_THEME_LIGHT ? UIColor.white : AppDelegate.APP_THEME_COLOR;
                    statusBarBackgroundView!.backgroundColor = statusBarColor
                    statusBarBackgroundView!.translatesAutoresizingMaskIntoConstraints = false
                    statusBarBackgroundView!.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]

                    view.addSubview(statusBarBackgroundView!)
                }
            } else if let statusBarView = statusBarBackgroundView {
                statusBarView.removeFromSuperview()
                statusBarBackgroundView = nil
            }
        }
    }
    
    
    /**
     * Update the statusbar appearance to use the light theme or default theme as defined in AppDelegate
     * Boolean 'force' can be used to override the theme set for a dark theme (i.e. for detailview fade header).
     */
    @objc func forceDarkNavigation(force: Bool) {
        self.configureNavigationBar(transparent: true, forceDark: force)
    }
    
    //---- Utility methods for managing statusbar style
    
    private var statusBarStyle:UIStatusBarStyle! = .default
    private var prefersHiddenStatusbar = false;
    
    func setStatusBar(style: UIStatusBarStyle!){
        statusBarStyle = style
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return statusBarStyle
    }
    
    func setStatusBar(hidden: Bool){
        prefersHiddenStatusbar = hidden
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var prefersStatusBarHidden: Bool {
      return prefersHiddenStatusbar
    }
    
    //---- Utility methods for managing navigationbar transparency
    
    func getNavigationBarHeight() -> CGFloat {
        return getStatusBarFrame().height + self.navigationBar.frame.height;
    }
    
    func getStatusBarFrame() -> CGRect {
        if #available(iOS 13.0, *) {
            var statusBarView: UIView? {
                let tag = 38482
                let keyWindow = UIApplication.shared.windows.first
                if let statusBar = keyWindow?.viewWithTag(tag) {
                    return statusBar
                } else {
                    guard let statusBarFrame = keyWindow?.windowScene?.statusBarManager?.statusBarFrame else {
                        return nil
                    }
                    let statusBarView = UIView(frame: statusBarFrame)
                    statusBarView.tag = tag
                    keyWindow?.addSubview(statusBarView)
                    return statusBarView
                }
            }
            
            return statusBarView?.frame ?? CGRect.zero;
        } else {
            return UIApplication.shared.statusBarFrame
        }
    }
    /**
      * IBOutlet to gradientView is for some reason lost. This method is used instead to obtain the gradientView.
      **/
     @objc func getGradientView() -> NavbarGradientView {
         return (self.navigationBar as! CustomNavigationBar).backgroundView as! NavbarGradientView
     }
    
    func enableTransparencyFunctions(enable: Bool){
        if (enable) {
            //TODO This is irriversible, after doing this we can no longer hide the navbar for some reason (test)
            self.view.insertSubview(gradientView, belowSubview:self.navigationBar)
            (self.navigationBar as! CustomNavigationBar).backgroundView = gradientView
            UIView.animate(withDuration: TimeInterval.init(0.5), animations: {
                //self.configureNavigationBar(transparent: true, forceDark: false)

            })
        } else {
            gradientView.removeFromSuperview();
            (self.navigationBar as! CustomNavigationBar).backgroundView = nil;
            UIView.animate(withDuration: TimeInterval.init(0.5), animations: {
                self.configureNavigationBar(transparent: false, forceDark: false)
            })
            
        }
    }
    
     @objc func turnTransparency(on: Bool, animated: Bool){
         if (((self.navigationBar as! CustomNavigationBar).backgroundView == nil) && on) {
            enableTransparencyFunctions(enable: true)
         }
        
        if ((self.navigationBar as! CustomNavigationBar).backgroundView != nil) {
            self.getGradientView().turnTransparency(on: on, animated: animated, tabController: self)
            self.configureNavigationBar(transparent: on, forceDark: on)
        }
     
     }
}

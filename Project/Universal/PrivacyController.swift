//
//  File.swift
//  Universal
//
//  Created by Mark on 19/07/2020.
//  Copyright © 2020 Sherdle. All rights reserved.
//

import Foundation

class PrivacyController: UIViewController {
    
    @IBOutlet weak var privacyButton: UIButton!
    @IBOutlet weak var agreeButton: UIButton!
    
    @IBAction func privacyClicked(_ sender: Any) {
        AppDelegate.openUrl(url: AppDelegate.PRIVACY_POLICY_URL, withNavigationController: nil)
    }
    
    @IBAction func agreeClicked(_ sender: Any) {
        self.dismiss(animated: true) {
            let defaults = UserDefaults.standard
            defaults.set("Yes", forKey:"hasAgreed")
        }
    }
    
    static func shouldShow() -> Bool {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "hasAgreed") == nil {
            return true;
        }
        return false;
    }
}

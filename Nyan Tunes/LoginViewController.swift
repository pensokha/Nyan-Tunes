//
//  ViewController.swift
//  Nyan Tunes
//
//  Created by Pushkar Sharma on 25/09/2016.
//  Copyright © 2016 thePsguy. All rights reserved.
//

import UIKit
import CoreData
import VK_ios_sdk

class LoginViewController: UIViewController {
    
    let vkManager: VKClient = {
        return VKClient.sharedInstance
    }()
    
    let SCOPE = VKClient.Constants.SCOPE
    
    @IBOutlet weak var loginButton: UIButton!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var activityLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let SDKvk = VKSdk.initialize(withAppId: VKClient.Constants.appID)!
        SDKvk.uiDelegate = self
        SDKvk.register(self)
        loginButton.layer.cornerRadius = 2.4
        loginButton.clipsToBounds = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        checkSession()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func checkSession(){
        activityLabel.text = "Checking existing session"
        activityIndicator.startAnimating()
        activityLabel.isHidden = false
        vkManager.sessionExistsWith(SCOPE, completion: {exists in
            if exists {
                print("Existing Session")
                self.activityLabel.text = "Existing Session Found"
                self.activityIndicator.stopAnimating()
                self.didLogin()
            }else{
                self.activityIndicator.stopAnimating()
                self.activityLabel.text = "Please Login Below."
            }
        })
    }

    @IBAction func doLogin(_ sender: AnyObject?) {
        vkManager.authorize(SCOPE)
    }
    
    func didLogin(){
        performSegue(withIdentifier: "login", sender: nil)
    }
}

extension LoginViewController: VKSdkDelegate, VKSdkUIDelegate {
    
    func vkSdkAccessAuthorizationFinished(with result: VKAuthorizationResult!) {
        if ((result.token) != nil) {
//            UserDefaults.standard.set(result.token, forKey: VKClient.Constants.VK_ACCESS_TOKEN_DEFAULTS_KEY)
            print("authed")
//            UserDefaults.setValue(result.token.accessToken, forKey: "vkToken")
        } else if ((result.error) != nil) {
            print(result.error)
        }
    }
    
    func vkSdkAuthorizationStateUpdated(with result: VKAuthorizationResult!) {
        print("AUTH STATE UPDATED TO ", result.state.rawValue)
        if result.state == .authorized {
            didLogin()
        }
    }

    func vkSdkTokenHasExpired(_ expiredToken: VKAccessToken!) {
        print("TOKEN EXPIRED")
    }
    
    func vkSdkAccessTokenUpdated(_ newToken: VKAccessToken!, oldToken: VKAccessToken!) {
//        let token: String? = newToken?.accessToken
//        let old: String? = oldToken?.accessToken
//        print("TOKEN UPDATED TO", token, "FROM", old)
    }
    
    func vkSdkUserAuthorizationFailed() {   //Required Delegate Method
        showAlert(text: "Authorization Falied")
    }
    
    func vkSdkShouldPresent(_ controller: UIViewController!) {
        self.show(controller, sender: nil)
    }
    
    func vkSdkNeedCaptchaEnter(_ captchaError: VKError!) {
        let vc = VKCaptchaViewController.captchaControllerWithError(captchaError)
        vc?.present(in: self)
        print(captchaError.description)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "continueOffline" {
            let dest = segue.destination as! UINavigationController
            let target = dest.topViewController as! MyMusicViewController
            target.offlineMode = true
        }
    }

}

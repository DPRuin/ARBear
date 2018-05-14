//
//  AppDelegate+Weibo.swift
//  ARBear
//
//  Created by mac126 on 2018/5/10.
//  Copyright © 2018年 mac126. All rights reserved.
//

import UIKit

let WeiboKey = "466233728"
var wbtoken = ""
var wbRefreshToken = ""
var wbCurrentUserID = ""

extension AppDelegate: WeiboSDKDelegate {
    
    func weiboRegister() {
        WeiboSDK.enableDebugMode(true)
        WeiboSDK.registerApp(WeiboKey)
    }
    
    func weiboHandleOpen(_ url: URL) -> Bool {
        return WeiboSDK.handleOpen(url, delegate: self)
    }
    
    // MARK: WeiboSDKDelegate
    func didReceiveWeiboRequest(_ request: WBBaseRequest!) {
        if request.isKind(of: WBProvideMessageForWeiboRequest.self) {
            
        }
    }
    
    func didReceiveWeiboResponse(_ response: WBBaseResponse!) {
        if response.isKind(of: WBProvideMessageForWeiboResponse.self) { // 发送结果
            
        } else if response.isKind(of: WBAuthorizeResponse.self) { // 认证结果
            let myResponse = response as! WBAuthorizeResponse
            wbtoken = myResponse.accessToken
            wbCurrentUserID = myResponse.userID
            wbRefreshToken = myResponse.refreshToken
            
        }
    }
    
    // MARK: 友盟分享
    /// 设置友盟分享
    func umConfigure() {
        UMSocialManager.default().umSocialAppkey = "59892ebcaed179694b000104"
        // 微信
        UMSocialManager.default().setPlaform(UMSocialPlatformType.wechatSession, appKey: "wxdc1e388c3822c80b", appSecret: "3baf1193c85774b3fd9d18447d76cab0", redirectURL: nil)
        UMSocialManager.default().setPlaform(UMSocialPlatformType.wechatTimeLine, appKey: "wxdc1e388c3822c80b", appSecret: "3baf1193c85774b3fd9d18447d76cab0", redirectURL: nil)
        // 新浪
        UMSocialManager.default().setPlaform(UMSocialPlatformType.sina, appKey: "466233728", appSecret: "edaea9135e80ffa23c922486a87a4138", redirectURL: "https://www.sina.com")
    }
    
    
    
    
}

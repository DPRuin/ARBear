//
//  AppDelegate+Weibo.swift
//  ARBear
//
//  Created by mac126 on 2018/5/10.
//  Copyright © 2018年 mac126. All rights reserved.
//

import UIKit

let WeiboKey = "2045436852"
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
    
    
}

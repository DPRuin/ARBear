//
//  ARViewController+Share.swift
//  ARBear
//
//  Created by mac126 on 2018/5/10.
//  Copyright © 2018年 mac126. All rights reserved.
//

import UIKit

extension ARViewController: WBMediaTransferProtocol {

    // 视频压缩
    
    // MARK: 微博分享
    
    
    /// 分享微博视频
    func shareWeiboMessage() {
        
        let authRequest = WBAuthorizeRequest.request() as! WBAuthorizeRequest
        authRequest.redirectURI = "https://www.sina.com"
        authRequest.scope = "all"
        let request = WBSendMessageToWeiboRequest.request(withMessage: messageObject, authInfo: authRequest, access_token: wbtoken) as! WBSendMessageToWeiboRequest
        
        WeiboSDK.send(request)
        
    }
    
    func weiboImageMessage(images: [UIImage]) -> WBMessageObject {
        
        let message = WBMessageObject.message() as! WBMessageObject
        
        let imageObject = WBImageObject.object() as! WBImageObject
        imageObject.isShareToStory = false
        imageObject.delegate = self
        imageObject.add(images)
        
        message.imageObject = imageObject
        
        return message
    }
    
    func weiboVideoMessage(videoUrl: URL) -> WBMessageObject {
        let message = WBMessageObject.message() as! WBMessageObject
        
        let videoObject = WBNewVideoObject.object() as! WBNewVideoObject
        videoObject.isShareToStory = false
        videoObject.delegate = self
        videoObject.addVideo(videoUrl)
        message.videoObject = videoObject
        
        return message
    }
    
    // MARK: WBMediaTransferProtocol
    func wbsdk_TransferDidReceive(_ object: Any!) {
        // 指示器停止动画
        
        // 启动微博分享
        self.shareWeiboMessage()
        
    }
    
    func wbsdk_TransferDidFailWith(_ errorCode: WBSDKMediaTransferErrorCode, andError error: Error!) {
        // 指示器停止动画
    }
    
}


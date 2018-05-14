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

extension ARViewController: UMSocialShareMenuViewDelegate {
    // MARK: - 友盟分享
    func showUM() {
        // UMSocialUIManager.addCustomPlatformWithoutFilted(UMSocialPlatformType.userDefine_Begin, withPlatformIcon: UIImage(named: "icon_circle"), withPlatformName: "演示icon")
        UMSocialShareUIConfig.shareInstance().sharePageGroupViewConfig.sharePageGroupViewPostionType = UMSocialSharePageGroupViewPositionType.bottom
        UMSocialShareUIConfig.shareInstance().sharePageScrollViewConfig.shareScrollViewPageItemStyleType = UMSocialPlatformItemViewBackgroudType.none
        
        UMSocialUIManager.showShareMenuViewInWindow { (platformType, userInfo) in
            if platformType.rawValue == UMSocialPlatformType.userDefine_Begin.rawValue + 2 {
                DispatchQueue.main.async {
                    print("-alert-show-")
                }
            } else {
                // 分享图片或视频链接
                print("-share-")
                
                self.shareUMMessage(platformType: platformType)
            }
        }
    }
    
    /// 分享友盟消息
    private func shareUMMessage(platformType: UMSocialPlatformType) {
        
        switch platformType {
        case .wechatSession, .wechatTimeLine, .wechatFavorite:
            if ummessageObject is URL {
                print("-video-")
                let url = ummessageObject as! URL
                // TODO: 暂时的视频url
                let urlString = "http://video.sina.com.cn/p/sports/cba/v/2013-10-22/144463050817.html"
                shareVideo(toPlatformType: platformType, withVideoUrl: urlString)
                
            } else if ummessageObject is UIImage {
                let image = ummessageObject as! UIImage
                shareImage(toPlatformType: platformType, withThumb: nil, image: image)
            }
            
        case .sina:
            
            if ummessageObject is URL {
                let url = ummessageObject as! URL
                messageObject = weiboVideoMessage(videoUrl: url)
            } else if ummessageObject is UIImage {
                let image = ummessageObject as! UIImage
                messageObject = weiboImageMessage(images: [image])
            }
            
            break
            
        default:
            break
        }
    }
    
    /// 友盟分享图片
    ///
    /// - Parameters:
    ///   - platformType: 平台
    ///   - thumb: 缩略图
    ///   - image: 分享的图片
    private func shareImage(toPlatformType platformType: UMSocialPlatformType, withThumb thumb: UIImage?, image: UIImage) {
        
        //创建分享消息对象
        let messageObject = UMSocialMessageObject()
        
        //创建图片内容对象
        let shareObject = UMShareImageObject()
        //如果有缩略图，则设置缩略图本地
        if let thumb = thumb {
            shareObject.thumbImage = thumb
        }
        shareObject.shareImage = image
        
        //分享消息对象设置分享内容对象
        messageObject.shareObject = shareObject
        //调用分享接口
        UMSocialManager.default().share(to: platformType, messageObject: messageObject, currentViewController: self) { (shareResponse, error) in
            if let error = error {
                print("Share fail with error--\(error)")
            } else {
                print("response--\(shareResponse)")
                
                
            }
            // 提示是否成功
            
        }
        
    }
    
    /// 友盟分享视频链接
    ///
    /// - Parameters:
    ///   - platformType: 平台
    ///   - url: 视频链接
    private func shareVideo(toPlatformType platformType: UMSocialPlatformType, withVideoUrl url: String) {
        
        //创建分享消息对象
        let messageObject = UMSocialMessageObject()
        
        //创建video内容对象
        let thumImageUrl = "https://mobile.umeng.com/images/pic/home/social/img-1.png"
        let shareObject = UMShareVideoObject.shareObject(withTitle: "ARBear增强现实", descr: "ARBear增强现实哈哈哈哈哈", thumImage: thumImageUrl)
        shareObject?.videoUrl = url
        
        //分享消息对象设置分享内容对象
        messageObject.shareObject = shareObject
        //调用分享接口
        UMSocialManager.default().share(to: platformType, messageObject: messageObject, currentViewController: self) { (shareResponse, error) in
            if let error = error {
                print("Share fail with error--\(error)")
            } else {
                print("response--\(shareResponse)")
                
                
            }
            // 提示是否成功
        }
        
    }
    
    /// 设置要显示平台
    func setPreDefinePlatforms() {
        
        UMSocialUIManager.setPreDefinePlatforms([
            NSNumber(integerLiteral: UMSocialPlatformType.wechatTimeLine.rawValue),
            NSNumber(integerLiteral: UMSocialPlatformType.wechatSession.rawValue),
            NSNumber(integerLiteral: UMSocialPlatformType.wechatFavorite.rawValue),
            NSNumber(integerLiteral: UMSocialPlatformType.sina.rawValue)
            ])
        UMSocialUIManager.setShareMenuViewDelegate(self)
        
    }
    
    // MARK: - UMSocialShareMenuViewDelegate
    func umSocialShareMenuViewDidAppear() {
        print("--umSocialShareMenuViewDidAppear")
    }
    func umSocialShareMenuViewDidDisappear() {
        print("--umSocialShareMenuViewDidDisappear")
    }
    
}


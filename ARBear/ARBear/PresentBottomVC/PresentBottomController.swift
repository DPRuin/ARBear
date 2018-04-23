//
//  PresentBottomController.swift
//  PresentBottomVC
//
//  Created by HongXiangWen on 2018/3/9.
//  Copyright © 2018年 WHX. All rights reserved.
//

import UIKit

// MARK: - UIPresentationController子类，重写present相关属性和方法
class PresentBottomController: UIPresentationController {

    /// 动画的主要参数
    private var animateHeight: CGFloat = 0.0
    private var animateTime: CGFloat = 0.25
    
    /// pan的起始Y值
    private var canPanDown: Bool = false
    private var panStartY: CGFloat = 0
    
    public override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        if let viewController = presentedViewController as? PresentBottomType {
            animateHeight = viewController.contentHeight
            canPanDown = viewController.canPanDown
        } else {
            animateHeight = UIScreen.main.bounds.width
        }
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }
    
    /// 已经弹出视图
    public override func presentationTransitionDidEnd(_ completed: Bool) {
        if canPanDown {
            let panGuesture = UIPanGestureRecognizer(target: self, action: #selector(panGuestureAction(panGuesture:)))
            presentedViewController.view.addGestureRecognizer(panGuesture)
        }
    }
    
    /// 内容视图的frame
    public override var frameOfPresentedViewInContainerView: CGRect {
        return CGRect(x: 0, y: UIScreen.main.bounds.height - animateHeight, width: UIScreen.main.bounds.width, height: animateHeight)
    }
    
    ///  点击背景按钮收起
    @objc private func backgroundBtnClicked() {
        presentedViewController.dismiss(animated: true, completion: nil)
    }
    
    /// 处理pan手势
    @objc func panGuestureAction(panGuesture: UIPanGestureRecognizer) {
        let offsetY = panGuesture.translation(in: presentedView).y
        if panGuesture.state == .began {
            panStartY = offsetY
        } else if panGuesture.state == .changed {
            let deltaY = max(0, min(offsetY - panStartY, presentedViewController.view.frame.size.height))
            presentedViewController.view.transform = CGAffineTransform(translationX: 0, y: deltaY)

        } else if panGuesture.state == .ended || panGuesture.state == .cancelled || panGuesture.state == .failed {
            if offsetY - panStartY > 100 {
                backgroundBtnClicked()
            } else {
                openView()
            }
        }
    }

    private func openView() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveLinear, animations: {
            self.presentedViewController.view.transform = CGAffineTransform.identity
        }) { (finsihed) in
        }
    }
    
}

// MARK: - 从底部弹出的viewController都要遵守此协议
protocol PresentBottomType {
    /// 容器view的高度
    var contentHeight: CGFloat { get }
    /// 是否开启下拉关闭手势
    var canPanDown: Bool { get }
}


extension PresentBottomType {
    
    /// 默认关闭下拉关闭手势
    var canPanDown: Bool {
        return false
    }

}

// MARK: - UIViewController & PresentBottomType
typealias PresentBottomViewController = UIViewController & PresentBottomType

// MARK: - 提供自定义present方法
extension UIViewController: UIViewControllerTransitioningDelegate {
    
    /// 自定义present方法
    func presentBottomViewController(_ viewController: PresentBottomViewController ) {
        viewController.modalPresentationStyle = .custom
        viewController.transitioningDelegate = self
        present(viewController, animated: true, completion: nil)
    }

    /// UIViewControllerTransitioningDelegate
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return PresentBottomController(presentedViewController: presented, presenting: presenting)
    }
    
}

// MARK: - 自定义segue，在storyboard中设置custom，且destination必须遵守PresentBottomType
class PresentBottomSegue: UIStoryboardSegue {
    
    override func perform() {
        guard let destination = destination as? PresentBottomViewController else {
            fatalError("destination must be UIViewController & PresentBottomType")
        }
        source.presentBottomViewController(destination)
    }
    
}

















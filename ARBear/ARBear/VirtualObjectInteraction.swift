/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Coordinates movement and gesture interactions with virtual objects.
虚拟对象的移动和手势交互
*/

import UIKit
import ARKit

/// - Tag: VirtualObjectInteraction
class VirtualObjectInteraction: NSObject, UIGestureRecognizerDelegate {
    
    /// 开发人员设置翻译假设检测到的平面无限延伸。
    let translateAssumingInfinitePlane = true

    /// 场景交互hit-test视图
    let sceneView: VirtualObjectARView
    
    /**
     选中的虚拟对象
     */
    var selectedObject: VirtualObject?
    
    /// 跟踪平移和旋转手势所使用的对象
    private var trackedObject: VirtualObject? {
        didSet {
            guard trackedObject != nil else { return }
            selectedObject = trackedObject
        }
    }
    
    /// The tracked screen position used to update the `trackedObject`'s position in `updateObjectToCurrentTrackingPosition()`.
    private var currentTrackingPosition: CGPoint?
    
    /// 单击block
    var oneTapGestureHandler: () -> Void = {}
    
    /// 缩放手势相关
    private var lastScaleFactor: Float = 1.0

    init(sceneView: VirtualObjectARView) {
        self.sceneView = sceneView
        super.init()
        
        let panGesture = ThresholdPanGesture(target: self, action: #selector(didPan(_:)))
        panGesture.delegate = self
        
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(didRotate(_:)))
        rotationGesture.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        tapGesture.numberOfTapsRequired = 1
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.didDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        
        tapGesture.require(toFail: doubleTapGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.didPinch(_:)))
        
        // Add gestures to the `sceneView`.
        sceneView.addGestureRecognizer(panGesture)
        sceneView.addGestureRecognizer(rotationGesture)
        sceneView.addGestureRecognizer(tapGesture)
        sceneView.addGestureRecognizer(doubleTapGesture)
        sceneView.addGestureRecognizer(pinchGesture)
        
    }
    
    // MARK: - Gesture Actions
    
    /// 平移手势
    @objc
    func didPan(_ gesture: ThresholdPanGesture) {
        switch gesture.state {
        case .began:
            // 检查与新对象的交互
            if let object = objectInteracting(with: gesture, in: sceneView) {
                trackedObject = object
            }
            
        case .changed where gesture.isThresholdExceeded:
            guard let object = trackedObject else { return }
            let translation = gesture.translation(in: sceneView)
            
            let currentPosition = currentTrackingPosition ?? CGPoint(sceneView.projectPoint(object.position))
            
            // The `currentTrackingPosition` is used to update the `selectedObject` in `updateObjectToCurrentTrackingPosition()`.
            currentTrackingPosition = CGPoint(x: currentPosition.x + translation.x, y: currentPosition.y + translation.y)

            gesture.setTranslation(.zero, in: sceneView)
            
        case .changed:
            // 忽略对平移手势的更改，直到超过位移阈值
            break
            
        default:
            // Clear the current position tracking.
            // 清除当前位置追踪
            currentTrackingPosition = nil
            trackedObject = nil
        }
    }

    /**
     手势移动位置
     - Tag: updateObjectToCurrentTrackingPosition
     */
    @objc
    func updateObjectToCurrentTrackingPosition() {
        guard let object = trackedObject, let position = currentTrackingPosition else { return }
        translate(object, basedOn: position, infinitePlane: translateAssumingInfinitePlane)
    }

    /// - Tag: didRotate
    /// 旋转手势
    @objc
    func didRotate(_ gesture: UIRotationGestureRecognizer) {
        guard gesture.state == .changed else { return }
        
        /*
         查看对象（99％的用例），我们需要减去角度。
         当从下方观察物体时，为了使旋转也正常工作，必须根据物体是在摄像机的上方还是下方来翻转角度的符号...
         */
        
        trackedObject?.eulerAngles.y -= Float(gesture.rotation)
        
        gesture.rotation = 0
    }
    
    /// 点击手势
    @objc
    func didTap(_ gesture: UITapGestureRecognizer) {
        oneTapGestureHandler()
//        let touchLocation = gesture.location(in: sceneView)
//
//        if let tappedObject = sceneView.virtualObject(at: touchLocation) {
//            selectedObject = tappedObject
//        } else if let object = selectedObject {
//            // 将对象传送到用户触摸屏幕的任何地方
//            translate(object, basedOn: touchLocation, infinitePlane: false)
//        }
    }
    
    /// 双击手势
    @objc func didDoubleTap(_ gesture: UITapGestureRecognizer)  {
        // doubleTapGestureHandler()
        let touchLocation = gesture.location(in: sceneView)
        
        if let tappedObject = sceneView.virtualObject(at: touchLocation) {
            selectedObject = tappedObject
        } else if let object = selectedObject {
            // 将对象传送到用户触摸屏幕的任何地方
            translate(object, basedOn: touchLocation, infinitePlane: false)
        }
    }
    // 捏合手势
    @objc func didPinch(_ gesture: UIPinchGestureRecognizer) {
        
        let factor = Float(gesture.scale)
        var scale: Float = 1
        if factor > 1 { // 放大
            scale = lastScaleFactor + factor - 1
        } else { // 缩小
            scale = lastScaleFactor * factor
        }
        
        trackedObject?.scale = SCNVector3Make(scale, scale, scale)
        
        if gesture.state == UIGestureRecognizerState.ended {
            if factor > 1 {
                lastScaleFactor = lastScaleFactor + factor - 1
            } else {
                lastScaleFactor = lastScaleFactor * factor
            }
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow objects to be translated and rotated at the same time.
        return true
    }
    /// 辅助方法返回在提供的“手势”触摸位置下找到的第一个对象
    /// - Tag: TouchTesting
    private func objectInteracting(with gesture: UIGestureRecognizer, in view: ARSCNView) -> VirtualObject? {
        for index in 0..<gesture.numberOfTouches {
            let touchLocation = gesture.location(ofTouch: index, in: view)
            
            // Look for an object directly under the `touchLocation`.
            if let object = sceneView.virtualObject(at: touchLocation) {
                return object
            }
        }
        
        // 作为最后的手段寻找触摸中心下的对象。
        return sceneView.virtualObject(at: gesture.center(in: view))
    }
    
    // MARK: - Update object position

    /// - Tag: DragVirtualObject
    private func translate(_ object: VirtualObject, basedOn screenPos: CGPoint, infinitePlane: Bool) {
        guard let cameraTransform = sceneView.session.currentFrame?.camera.transform,
            let (position, _, isOnPlane) = sceneView.worldPosition(fromScreenPosition: screenPos,
                                                                   objectPosition: object.simdPosition,
                                                                   infinitePlane: infinitePlane) else { return }
        
        /*
         平面检测一般平稳，如果未检测平面，请平稳移动避免大跳跃
         */
        object.setPosition(position, relativeTo: cameraTransform, smoothMovement: !isOnPlane)
    }
}

///  提供多点触控产生的中心点
extension UIGestureRecognizer {
    func center(in view: UIView) -> CGPoint {
        let first = CGRect(origin: location(ofTouch: 0, in: view), size: .zero)

        let touchBounds = (1..<numberOfTouches).reduce(first) { touchBounds, index in
            return touchBounds.union(CGRect(origin: location(ofTouch: index, in: view), size: .zero))
        }

        return CGPoint(x: touchBounds.midX, y: touchBounds.midY)
    }
}

/*
See LICENSE folder for this sample’s licensing information.

Abstract:
ARSCNViewDelegate interactions for `ViewController`.

*/

import ARKit

extension ARViewController: ARSCNViewDelegate, ARSessionDelegate {
    
    // MARK: - ARSCNViewDelegate
    
    /// 实现这个来执行每帧游戏逻辑。 在评估任何动画和动作并模拟任何物理效果之前，每帧调用一次。
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.virtualObjectInteraction.updateObjectToCurrentTrackingPosition()
            self.updateFocusSquare()
        }
        
        // 如果启用光线估计，请更新模型灯光强度和环境贴图
        let baseIntensity: CGFloat = 40
        let lightingEnvironment = sceneView.scene.lightingEnvironment
        if let lightEstimate = session.currentFrame?.lightEstimate {
            lightingEnvironment.intensity = lightEstimate.ambientIntensity / baseIntensity
        } else {
            lightingEnvironment.intensity = baseIntensity
        }
    }
    
    /// 当新节点已映射到给定锚点时调用
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        DispatchQueue.main.async {
            self.statusViewController.cancelScheduledMessage(for: .planeEstimation)
            self.statusViewController.showMessage("检测到平面") // 表面检测
//            if self.virtualObjectLoader.loadedObjects.isEmpty {
//                self.statusViewController.scheduleMessage("TAP + TO PLACE AN OBJECT", inSeconds: 7.5, messageType: .contentPlacement)
//            }
            // 用户未放置物体自定放置
            if self.virtualObjectLoader.loadedObjects.isEmpty {
                // 放置模型
                self.virtualObjectLoader.loadVirtualObject(VirtualObject.availableObjects.first!, loadedHandler: { [unowned self] loadedObject in
                    DispatchQueue.main.async {
                        self.hideObjectLoadingUI()
                        self.placeVirtualObject(loadedObject)
                    }
                })
                
                self.displayObjectLoadingUI()
            }
        }
        
        updateQueue.async {
            for object in self.virtualObjectLoader.loadedObjects {
                object.adjustOntoPlaneAnchor(planeAnchor, using: node)
            }
        }
        

    }
    
    // 当使用给定锚点的数据更新节点时调用
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        updateQueue.async {
            for object in self.virtualObjectLoader.loadedObjects {
                object.adjustOntoPlaneAnchor(planeAnchor, using: node)
            }
        }
    }
    
    // MARK: - ARSessionObserver
    
    /// 相机追踪状态发生变化时调用
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        statusViewController.showTrackingQualityInfo(for: camera.trackingState, autoHide: true)
        
        switch camera.trackingState {
        case .notAvailable, .limited:
            statusViewController.escalateFeedback(for: camera.trackingState, inSeconds: 3.0)
        case .normal:
            statusViewController.cancelScheduledMessage(for: .trackingStateEscalation)
        }
    }
    
    ///  会话失败时会调用。会话将暂停
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        
        // Use `flatMap(_:)` to remove optional error messages.
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        
        DispatchQueue.main.async {
            self.displayErrorMessage(title: "The AR session failed.", message: errorMessage)
        }
    }
    /// 会话中断时调用。 在中断结束之前不会传送额外的帧更新
    func sessionWasInterrupted(_ session: ARSession) {
        blurView.isHidden = false
        statusViewController.showMessage("追踪中断", autoHide: false)
    }
    
    /*
     会话中断结束时被调用
     */
    func sessionInterruptionEnded(_ session: ARSession) {
        blurView.isHidden = true
        statusViewController.showMessage("重新启动追踪")
        
        restartExperience()
    }
}

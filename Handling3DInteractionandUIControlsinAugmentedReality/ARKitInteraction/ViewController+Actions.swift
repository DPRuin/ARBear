/*
See LICENSE folder for this sample’s licensing information.

Abstract:
UI Actions for the main view controller.
*/

import UIKit
import SceneKit

extension ViewController: UIGestureRecognizerDelegate {
    
    /// - Tag: restartExperience
    /// 重启体验
    func restartExperience() {
        guard isRestartAvailable, !virtualObjectLoader.isLoading else { return }
        isRestartAvailable = false

        statusViewController.cancelAllScheduledMessages()

        virtualObjectLoader.removeAllVirtualObjects()

        resetTracking()

        // Disable restart for a while in order to give the session time to restart.
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.isRestartAvailable = true
        }
    }
    
    /**
     Adds the specified virtual object to the scene, placed using
     the focus square's estimate of the world-space position
     currently corresponding to the center of the screen.
     放置虚拟物体
     - Tag: PlaceVirtualObject
     */
    func placeVirtualObject(_ virtualObject: VirtualObject) {
        guard let cameraTransform = session.currentFrame?.camera.transform,
            let focusSquarePosition = focusSquare.lastPosition else {
                statusViewController.showMessage("CANNOT PLACE OBJECT\nTry moving left or right.")
                return
        }
        
        virtualObjectInteraction.selectedObject = virtualObject
        virtualObject.setPosition(focusSquarePosition, relativeTo: cameraTransform, smoothMovement: false)
        
        updateQueue.async {
            self.sceneView.scene.rootNode.addChildNode(virtualObject)
        }
    }
    
    /// 点击屏幕展示虚拟物体
    @objc func showVirtualObject() {
        let virtualObjects = VirtualObject.availableObjects
        virtualObjectLoader.loadVirtualObject(virtualObjects.first!, loadedHandler: { [unowned self] loadedObject in
            DispatchQueue.main.async {
                self.hideObjectLoadingUI()
                self.placeVirtualObject(loadedObject)
            }
        })
        
        displayObjectLoadingUI()
    }
    
    // MARK: - UIGestureRecognizerDelegate
    /// Determines if the tap gesture for presenting the `VirtualObjectSelectionViewController` should be used.
    /// 确保加载的虚拟物体不为空
    func gestureRecognizerShouldBegin(_: UIGestureRecognizer) -> Bool {
        return virtualObjectLoader.loadedObjects.isEmpty
    }
    
    func gestureRecognizer(_: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool {
        return true
    }
    
    
    // MARK: Object Loading UI
    
    func displayObjectLoadingUI() {
        // Show progress indicator.
        spinner.startAnimating()
        
        isRestartAvailable = false
    }
    
    func hideObjectLoadingUI() {
        // Hide progress indicator.
        spinner.stopAnimating()
        isRestartAvailable = true
    }
}


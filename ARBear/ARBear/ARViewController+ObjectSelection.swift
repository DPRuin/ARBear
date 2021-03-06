/*
See LICENSE folder for this sample’s licensing information.

处理虚拟对象的加载和移动
*/

import UIKit
import SceneKit

extension ARViewController: VirtualObjectSelectionViewControllerDelegate {
    /// 放置虚拟物体
    func placeVirtualObject(_ virtualObject: VirtualObject) {
        guard let cameraTransform = session.currentFrame?.camera.transform,
            let focusSquarePosition = focusSquare.lastPosition else {
            statusViewController.showMessage("不能放置物体请左右移动手机")
            return
        }
        
        virtualObjectInteraction.selectedObject = virtualObject
        virtualObject.setPosition(focusSquarePosition, relativeTo: cameraTransform, smoothMovement: false)
        
        updateQueue.async {
            self.sceneView.scene.rootNode.addChildNode(virtualObject)
        }
    }
    
    // MARK: - VirtualObjectSelectionViewControllerDelegate
    
    func virtualObjectSelectionViewController(_: VirtualObjectSelectionViewController, didSelectObject object: VirtualObject) {
        showVirtualObject(withObject: object)
    }
    
    func showVirtualObject(withObject object: VirtualObject) {
        // 删除原来的模型
        virtualObjectLoader.removeAllVirtualObjects()
        
        // 放置选中的模型
        virtualObjectLoader.loadVirtualObject(object, loadedHandler: { [unowned self] loadedObject in
            DispatchQueue.main.async {
                self.hideObjectLoadingUI()
                self.placeVirtualObject(loadedObject)
            }
        })
        
        displayObjectLoadingUI()
    }
    
    // MARK: Object Loading UI

    func displayObjectLoadingUI() {
        // Show progress indicator.
        spinner.startAnimating()
        
        // addObjectButton.setImage(#imageLiteral(resourceName: "buttonring"), for: [])
        addObjectButton.setImage(UIImage(named: "Images.bundle/ring"), for: [])

        addObjectButton.isEnabled = false
        isRestartAvailable = false
    }

    func hideObjectLoadingUI() {
        // Hide progress indicator.
        spinner.stopAnimating()

//        addObjectButton.setImage(#imageLiteral(resourceName: "add"), for: [])
//        addObjectButton.setImage(#imageLiteral(resourceName: "addPressed"), for: [.highlighted])
        addObjectButton.setImage(UIImage(named: "Images.bundle/add"), for: [])
        addObjectButton.setImage(UIImage(named: "Images.bundle/addPressed"), for: [.highlighted])

        addObjectButton.isEnabled = true
        isRestartAvailable = true
    }
}

/*
See LICENSE folder for this sample’s licensing information.

Abstract:
UI Actions for the main view controller.
*/

import UIKit
import SceneKit

extension ARViewController: UIGestureRecognizerDelegate {
    
    enum SegueIdentifier: String {
        case showObjects
    }
    
    // MARK: - Interface Actions
    
    /// 展示选择模型界面
    @IBAction func showVirtualObjectSelectionViewController() {
        guard !addObjectButton.isHidden && !virtualObjectLoader.isLoading else { return }
        
        statusViewController.cancelScheduledMessage(for: .contentPlacement)
        performSegue(withIdentifier: SegueIdentifier.showObjects.rawValue, sender: addObjectButton)
    }
    
    /// 确保没有加载模型，才弹出选择模型界面
    func gestureRecognizerShouldBegin(_: UIGestureRecognizer) -> Bool {
        return virtualObjectLoader.loadedObjects.isEmpty
    }
    
    func gestureRecognizer(_: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool {
        return true
    }
    
    /// - Tag: restartExperience
    /// 重启体验
    func restartExperience() {
        guard isRestartAvailable, !virtualObjectLoader.isLoading else { return }
        isRestartAvailable = false

        statusViewController.cancelAllScheduledMessages()

        virtualObjectLoader.removeAllVirtualObjects()
//        addObjectButton.setImage(#imageLiteral(resourceName: "add"), for: [])
//        addObjectButton.setImage(#imageLiteral(resourceName: "addPressed"), for: [.highlighted])
        addObjectButton.setImage(UIImage(named: "Images.bundle/add"), for: [])
        addObjectButton.setImage(UIImage(named: "Images.bundle/addPressed"), for: [.highlighted])
        
        resetTracking()

        // Disable restart for a while in order to give the session time to restart.
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.isRestartAvailable = true
        }
    }
}

extension ARViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let identifier = segue.identifier,
            let segueIdentifer = SegueIdentifier(rawValue: identifier),
            segueIdentifer == .showObjects else { return }
        
        let objectsViewController = segue.destination as! VirtualObjectSelectionViewController
        objectsViewController.virtualObjects = VirtualObject.availableObjects
        objectsViewController.delegate = self
        
    }
    
}

// MARK: - 展示或隐藏toast
extension ARViewController {
    func showToast(withImageName name: String) {
        let bundlePath = Bundle.main.url(forResource: "Images", withExtension: "bundle")!
        let dataPath = bundlePath.appendingPathComponent("name")
        let imageData = try! Data(contentsOf: dataPath)
            
        imageView.image = UIImage.sd_image(with: imageData)
        guard toast.alpha == 0 else {
            return
        }
        
        toast.layer.masksToBounds = true
        toast.layer.cornerRadius = 7.5
        
        UIView.animate(withDuration: 0.25, animations: {
            self.toast.alpha = 1
            self.toast.frame = self.toast.frame.insetBy(dx: -5, dy: -5)
        })
        
    }
    
    func hideToast() {
        UIView.animate(withDuration: 0.25, animations: {
            self.toast.alpha = 0
            self.toast.frame = self.toast.frame.insetBy(dx: 5, dy: 5)
        })
    }
}

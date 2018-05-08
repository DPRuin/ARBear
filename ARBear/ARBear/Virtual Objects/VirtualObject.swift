/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A `SCNReferenceNode` subclass for virtual objects placed into the AR scene.
虚拟对象
*/

import Foundation
import SceneKit
import ARKit

class VirtualObject: SCNReferenceNode {
    
    /// 模型名称
    var modelName: String {
        
        return referenceURL.lastPathComponent.replacingOccurrences(of: ".scn", with: "")
    }
    
    /// 使用最近虚拟物体距离的平均值来避免物体比例的快速变化
    private var recentVirtualObjectDistances = [Float]()
    
    /// 重置对象的位置平滑
    func reset() {
        recentVirtualObjectDistances.removeAll()
    }
	
    /**
     放置对象
     - Tag: VirtualObjectSetPosition
     */
    func setPosition(_ newPosition: float3, relativeTo cameraTransform: matrix_float4x4, smoothMovement: Bool) {
        let cameraWorldPosition = cameraTransform.translation
        var positionOffsetFromCamera = newPosition - cameraWorldPosition
        
        // 将物体与相机的距离限制为最大10米
        if simd_length(positionOffsetFromCamera) > 10 {
            positionOffsetFromCamera = simd_normalize(positionOffsetFromCamera)
            positionOffsetFromCamera *= 10
        }
        
        /*
         计算最近十次更新中物体距相机的平均距离
         请注意，该距离将应用于从相机到内容的矢量，因此它只影响与对象相距的距离
         平均不会使内容“滞后”
         */
        if smoothMovement {
            let hitTestResultDistance = simd_length(positionOffsetFromCamera)
            
            // 获取最新的10个位置
            recentVirtualObjectDistances.append(hitTestResultDistance)
            recentVirtualObjectDistances = Array(recentVirtualObjectDistances.suffix(10))
            
            let averageDistance = recentVirtualObjectDistances.average!
            let averagedDistancePosition = simd_normalize(positionOffsetFromCamera) * averageDistance
            simdPosition = cameraWorldPosition + averagedDistancePosition
        } else {
            simdPosition = cameraWorldPosition + positionOffsetFromCamera
        }
    }
    
    /// - Tag: AdjustOntoPlaneAnchor
    func adjustOntoPlaneAnchor(_ anchor: ARPlaneAnchor, using node: SCNNode) {
        // Get the object's position in the plane's coordinate system.
        let planePosition = node.convertPosition(position, from: parent)
        
        // Check that the object is not already on the plane.
        guard planePosition.y != 0 else { return }
        
        // Add 10% tolerance to the corners of the plane.
        let tolerance: Float = 0.1
        
        let minX: Float = anchor.center.x - anchor.extent.x / 2 - anchor.extent.x * tolerance
        let maxX: Float = anchor.center.x + anchor.extent.x / 2 + anchor.extent.x * tolerance
        let minZ: Float = anchor.center.z - anchor.extent.z / 2 - anchor.extent.z * tolerance
        let maxZ: Float = anchor.center.z + anchor.extent.z / 2 + anchor.extent.z * tolerance
        
        guard (minX...maxX).contains(planePosition.x) && (minZ...maxZ).contains(planePosition.z) else {
            return
        }
        
        // Move onto the plane if it is near it (within 5 centimeters).
        let verticalAllowance: Float = 0.05
        let epsilon: Float = 0.001 // Do not update if the difference is less than 1 mm.
        let distanceToPlane = abs(planePosition.y)
        if distanceToPlane > epsilon && distanceToPlane < verticalAllowance {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = CFTimeInterval(distanceToPlane * 500) // Move 2 mm per second.
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            position.y = anchor.transform.columns.3.y
            SCNTransaction.commit()
        }
    }
}

extension VirtualObject {
    // MARK: Static Properties and Methods
    
    /// Loads all the model objects within `Models.scnassets`.
    static let availableObjects: [VirtualObject] = {
        let modelsURL = Bundle.main.url(forResource: "Models.scnassets", withExtension: nil)!

        let fileEnumerator = FileManager().enumerator(at: modelsURL, includingPropertiesForKeys: [])!

        return fileEnumerator.compactMap { element in
            let url = element as! URL

            guard url.pathExtension == "scn" else { return nil }

            return VirtualObject(url: url)
        }
    }()
    
    /// 沙盒中获取可用的模型
    static func availableCachesObjects() -> [VirtualObject] {
        // 从沙盒中获取模型
        // 沙盒中存放多个.scnassets文件
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        
        let fileEnumerator = FileManager().enumerator(at: cachesDirectory, includingPropertiesForKeys: [])!
        
        return fileEnumerator.compactMap { element in
            let url = element as! URL
            
            guard url.pathExtension == "scnassets" else { return nil }
            let name = url.lastPathComponent.replacingOccurrences(of: ".scnassets", with: "")
            let component = "\(name).scnassets/\(name).scn"
            let destinationURL = cachesDirectory.appendingPathComponent(component)
            
            return VirtualObject(url: destinationURL)
        }
    }
    
    /// Returns a `VirtualObject` if one exists as an ancestor to the provided node.
    static func existingObjectContainingNode(_ node: SCNNode) -> VirtualObject? {
        if let virtualObjectRoot = node as? VirtualObject {
            return virtualObjectRoot
        }
        
        guard let parent = node.parent else { return nil }
        
        // Recurse up to check if the parent is a `VirtualObject`.
        // 递归检查父对象是否是模型对象
        return existingObjectContainingNode(parent)
    }
}

extension Collection where Element == Float, Index == Int {
    /// Return the mean of a list of Floats. Used with `recentVirtualObjectDistances`.
    var average: Float? {
        guard !isEmpty else {
            return nil
        }
        
        let sum = reduce(Float(0)) { current, next -> Float in
            return current + next
        }
        
        return sum / Float(count)
    }
}

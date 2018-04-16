/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Utility functions and type extensions used throughout the projects.
*/

import Foundation
import ARKit

// MARK: - float4x4 extensions

extension float4x4 {
    /**
     Treats matrix as a (right-hand column-major convention) transform matrix
     and factors out the translation component of the transform.
    */
    var translation: float3 {
        let translation = columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}

// MARK: - CGPoint extensions

extension CGPoint {
    /// Extracts the screen space point from a vector returned by SCNView.projectPoint(_:).
	init(_ vector: SCNVector3) {
		x = CGFloat(vector.x)
		y = CGFloat(vector.y)
	}

    /// Returns the length of a point when considered as a vector. (Used with gesture recognizers.)
    var length: CGFloat {
		return sqrt(x * x + y * y)
	}
}

extension SCNAnimation {
    
    /// 获取模型动画
    static func fromFile(named name: String, inDirectory: String) -> SCNAnimation? {
        let animScene = SCNScene(named: name, inDirectory: inDirectory)
        var animation: SCNAnimation?
        
        animScene?.rootNode.enumerateChildNodes({ (child, stop) in
            if !child.animationKeys.isEmpty { // 节点动画key不为空
                let player = child.animationPlayer(forKey: child.animationKeys[0])
                animation = player?.animation
                
                // 停止
                stop.initialize(to: true)
            }
        })
        // ？？ 关键路径
        animation?.keyPath = name
        
        return animation
    }
}


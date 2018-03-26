//
//  ViewController+Game.swift
//  ARKitInteraction
//
//  Created by mac126 on 2018/3/24.
//  Copyright © 2018年 Apple. All rights reserved.
//

import SceneKit
import UIKit

extension ViewController {
    
    // MARK: Types
    
    struct Assets {
        static let basePath = "Models.scnassets/"
        private static let soundsPath = basePath + "sounds/"
        
        static func sound(named name: String) -> SCNAudioSource {
            guard let source = SCNAudioSource(named: soundsPath + name) else {
                fatalError("Failed to load audio source \(name).")
            }
            return source
        }
        
        static func animation(named name: String) -> CAAnimation {
            return CAAnimation.animation(withSceneName: basePath + name)
        }
        
        static func scene(named name: String) -> SCNScene {
            guard let scene = SCNScene(named: basePath + name) else {
                fatalError("Failed to load scene \(name).")
            }
            return scene
        }
    }
    
    /// 初始状态
    func setupGame() {
        character = scene.rootNode.childNode(withName: "Bob_root", recursively: true)!
        let idleScene = Assets.scene(named: "animation-idle.scn")
        let characterHierarchy = idleScene.rootNode.childNode(withName: "Bob_root", recursively: true)!
        
        for node in characterHierarchy.childNodes {
            character.addChildNode(node)
        }
        
        // Play character idle animation.
        let idleAnimation = Assets.animation(named: "animation-start-idle.scn")
        idleAnimation.repeatCount = Float.infinity
        character.addAnimation(idleAnimation, forKey: "start")
        
        // Configure sounds.
        let sounds = [cartJump]
        
        for sound in sounds {
            sound.isPositional = false
            sound.load()
        }
    }
    
    // MARK: Controlling the Character
    
    func jump() {
        character.addAnimation(jumpAnimation, forKey: nil)
        character.runAction(.playAudio(cartJump, waitForCompletion: false))
    }
    
    func startMusic() {
        guard isSoundEnabled else { return }
        
        let musicIntroSource = Assets.sound(named: "music_intro.mp3")
        let musicLoopSource = Assets.sound(named: "music_loop.mp3")
        musicLoopSource.loops = true
        musicIntroSource.isPositional = false
        musicLoopSource.isPositional = false
        
        // `shouldStream` must be false to wait for completion.
        musicIntroSource.shouldStream = false
        musicLoopSource.shouldStream = true
        
        scene.rootNode.runAction(.playAudio(musicIntroSource, waitForCompletion: true)) { [unowned self] in
            self.scene.rootNode.addAudioPlayer(SCNAudioPlayer(source:musicLoopSource))
        }
    }
    
    func startGame() {
        
        // Stop wind.
        scene.rootNode.removeAllAudioPlayers()
        
        // Play some music.
        startMusic()
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 2.0
        SCNTransaction.completionBlock = {
            self.jump()
        }
        
        let idleAnimation = Assets.animation(named: "animation-jump.scn")
        character.addAnimation(idleAnimation, forKey: nil)
        // character.removeAnimation(forKey: "start", fadeOutDuration: 0.3)
        character.removeAnimation(forKey: "start", blendOutDuration: 0.3)
        SCNTransaction.commit()
        
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 5.0
        
        SCNTransaction.commit()
    }
}

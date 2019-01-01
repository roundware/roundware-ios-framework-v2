//
// Created by Taylor Snead on 12/28/18.
//

import Foundation
import SceneKit
import AVKit
import SpriteKit

@objc class AudioSceneRenderer: NSObject {
    // relevant to management
    public var scene: SCNScene?
    public var sceneTime: TimeInterval = 0
    public var delegate: SCNSceneRendererDelegate? = nil
    public var isPlaying: Bool

    // audio
    public var audioEngine: AVAudioEngine = AVAudioEngine()
    public var audioEnvironmentNode: AVAudioEnvironmentNode = AVAudioEnvironmentNode()
    public var audioListener: SCNNode?

    init(_ scene: SCNScene) {
        self.scene = scene
        self.isPlaying = !scene.isPaused

        let node = SCNNode()
        scene.rootNode.addChildNode(node)
        self.audioListener = node
    }


    func present(_ scene: SCNScene, with transition: SKTransition, incomingPointOfView pointOfView: SCNNode?, completionHandler: (() -> Void)? = nil) {

    }

    public func hitTest(_ point: CGPoint, options: [SCNHitTestOption: Any]?) -> [SCNHitTestResult] {
        return []
//        fatalError("hitTest(point:options:) has not been implemented")
    }

    public func isNode(_ node: SCNNode, insideFrustumOf pointOfView: SCNNode) -> Bool {
        return false
//        fatalError("isNode(node:pointOfView:) has not been implemented")
    }

    public func nodesInsideFrustum(of pointOfView: SCNNode) -> [SCNNode] {
        return []
//        fatalError("nodesInsideFrustum(pointOfView:) has not been implemented")
    }

    public func projectPoint(_ point: SCNVector3) -> SCNVector3 {
        return point
//        fatalError("projectPoint(point:) has not been implemented")
    }

    public func unprojectPoint(_ point: SCNVector3) -> SCNVector3 {
        return point
//        fatalError("unprojectPoint(point:) has not been implemented")
    }


    // unused
    public var loops: Bool = false
    public var pointOfView: SCNNode? = nil
    public var autoenablesDefaultLighting: Bool = false
    public var isJitteringEnabled: Bool = false
    public var showsStatistics: Bool = false
    public var debugOptions: SCNDebugOptions = SCNDebugOptions()
    public var renderingAPI: SCNRenderingAPI = .openGLES2
    public var context: UnsafeMutableRawPointer? = nil
    public var currentRenderCommandEncoder: MTLRenderCommandEncoder? = nil
    public var device: MTLDevice? = nil
    public var colorPixelFormat: MTLPixelFormat = .invalid
    public var depthPixelFormat: MTLPixelFormat = .invalid
    public var stencilPixelFormat: MTLPixelFormat = .invalid
    public var commandQueue: MTLCommandQueue? = nil
    var overlaySKScene: SKScene? = nil

}

//extension AudioSceneRenderer: SCNSceneRenderer {
//    @objc public func prepare(_ object: Any, shouldAbortBlock block: (() -> Bool)? = nil) -> Bool {
//        return true
//    }
//}

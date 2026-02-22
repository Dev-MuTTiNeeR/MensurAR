//
//  ARViewContainer.swift
//  MensurAR
//
//  Created by Cem Akkaya on 22/02/26.
//

import SwiftUI
import RealityKit
import ARKit

struct ARViewContainer: UIViewRepresentable {
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        let config = ARWorldTrackingConfiguration()
        
        config.planeDetection = [.horizontal]
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        
        arView.session.run(config)
        
        // Debug overlays for testing
        arView.debugOptions.insert([.showFeaturePoints, .showWorldOrigin, .showSceneUnderstanding])
        
        // Optional: enable scene understanding behaviors for occlusion/collision during testing
        arView.environment.sceneUnderstanding.options.insert(.occlusion)
        arView.environment.sceneUnderstanding.options.insert(.collision)
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        arView.addGestureRecognizer(pinchGesture)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // empty
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var selectedEntity: ModelEntity?
        var initialScale: SIMD3<Float> = [0.01, 0.01, 0.01]
        
        let minScale: Float = 0.01
        let maxScale: Float = 0.02
        
        // tab gesture
        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = recognizer.view as? ARView else { return }
            
            let tapLocation = recognizer.location(in: arView)
            
            // raycast to find
            let results = arView.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal)
            
            guard let firstResult = results.first else {
                print("No surface was found - point camera at flat surface.")
                return
            }
            
            // load 3d model
            guard let modelEntity = try? ModelEntity.loadModel(named: "robot") else {
                print("Failed to load 3D model. Check that robot.usdz is in your project.")
                return
            }
            
            // scale model
            modelEntity.scale = [0.01, 0.01, 0.01]
            modelEntity.generateCollisionShapes(recursive: true)
            
            // create the anchor
            let anchorEntity = AnchorEntity(world: firstResult.worldTransform)
            anchorEntity.addChild(modelEntity)
            arView.scene.addAnchor(anchorEntity)
            
            selectedEntity = modelEntity
            print("Placed the model - pinch to scale.")
            
        }
        
        @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
            guard let entity = selectedEntity else {
                print("No entity is selected tap to place an object firs.")
                return
            }
            
            switch recognizer.state {
                
            case .began:
                initialScale = entity.scale
                print("Started scaling from \(initialScale)")
                
            case .changed:
                let scale = Float(recognizer.scale)
                let newScale = initialScale * scale
                
                let clampedScale = SIMD3<Float>(
                    x: max(minScale, min(maxScale, newScale.x)),
                    y: max(minScale, min(maxScale, newScale.y)),
                    z: max(minScale, min(maxScale, newScale.z)),
                )
                entity.scale = clampedScale
                
            case .ended:
                print("Final scale \(entity.scale)")
                
            case .cancelled:
                entity.scale = initialScale
                print("Scale canceled")
                
            default:
                break
            }
        }
    }
}

import SwiftUI
import RealityKit
import ARKit

/// Wraps RealityKit's ARView for use in SwiftUI.
struct ARViewContainer: UIViewRepresentable {
    let sessionManager: ARSessionManager

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.environment.sceneUnderstanding.options.insert(.occlusion)
        sessionManager.setupSession(in: arView)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}

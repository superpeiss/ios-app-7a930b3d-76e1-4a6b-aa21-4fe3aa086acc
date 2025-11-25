import SwiftUI
import SceneKit

// MARK: - 3D Scene View
struct SceneKitView: UIViewRepresentable {
    let configuration: Configuration

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.backgroundColor = UIColor.systemBackground

        // Create scene
        let scene = SCNScene()
        sceneView.scene = scene

        // Add camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 5, z: 15)
        cameraNode.look(at: SCNVector3(x: 0, y: 0, z: 0))
        scene.rootNode.addChildNode(cameraNode)

        // Add ambient light
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.color = UIColor.white
        ambientLight.light?.intensity = 400
        scene.rootNode.addChildNode(ambientLight)

        // Add directional light
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.light?.color = UIColor.white
        directionalLight.light?.intensity = 1000
        directionalLight.position = SCNVector3(x: 5, y: 10, z: 5)
        directionalLight.look(at: SCNVector3(x: 0, y: 0, z: 0))
        scene.rootNode.addChildNode(directionalLight)

        return sceneView
    }

    func updateUIView(_ sceneView: SCNView, context: Context) {
        guard let scene = sceneView.scene else { return }

        // Remove existing component nodes
        scene.rootNode.childNodes.filter { $0.name?.hasPrefix("component-") ?? false }.forEach {
            $0.removeFromParentNode()
        }

        // Add nodes for each selected component
        let sortedComponents = configuration.selectedComponents.values.sorted {
            $0.category.stepOrder < $1.category.stepOrder
        }

        var yOffset: Float = 0
        for component in sortedComponents {
            let node = createNode(for: component, at: yOffset)
            scene.rootNode.addChildNode(node)

            // Stack components vertically
            yOffset += 1.5
        }
    }

    private func createNode(for component: Component, at yOffset: Float) -> SCNNode {
        let node = SCNNode()
        node.name = "component-\(component.id)"

        // Create geometry based on component category
        let geometry: SCNGeometry

        switch component.category {
        case .base:
            geometry = SCNBox(width: 4, height: 0.5, length: 4, chamferRadius: 0.1)
            geometry.firstMaterial?.diffuse.contents = UIColor.systemGray
        case .mounting:
            geometry = SCNBox(width: 3.5, height: 0.3, length: 3.5, chamferRadius: 0.05)
            geometry.firstMaterial?.diffuse.contents = UIColor.systemBlue
        case .power:
            geometry = SCNBox(width: 2, height: 1, length: 1.5, chamferRadius: 0.1)
            geometry.firstMaterial?.diffuse.contents = UIColor.systemYellow
        case .control:
            geometry = SCNBox(width: 1.5, height: 0.8, length: 1.2, chamferRadius: 0.1)
            geometry.firstMaterial?.diffuse.contents = UIColor.systemGreen
        case .sensor:
            geometry = SCNCylinder(radius: 0.3, height: 0.5)
            geometry.firstMaterial?.diffuse.contents = UIColor.systemPurple
        case .actuator:
            geometry = SCNCylinder(radius: 0.4, height: 1.2)
            geometry.firstMaterial?.diffuse.contents = UIColor.systemRed
        case .interface:
            geometry = SCNBox(width: 1, height: 0.5, length: 0.8, chamferRadius: 0.05)
            geometry.firstMaterial?.diffuse.contents = UIColor.systemTeal
        case .housing:
            geometry = SCNBox(width: 4.5, height: 3, length: 4.5, chamferRadius: 0.2)
            geometry.firstMaterial?.diffuse.contents = UIColor.systemGray.withAlphaComponent(0.3)
            geometry.firstMaterial?.transparency = 0.3
        }

        // Add metallic effect
        geometry.firstMaterial?.metalness.contents = 0.5
        geometry.firstMaterial?.roughness.contents = 0.3

        node.geometry = geometry
        node.position = SCNVector3(x: 0, y: yOffset, z: 0)

        return node
    }
}

// MARK: - 3D Preview View
struct ThreeDPreviewView: View {
    let configuration: Configuration

    var body: some View {
        VStack(spacing: 0) {
            if configuration.selectedComponents.isEmpty {
                emptyStateView
            } else {
                SceneKitView(configuration: configuration)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            componentListView
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "cube.transparent")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Components Selected")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Select components to see the 3D preview")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private var componentListView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Selected Components")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 12)

            if configuration.selectedComponents.isEmpty {
                Text("None")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom, 12)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(configuration.selectedComponents.values).sorted(by: {
                            $0.category.stepOrder < $1.category.stepOrder
                        }), id: \.id) { component in
                            HStack {
                                categoryIcon(for: component.category)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(component.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)

                                    Text(component.category.rawValue)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Text(BOMService.shared.formatPrice(component.basePrice))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                        }
                    }
                }
                .frame(height: 150)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private func categoryIcon(for category: ComponentCategory) -> some View {
        let iconName: String
        let color: Color

        switch category {
        case .base:
            iconName = "square.3.layers.3d"
            color = .gray
        case .mounting:
            iconName = "bolt.horizontal"
            color = .blue
        case .power:
            iconName = "bolt.fill"
            color = .yellow
        case .control:
            iconName = "cpu"
            color = .green
        case .sensor:
            iconName = "sensor"
            color = .purple
        case .actuator:
            iconName = "gearshape.2"
            color = .red
        case .interface:
            iconName = "network"
            color = .teal
        case .housing:
            iconName = "square.dashed"
            color = .gray
        }

        return Image(systemName: iconName)
            .foregroundColor(color)
    }
}

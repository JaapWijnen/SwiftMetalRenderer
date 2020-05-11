import MetalKit

class Scene {
    var name: String

    var cameras: [Camera] = [Camera(name: "first camera")]
    var currentCameraIndex = 0
    var camera: Camera  {
        return cameras[currentCameraIndex]
    }
    
    var lights: [Light] = []

    let rootNode = Node(name: "root node")
    var renderables: [Renderable] = []

    var sceneConstantsBuffer = [SceneConstants](repeating: SceneConstants(), count: Preferences.constantBuffersInFlight)
    var fragmentUniformsBuffer = [FragmentUniforms](repeating: FragmentUniforms(), count: Preferences.constantBuffersInFlight)
    var currentConstantsIndex = 0

    var sceneConstants: SceneConstants {
        get { return sceneConstantsBuffer[currentConstantsIndex] }
        set { sceneConstantsBuffer[currentConstantsIndex] = newValue }
    }
    var fragmentUniforms: FragmentUniforms {
        get { return fragmentUniformsBuffer[currentConstantsIndex] }
        set { fragmentUniformsBuffer[currentConstantsIndex] = newValue }
    }

    init(name: String) {
        self.name = name
        buildScene()
    }

    func buildScene() {
        // override this to add objects to the scene
    }

    final func update(deltaTime: Float) {
        currentConstantsIndex = (currentConstantsIndex + 1) % Preferences.constantBuffersInFlight

        sceneConstants.projectionMatrix = camera.projectionMatrix
        sceneConstants.viewMatrix = camera.viewMatrix
        fragmentUniforms.cameraPosition = camera.position

        #warning("is this order correct?")

        updateScene(deltaTime: deltaTime)
        update(nodes: rootNode.children, deltaTime: deltaTime)
    }

    private func update(nodes: [Node], deltaTime: Float) {
        nodes.forEach { node in
            node.update(deltaTime: deltaTime)
            update(nodes: node.children, deltaTime: deltaTime)
        }
    }

    func updateScene(deltaTime: Float) {
        // override this to update your scene
    }

    #warning("no like dis")
    final func add(node: Node, parent: Node? = nil, render: Bool = true) {
        if let parent = parent {
            parent.add(childNode: node)
        } else {
            rootNode.add(childNode: node)
        }
        
        if render == true, let renderable = node as? Renderable {
            renderables.append(renderable)
        }
        
        addRenderableChildren(node: node, render: render)
    }
    
    #warning("and dis")
    private func addRenderableChildren(node: Node, render: Bool) {
        for child in node.children {
            if render == true, let renderable = child as? Renderable {
                renderables.append(renderable)
            }
            addRenderableChildren(node: child, render: render)
        }
    }

    final func remove(node: Node) {
        if let parent = node.parent {
            parent.remove(childNode: node)
        } else {
            for child in node.children {
                child.parent = nil
            }
            node.children = []
        }
        guard node is Renderable,
            let index = (renderables.firstIndex {
                $0 as? Node === node
            }) else { return }
        renderables.remove(at: index)
    }

    func sceneSizeWillChange(to size: CGSize) {
        for camera in cameras {
            camera.aspect = Float(size.width / size.height)
        }
    }
}

extension Scene {
    func renderShadowPass(renderEncoder: MTLRenderCommandEncoder) {
        let sunlight = lights.first { light in light.type == sunLight }!
        #warning("ja dit moet anders")
        let position: float3 = [sunlight.position.x,
                                sunlight.position.y,
                                sunlight.position.z]
        let center: float3 = [0, 0, 0]
        let lookAt = float4x4(lookAtEye: position, center: center, up: [0,1,0])

        sceneConstants.viewMatrix = float4x4(translation: [0,0,7]) * lookAt
        sceneConstants.projectionMatrix = float4x4(orthoLeft: -8, right: 8, bottom: -8, top: 8, near: 0.1, far: 16)
        sceneConstants.shadowMatrix = sceneConstants.projectionMatrix * sceneConstants.viewMatrix
        
        renderEncoder.setVertexBytes(&sceneConstants,
                                     length: MemoryLayout<SceneConstants>.stride,
                                     index: Int(BufferIndexSceneConstants.rawValue))
        
        for renderable in renderables {
            renderable.render(renderEncoder: renderEncoder, fragmentUniforms: fragmentUniforms)
        }
    }
    
    func renderGBufferPass(renderEncoder: MTLRenderCommandEncoder) {
        sceneConstants.viewMatrix = camera.viewMatrix
        sceneConstants.projectionMatrix = camera.projectionMatrix
        #warning("this is world or not world pos for cameras?")
        fragmentUniforms.cameraPosition = camera.position
        
        renderEncoder.setVertexBytes(&sceneConstants,
                                     length: MemoryLayout<SceneConstants>.stride,
                                     index: Int(BufferIndexSceneConstants.rawValue))
        
        renderEncoder.setFragmentBytes(&fragmentUniforms,
                                       length: MemoryLayout<FragmentUniforms>.stride,
                                       index: Int(BufferIndexFragmentUniforms.rawValue))
        
        for renderable in renderables {
            renderable.render(renderEncoder: renderEncoder, fragmentUniforms: fragmentUniforms)
        }
    }
    
    func renderCompositionPass(renderEncoder: MTLRenderCommandEncoder) {
        var lightDatas = lights.map { light in light.lightData }
        let lightCount = lightDatas.count
        fragmentUniforms.lightCount = UInt32(lightCount)
        
        renderEncoder.setFragmentBytes(&lightDatas,
                                       length: MemoryLayout<LightData>.stride * lightCount,
                                       index: Int(BufferIndexLights.rawValue))
        
        renderEncoder.setFragmentBytes(&fragmentUniforms, length: MemoryLayout<FragmentUniforms>.stride, index: Int(BufferIndexFragmentUniforms.rawValue))
    }
}

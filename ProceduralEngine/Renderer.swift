import MetalKit

class Renderer: NSObject {
    public static var screenSize: float2 = float2(repeating: 0)
    public static var aspectRatio: Float {
        return screenSize.x / screenSize.y
    }
    
    var albedoTexture: MTLTexture!
    var normalTexture: MTLTexture!
    var positionTexture: MTLTexture!
    var metallicRoughnessAOTexture: MTLTexture!
    var depthTexture: MTLTexture!
    var texturesBuffer: MTLBuffer!

    var depthStencilState: MTLDepthStencilState!

    var shadowTexture: MTLTexture!
    
    let shadowRenderPassDescriptor = MTLRenderPassDescriptor()
    var shadowPipelineState: MTLRenderPipelineState!

    var gBufferPipelineState: MTLRenderPipelineState!
    var gBufferRenderPassDescriptor: MTLRenderPassDescriptor!

    var compositionPipelineState: MTLRenderPipelineState!

    var quadVerticesBuffer: MTLBuffer!
    var quadTexCoordsBuffer: MTLBuffer!

    let quadVertices: [Float] = [
        -1.0,  1.0,
        1.0, -1.0,
        -1.0, -1.0,
        -1.0,  1.0,
        1.0,  1.0,
        1.0, -1.0,
    ]

    let quadTexCoords: [Float] = [
        0.0, 0.0,
        1.0, 1.0,
        0.0, 1.0,
        0.0, 0.0,
        1.0, 0.0,
        1.0, 1.0
    ]

    var semaphore: DispatchSemaphore

    init(metalView: MTKView) {
        semaphore = DispatchSemaphore(value: Preferences.constantBuffersInFlight)
        Engine.fps = metalView.preferredFramesPerSecond

        super.init()
        metalView.clearColor = MTLClearColor(red: 1.0, green: 1.0, blue: 0.8, alpha: 1)
        metalView.depthStencilPixelFormat = .depth32Float
        metalView.delegate = self
        metalView.framebufferOnly = false
        
        mtkView(metalView, drawableSizeWillChange: metalView.drawableSize)
    
        buildDepthStencilState()
        
        buildShadowTexture(size: metalView.drawableSize)
        
        buildShadowPipelineState()
        
        TextureManager.heap = TextureManager.buildHeap()
        
        buildGbufferPipelineState()
        
        // Create composition buffers
        quadVerticesBuffer = Engine.device.makeBuffer(bytes: quadVertices, length: MemoryLayout<Float>.stride * quadVertices.count, options: [])
        quadVerticesBuffer.label = "Quad vertices"
        quadTexCoordsBuffer = Engine.device.makeBuffer(bytes: quadTexCoords, length: MemoryLayout<Float>.stride * quadTexCoords.count, options: [])
        quadTexCoordsBuffer.label = "Quad texCoords"
        
        buildCompositionPipelineState()
    }

    func buildShadowPipelineState() {        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = Engine.shaderLibrary[.vertexShadow].function
        pipelineDescriptor.fragmentFunction = nil
        pipelineDescriptor.colorAttachments[0].pixelFormat = .invalid
        pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(MeshModel.vertexDescriptor)
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        do {
            shadowPipelineState = try Engine.device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }
    
    func buildGbufferPipelineState() {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.colorAttachments[1].pixelFormat = .rgba16Float
        descriptor.colorAttachments[2].pixelFormat = .rgba16Float
        descriptor.colorAttachments[3].pixelFormat = .bgra8Unorm
        descriptor.depthAttachmentPixelFormat = .depth32Float
        descriptor.label = "GBuffer state"
        descriptor.vertexFunction = Engine.shaderLibrary[.vertexGBuffer].function
        descriptor.fragmentFunction = Engine.shaderLibrary[.fragmentGBuffer].function
        descriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(MeshModel.vertexDescriptor)
        do {
            gBufferPipelineState = try Engine.device.makeRenderPipelineState(descriptor: descriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }
    
    func buildCompositionPipelineState() {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = Preferences.mainPixelFormat
        descriptor.depthAttachmentPixelFormat = .depth32Float
        descriptor.label = "Composition state"
        descriptor.vertexFunction = Engine.shaderLibrary[.vertexComposition].function
        descriptor.fragmentFunction = Engine.shaderLibrary[.fragmentComposition].function
        let textureEncoder = descriptor.fragmentFunction!.makeArgumentEncoder(bufferIndex: Int(BufferIndexTextures.rawValue))
        texturesBuffer = Engine.device.makeBuffer(length: textureEncoder.encodedLength, options: [])!
        texturesBuffer.label = "CompositionTextures"
        
        textureEncoder.setArgumentBuffer(texturesBuffer, offset: 0)
        textureEncoder.setTexture(albedoTexture, index: 0)
        textureEncoder.setTexture(normalTexture, index: 1)
        textureEncoder.setTexture(positionTexture, index: 2)
        textureEncoder.setTexture(metallicRoughnessAOTexture, index: 3)

        do {
            compositionPipelineState = try Engine.device.makeRenderPipelineState(descriptor: descriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }

    func buildTexture(pixelFormat: MTLPixelFormat, size: CGSize, label: String) -> MTLTexture {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat,
                                                                  width: Int(size.width),
                                                                  height: Int(size.height),
                                                                  mipmapped: false)
        descriptor.usage = [.shaderRead, .renderTarget]
        descriptor.storageMode = .private
        guard let texture = Engine.device.makeTexture(descriptor: descriptor) else {
            fatalError()
        }
        texture.label = "\(label) texture"
        return texture
    }
    
    func buildDepthStencilState() {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = .less
        descriptor.isDepthWriteEnabled = true
        depthStencilState = Engine.device.makeDepthStencilState(descriptor: descriptor)
    }

    func buildShadowTexture(size: CGSize) {
        shadowTexture = buildTexture(pixelFormat: .depth32Float, size: size, label: "Shadow")
        shadowRenderPassDescriptor.setUpDepthAttachment(texture: shadowTexture)
    }

    func buildGBufferTextures(size: CGSize) {
        albedoTexture = buildTexture(pixelFormat: .bgra8Unorm, size: size, label: "Albedo texture")
        normalTexture = buildTexture(pixelFormat: .rgba16Float, size: size, label: "Normal texture")
        positionTexture = buildTexture(pixelFormat: .rgba16Float, size: size, label: "Position texture")
        metallicRoughnessAOTexture = buildTexture(pixelFormat: .bgra8Unorm, size: size, label: "Metallic Roughness AO texture")
        depthTexture = buildTexture(pixelFormat: .depth32Float, size: size, label: "Depth texture")
    }

    func buildGBufferRenderPassDescriptor(size: CGSize) {
        gBufferRenderPassDescriptor = MTLRenderPassDescriptor()
        buildGBufferTextures(size: size)
        let textures: [MTLTexture] = [albedoTexture, normalTexture, positionTexture, metallicRoughnessAOTexture]
        for (position, texture) in textures.enumerated() {
            gBufferRenderPassDescriptor.setUpColorAttachment(position: position, texture: texture)
        }
        gBufferRenderPassDescriptor.setUpDepthAttachment(texture: depthTexture)
    }

    func renderShadowPass(renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.pushDebugGroup("Shadow pass")
        renderEncoder.label = "Shadow encoder"
        renderEncoder.setCullMode(.none)
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setDepthBias(0.01, slopeScale: 1.0, clamp: 0.01)
        renderEncoder.setRenderPipelineState(shadowPipelineState)
        
        SceneManager.currentScene.renderShadowPass(renderEncoder: renderEncoder)

        renderEncoder.endEncoding()
        renderEncoder.popDebugGroup()
    }

    func renderGbufferPass(renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.pushDebugGroup("Gbuffer pass")
        renderEncoder.label = "Gbuffer encoder"
        renderEncoder.setRenderPipelineState(gBufferPipelineState)
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setFragmentTexture(shadowTexture, index: Int(ShadowTexture.rawValue))
        
        SceneManager.currentScene.renderGBufferPass(renderEncoder: renderEncoder)
        
        renderEncoder.endEncoding()
        renderEncoder.popDebugGroup()
    }

    func renderCompositionPass(renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.pushDebugGroup("Composition pass")
        renderEncoder.label = "Composition encoder"
        renderEncoder.setRenderPipelineState(compositionPipelineState)
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setVertexBuffer(quadVerticesBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(quadTexCoordsBuffer, offset: 0, index: 1)
        renderEncoder.setFragmentBuffer(texturesBuffer, offset: 0, index: Int(BufferIndexTextures.rawValue))

        if let heap = TextureManager.heap {
            renderEncoder.useHeap(heap)
        }
        
        SceneManager.currentScene.renderCompositionPass(renderEncoder: renderEncoder)
        
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: quadVertices.count)
        renderEncoder.endEncoding()
        renderEncoder.popDebugGroup()
    }
}

extension Renderer: MTKViewDelegate {
    func updateScreenSize(size: CGSize) {
        Renderer.screenSize = float2(Float(size.width), Float(size.height))
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        updateScreenSize(size: size)
        for camera in SceneManager.currentScene!.cameras {
            camera.aspect = Renderer.aspectRatio
        }
        SceneManager.currentScene.sceneConstants.projectionMatrix = SceneManager.currentScene.camera.projectionMatrix

        buildShadowTexture(size: size)

        buildGBufferRenderPassDescriptor(size: size)
    }

    func draw(in view: MTKView) {
        _ = semaphore.wait(timeout: .distantFuture)

        guard let descriptor = view.currentRenderPassDescriptor,
            let commandBuffer = Engine.commandQueue.makeCommandBuffer() else {
            return
        }

        SceneManager.updateScene(deltaTime: 1 / Float(view.preferredFramesPerSecond))

        // shadow pass
        guard let shadowEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: shadowRenderPassDescriptor) else {
            return
        }
        renderShadowPass(renderEncoder: shadowEncoder)

        // g-buffer pass
        guard let gBufferEncoder = commandBuffer.makeRenderCommandEncoder(
            descriptor: gBufferRenderPassDescriptor) else {
            return
        }
        renderGbufferPass(renderEncoder: gBufferEncoder)

        // composition pass
        guard let compositionEncoder = commandBuffer.makeRenderCommandEncoder(
            descriptor: descriptor) else {
            return
        }
        
        compositionEncoder.useResource(albedoTexture, usage: .read)
        compositionEncoder.useResource(normalTexture, usage: .read)
        compositionEncoder.useResource(positionTexture, usage: .read)
        compositionEncoder.useResource(metallicRoughnessAOTexture, usage: .read)
        
        renderCompositionPass(renderEncoder: compositionEncoder)
        
        guard let drawable = view.currentDrawable else { return }

        commandBuffer.present(drawable)

        commandBuffer.addCompletedHandler { _ in
          self.semaphore.signal()
        }

        commandBuffer.commit()
    }
}

private extension MTLRenderPassDescriptor {
    func setUpDepthAttachment(texture: MTLTexture) {
        depthAttachment.texture = texture
        depthAttachment.loadAction = .clear
        depthAttachment.storeAction = .store
        depthAttachment.clearDepth = 1
    }

    func setUpColorAttachment(position: Int, texture: MTLTexture) {
        let attachment: MTLRenderPassColorAttachmentDescriptor = colorAttachments[position]
        attachment.texture = texture
        attachment.loadAction = .clear
        attachment.storeAction = .store
        attachment.clearColor = MTLClearColorMake(0.73, 0.92, 1, 1)
    }
}

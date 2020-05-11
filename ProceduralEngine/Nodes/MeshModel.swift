import MetalKit

class Model: Node {
    var tiling: UInt32 = 1

    var instanceCount: Int
    private var transforms: [Transform]
    var modelConstantsBuffer: MTLBuffer
    
    init(name: String, instanceCount: Int = 1) {
        self.instanceCount = instanceCount
        
        transforms = [Transform](repeatElement(Transform(), count: instanceCount))
        let modelConstants = transforms.map {
            ModelConstants(modelMatrix: $0.modelMatrix)
        }
        
        guard let modelConstantsBuffer =
            Engine.device.makeBuffer(bytes: modelConstants,
                                     length: MemoryLayout<ModelConstants>.stride * modelConstants.count) else {
            fatalError("Failed to create modelConstants buffer")
        }
        self.modelConstantsBuffer = modelConstantsBuffer

        super.init(name: name)
    }
    
    func updateModelConstantsBuffer(instance: Int, transform: Transform) {
        transforms[instance] = transform
        var pointer = modelConstantsBuffer.contents().bindMemory(to: ModelConstants.self,
                                                                 capacity: transforms.count)
        pointer = pointer.advanced(by: instance)
        pointer.pointee.modelMatrix = transforms[instance].modelMatrix
    }
    
    func render(renderEncoder: MTLRenderCommandEncoder) {
        
    }
}

extension Model: Renderable {
    func render(renderEncoder: MTLRenderCommandEncoder, fragmentUniforms: FragmentUniforms) {
        renderEncoder.pushDebugGroup(name)
        renderEncoder.setVertexBuffer(modelConstantsBuffer, offset: 0,
                                      index: Int(BufferIndexInstances.rawValue))
        
        var fragmentUniforms = fragmentUniforms
        fragmentUniforms.tiling = tiling
        renderEncoder.setFragmentBytes(&fragmentUniforms,
                                       length: MemoryLayout<FragmentUniforms>.stride,
                                       index: Int(BufferIndexFragmentUniforms.rawValue))
        
        var modelConstants = ModelConstants()
        modelConstants.modelMatrix = worldTransform
        
        renderEncoder.setVertexBytes(&modelConstants,
                                     length: MemoryLayout<ModelConstants>.stride,
                                     index: Int(BufferIndexModelConstants.rawValue))
        
        render(renderEncoder: renderEncoder)
        
        renderEncoder.popDebugGroup()
    }
}

class MeshModel: Model {

    let meshes: [Mesh]
    
    #warning("weg?")
    static var vertexDescriptor: MDLVertexDescriptor = MDLVertexDescriptor.defaultVertexDescriptor

    override init(name: String, instanceCount: Int = 1) {
        guard let assetUrl = Bundle.main.url(forResource: name, withExtension: nil) else {
            fatalError("Model: \(name) not found")
        }

        let allocator = MTKMeshBufferAllocator(device: Engine.device)
        let asset = MDLAsset(url: assetUrl,
                             vertexDescriptor: MDLVertexDescriptor.defaultVertexDescriptor,
                             bufferAllocator: allocator)

        // load Model I/O textures
        asset.loadTextures()

        // load meshes
        var mtkMeshes: [MTKMesh] = []
        let mdlMeshes = asset.childObjects(of: MDLMesh.self) as! [MDLMesh]
        _ = mdlMeshes.map { mdlMesh in
            mdlMesh.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
                                    tangentAttributeNamed: MDLVertexAttributeTangent,
                                    bitangentAttributeNamed: MDLVertexAttributeBitangent)
            #warning("remove")
            MeshModel.vertexDescriptor = mdlMesh.vertexDescriptor
            mtkMeshes.append(try! MTKMesh(mesh: mdlMesh, device: Engine.device))
        }

        meshes = zip(mdlMeshes, mtkMeshes).map {
            Mesh(mdlMesh: $0.0, mtkMesh: $0.1)
        }
        
        super.init(name: name, instanceCount: instanceCount)

        self.boundingBox = asset.boundingBox
        
        for mesh in meshes {
            for submesh in mesh.submeshes {
                let textureEncoder = Engine.shaderLibrary[.fragmentGBuffer].function.makeArgumentEncoder(bufferIndex: Int(BufferIndexTextures.rawValue))
                submesh.texturesBuffer = Engine.device.makeBuffer(length: textureEncoder.encodedLength, options: [])!
                submesh.texturesBuffer.label = "GBufferTextures"
                textureEncoder.setArgumentBuffer(submesh.texturesBuffer, offset: 0)
                
                if let albedoTexture = submesh.textures.albedo {
                    textureEncoder.setTexture(albedoTexture, index: Int(MaterialIndexAlbedo.rawValue))
                }
                textureEncoder.constantData(at: Int(MaterialIndexHasAlbedo.rawValue)).storeBytes(of: submesh.textures.hasAlbedo, as: Bool.self)
                
                if let normalTexture = submesh.textures.normal {
                    textureEncoder.setTexture(normalTexture, index: Int(MaterialIndexNormal.rawValue))
                }
                textureEncoder.constantData(at: Int(MaterialIndexHasNormal.rawValue)).storeBytes(of: submesh.textures.hasNormal, as: Bool.self)
                
                if let roughnessTexture = submesh.textures.roughness {
                    textureEncoder.setTexture(roughnessTexture, index: Int(MaterialIndexRoughness.rawValue))
                }
                textureEncoder.constantData(at: Int(MaterialIndexHasRoughness.rawValue)).storeBytes(of: submesh.textures.hasRoughness, as: Bool.self)
                
                if let metallicTexture = submesh.textures.metallic {
                    textureEncoder.setTexture(metallicTexture, index: Int(MaterialIndexMetallic.rawValue))
                }
                textureEncoder.constantData(at: Int(MaterialIndexHasMetallic.rawValue)).storeBytes(of: submesh.textures.hasMetallic, as: Bool.self)
                
                if let aoTexture = submesh.textures.ao {
                    textureEncoder.setTexture(aoTexture, index: Int(MaterialIndexAO.rawValue))
                }
                textureEncoder.constantData(at: Int(MaterialIndexHasAO.rawValue)).storeBytes(of: submesh.textures.hasAO, as: Bool.self)
            }
        }
    }
    
    override func render(renderEncoder: MTLRenderCommandEncoder) {
        for mesh in meshes {            
            for (index, vertexBuffer) in mesh.mtkMesh.vertexBuffers.enumerated() {
                renderEncoder.setVertexBuffer(vertexBuffer.buffer, offset: 0, index: index)
            }
            
            for submesh in mesh.submeshes {
                renderEncoder.setFragmentBuffer(submesh.texturesBuffer, offset: 0, index: Int(BufferIndexTextures.rawValue))
                
                if let colorTexture = submesh.textures.albedo {
                    renderEncoder.useResource(colorTexture, usage: .read)
                }
                if let normalTexture = submesh.textures.normal {
                    renderEncoder.useResource(normalTexture, usage: .read)
                }
                if let roughnessTexture = submesh.textures.roughness {
                    renderEncoder.useResource(roughnessTexture, usage: .read)
                }
                if let metallicTexture = submesh.textures.metallic {
                    renderEncoder.useResource(metallicTexture, usage: .read)
                }
                if let aoTexture = submesh.textures.ao {
                    renderEncoder.useResource(aoTexture, usage: .read)
                }

                var material = submesh.material
                renderEncoder.setFragmentBytes(&material,
                                               length: MemoryLayout<Material>.stride,
                                               index: Int(BufferIndexMaterials.rawValue))

                // perform draw call
                let mtkSubmesh = submesh.mtkSubmesh
                renderEncoder.drawIndexedPrimitives(type: .triangle,
                                                    indexCount: mtkSubmesh.indexCount,
                                                    indexType: mtkSubmesh.indexType,
                                                    indexBuffer: mtkSubmesh.indexBuffer.buffer,
                                                    indexBufferOffset: mtkSubmesh.indexBuffer.offset,
                                                    instanceCount: instanceCount)
            }
        }
    }
}

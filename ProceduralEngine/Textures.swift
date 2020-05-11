import MetalKit

struct GBufferTextures {
    let albedo: MTLTexture?
    let hasAlbedo: Bool
    
    let normal: MTLTexture?
    let hasNormal: Bool
    
    let roughness: MTLTexture?
    let hasRoughness: Bool
    
    let metallic: MTLTexture?
    let hasMetallic: Bool
    
    let ao: MTLTexture?
    let hasAO: Bool
}

struct CompositionTextures {
    let albedo: MTLTexture?
    let normal: MTLTexture?
    let position: MTLTexture?
    let metallicRoughnessAO: MTLTexture?
}

extension GBufferTextures {
    init(material: MDLMaterial?) {
        func property(with semantic: MDLMaterialSemantic) -> MTLTexture? {
            guard let property = material?.property(with: semantic),
                property.type == .string,
                let filename = property.stringValue,
                let texture = try? Submesh.loadTexture(imageName: filename) else {
                    if let property = material?.property(with: semantic),
                        property.type == .texture,
                        let mdlTexture = property.textureSamplerValue?.texture {
                    return try? Submesh.loadTexture(texture: mdlTexture)
                }
                return nil
            }
            return texture
        }
        albedo = property(with: .baseColor)
        normal = property(with: .objectSpaceNormal)
        roughness = property(with: .roughness)
        metallic = property(with: .metallic)
        ao = property(with: .ambientOcclusion)
        
        hasAlbedo = albedo != nil ? true : false
        hasNormal = normal != nil ? true : false
        hasRoughness = roughness != nil ? true : false
        hasMetallic = metallic != nil ? true : false
        hasAO = ao != nil ? true : false
    }
}

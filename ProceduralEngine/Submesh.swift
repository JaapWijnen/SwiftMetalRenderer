import MetalKit

class Submesh {
    var mtkSubmesh: MTKSubmesh

    var textures: GBufferTextures
    var material: Material
    var texturesBuffer: MTLBuffer!

    init(mdlSubmesh: MDLSubmesh, mtkSubmesh: MTKSubmesh) {
        self.mtkSubmesh = mtkSubmesh
        self.textures = GBufferTextures(material: mdlSubmesh.material)
        self.material = Material(material: mdlSubmesh.material)
    }
}

extension Submesh: Texturable {}

private extension Material {
    init(material: MDLMaterial?) {
        self.init()
        if let baseColor = material?.property(with: .baseColor),
            baseColor.type == .float3 {
            self.baseColor = baseColor.float3Value
        }
        if let specular = material?.property(with: .specular),
            specular.type == .float3 {
            self.specularColor = specular.float3Value
        }
        if let shininess = material?.property(with: .specularExponent),
            shininess.type == .float {
            self.shininess = shininess.floatValue
        }
        if let roughness = material?.property(with: .roughness),
            roughness.type == .float3 {
            self.roughness = roughness.floatValue
        }
        if let metallic = material?.property(with: .metallic), metallic.type == .float {
            self.metallic = metallic.floatValue
        }
    }
}

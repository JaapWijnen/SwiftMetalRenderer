import MetalKit

protocol Texturable {}

extension Texturable {
    static func loadTexture(imageName: String) throws -> MTLTexture? {
        let textureLoader = MTKTextureLoader(device: Engine.device)

        let textureLoaderOptions: [MTKTextureLoader.Option: Any] =
            [.origin: MTKTextureLoader.Origin.bottomLeft,
             .SRGB: false,
             .generateMipmaps: NSNumber(booleanLiteral: true)]
        let fileExtension = URL(fileURLWithPath: imageName).pathExtension.isEmpty ? "png" : nil
        guard let url = Bundle.main.url(forResource: imageName,
                                        withExtension: fileExtension) else {
            let texture = try? textureLoader.newTexture(name: imageName,
                                                        scaleFactor: 1.0,
                                                        bundle: Bundle.main,
                                                        options: nil)
            if texture == nil {
                print("WARNING: Texture not found: \(imageName)")
            }
            return texture
        }

        let texture = try textureLoader.newTexture(URL: url,
                                                   options: textureLoaderOptions)
        print("loaded texture: \(url.lastPathComponent)")
        return texture
    }

    static func loadTexture(texture: MDLTexture) throws -> MTLTexture? {
        let textureLoader = MTKTextureLoader(device: Engine.device)
        let textureLoaderOptions: [MTKTextureLoader.Option: Any] =
            [.origin: MTKTextureLoader.Origin.topLeft,
             .SRGB: false,
             .generateMipmaps: NSNumber(booleanLiteral: true)]

        let texture = try? textureLoader.newTexture(texture: texture,
                                                    options: textureLoaderOptions)
        return texture
    }

    static func loadCubeTexture(imageName: String) throws -> MTLTexture {
        let textureLoader = MTKTextureLoader(device: Engine.device)
        if let texture = MDLTexture(cubeWithImagesNamed: [imageName]) {
            let options: [MTKTextureLoader.Option: Any] =
                [.origin: MTKTextureLoader.Origin.topLeft,
                 .SRGB: false,
                 .generateMipmaps: NSNumber(booleanLiteral: false)]
            return try textureLoader.newTexture(texture: texture, options: options)
        }
        let texture = try textureLoader.newTexture(name: imageName, scaleFactor: 1.0,
                                                   bundle: .main)
        return texture
    }

    static func loadTextureArray(textureNames: [String]) -> MTLTexture? {
        var textures: [MTLTexture] = []
        for textureName in textureNames {
            do {
                if let texture = try Self.loadTexture(imageName: textureName) {
                    textures.append(texture)
                }
            } catch {
                fatalError(error.localizedDescription)
            }
        }
        guard textures.count > 0 else { return nil }
        let descriptor = MTLTextureDescriptor()
        descriptor.textureType = .type2DArray
        descriptor.pixelFormat = textures[0].pixelFormat
        descriptor.width = textures[0].width
        descriptor.height = textures[0].height
        descriptor.arrayLength = textures.count
        let arrayTexture = Engine.device.makeTexture(descriptor: descriptor)!
        let commandBuffer = Engine.commandQueue.makeCommandBuffer()!
        let blitEncoder = commandBuffer.makeBlitCommandEncoder()!
        let origin = MTLOrigin(x: 0, y: 0, z: 0)
        let size = MTLSize(width: arrayTexture.width,
                           height: arrayTexture.height, depth: 1)
        for (index, texture) in textures.enumerated() {
          blitEncoder.copy(from: texture,
                           sourceSlice: 0,
                           sourceLevel: 0,
                           sourceOrigin: origin,
                           sourceSize: size,
                           to: arrayTexture,
                           destinationSlice: index,
                           destinationLevel: 0,
                           destinationOrigin: origin)
        }
        blitEncoder.endEncoding()
        commandBuffer.commit()
        return arrayTexture
    }
}

import MetalKit

class TextureManager {
    static var textures: [MTLTexture] = []
    static var heap: MTLHeap?

    static func add(texture: MTLTexture?) -> Int? {
        guard let texture = texture else { return nil }
        TextureManager.textures.append(texture)
        return TextureManager.textures.count - 1
    }

    static func buildHeap() -> MTLHeap? {
        let heapDescriptor = MTLHeapDescriptor()

        let descriptors = textures.map { texture in
            MTLTextureDescriptor.descriptor(from: texture)
        }

        let sizeAndAligns = descriptors.map {
            Engine.device.heapTextureSizeAndAlign(descriptor: $0)
        }

        heapDescriptor.size = sizeAndAligns.reduce(0) { $0 + $1.size - ($1.size & ($1.align - 1)) + $1.align }
        if heapDescriptor.size == 0 { return nil }

        guard let heap = Engine.device.makeHeap(descriptor: heapDescriptor) else { fatalError() }

        let heapTextures = descriptors.map { descriptor -> MTLTexture in
            descriptor.storageMode = heapDescriptor.storageMode
            return heap.makeTexture(descriptor: descriptor)!
        }

        guard let commandBuffer = Engine.commandQueue.makeCommandBuffer(),
            let blitEncoder = commandBuffer.makeBlitCommandEncoder() else {
            fatalError()
        }

        zip(textures, heapTextures).forEach { (texture, heapTexture) in
            var region = MTLRegionMake2D(0, 0, texture.width, texture.height)
            for level in 0..<texture.mipmapLevelCount {
                for slice in 0..<texture.arrayLength {
                    blitEncoder.copy(from: texture,
                                     sourceSlice: slice,
                                     sourceLevel: level,
                                     sourceOrigin: region.origin,
                                     sourceSize: region.size,
                                     to: heapTexture,
                                     destinationSlice: slice,
                                     destinationLevel: level,
                                     destinationOrigin: region.origin)
                }
                region.size.width /= 2
                region.size.height /= 2
            }
        }
        blitEncoder.endEncoding()
        commandBuffer.commit()
        TextureManager.textures = heapTextures
        return heap
    }
}

extension MTLTextureDescriptor {
  static func descriptor(from texture: MTLTexture) -> MTLTextureDescriptor {
    let descriptor = MTLTextureDescriptor()
    descriptor.textureType = texture.textureType
    descriptor.pixelFormat = texture.pixelFormat
    descriptor.width = texture.width
    descriptor.height = texture.height
    descriptor.depth = texture.depth
    descriptor.mipmapLevelCount = texture.mipmapLevelCount
    descriptor.arrayLength = texture.arrayLength
    descriptor.sampleCount = texture.sampleCount
    descriptor.cpuCacheMode = texture.cpuCacheMode
    descriptor.usage = texture.usage
    descriptor.storageMode = texture.storageMode
    return descriptor
  }
}

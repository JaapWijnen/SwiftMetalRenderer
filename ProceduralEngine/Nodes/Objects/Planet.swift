import MetalKit

class Planet: Node {
    var terrainFaces: [TerrainFace] = []
    let resolution = 100

    init() {
        super.init(name: "Planet")

        let directions = [float3(0,0,-1), float3(0,0,1), float3(-1,0,0), float3(1,0,0), float3(0,1,0), float3(0,-1,0)]
        //let colors = [float3(1,0,0), float3(0,1,0), float3(0,0,1), float3(1,1,0), float3(1,0,1), float3(0,1,1)]
        let color = float3(1,1,1)
        let names = ["front", "back","left", "right", "up", "down"]
        for i in 0..<6 {
            let direction = directions[i]
            let terrainFace = TerrainFace(name: names[i], resolution: resolution, localUp: direction)
            terrainFace.material.baseColor = color
            terrainFaces.append(terrainFace)
            self.add(childNode: terrainFace)
        }
    }
}

class TerrainFace: Model {
    var resolution: Int
    var localUp: float3
    var axisA: float3
    var axisB: float3
    var terrainMesh: TerrainFaceMesh
    var material: Material
    
    var texturesBuffer: MTLBuffer!

    init(name: String, resolution: Int, localUp: float3) {
        self.resolution = resolution
        self.localUp = localUp
        self.axisA = float3(localUp.y, localUp.z, localUp.x)
        self.axisB = cross(localUp, axisA)
        self.terrainMesh = TerrainFaceMesh(resolution: resolution, localUp: localUp)
        self.material = Material()
        super.init(name: name)
        
        let textureEncoder = Engine.shaderLibrary[.fragmentGBuffer].function.makeArgumentEncoder(bufferIndex: Int(BufferIndexTextures.rawValue))
        texturesBuffer = Engine.device.makeBuffer(length: textureEncoder.encodedLength, options: [])!
        texturesBuffer.label = "GBufferTextures"
        textureEncoder.setArgumentBuffer(texturesBuffer, offset: 0)
        
        #warning("look at this at a later stage (should be abstracted away)")
        let noTextures = false
        textureEncoder.setTexture(nil, index: Int(MaterialIndexAlbedo.rawValue))
        textureEncoder.constantData(at: Int(MaterialIndexHasAlbedo.rawValue)).storeBytes(of: noTextures, as: Bool.self)
        textureEncoder.setTexture(nil, index: Int(MaterialIndexNormal.rawValue))
        textureEncoder.constantData(at: Int(MaterialIndexHasNormal.rawValue)).storeBytes(of: noTextures, as: Bool.self)
        textureEncoder.setTexture(nil, index: Int(MaterialIndexRoughness.rawValue))
        textureEncoder.constantData(at: Int(MaterialIndexHasRoughness.rawValue)).storeBytes(of: noTextures, as: Bool.self)
        textureEncoder.setTexture(nil, index: Int(MaterialIndexMetallic.rawValue))
        textureEncoder.constantData(at: Int(MaterialIndexHasMetallic.rawValue)).storeBytes(of: noTextures, as: Bool.self)
        textureEncoder.setTexture(nil, index: Int(MaterialIndexAO.rawValue))
        textureEncoder.constantData(at: Int(MaterialIndexHasAO.rawValue)).storeBytes(of: noTextures, as: Bool.self)
    }
    
    override func render(renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setFragmentBytes(&material,
                                       length: MemoryLayout<Material>.stride,
                                       index: Int(BufferIndexMaterials.rawValue))
        renderEncoder.setFragmentBuffer(texturesBuffer, offset: 0, index: Int(BufferIndexTextures.rawValue))
        terrainMesh.drawPrimitives(renderEncoder: renderEncoder)
    }
}

class CustomMesh {
    var vertices: [Vertex] = []
    var indices: [UInt32] = []
    var vertexBuffer: MTLBuffer!
    var indexBuffer: MTLBuffer!
    var instanceCount: Int = 1

    var vertexCount: Int {
        vertices.count
    }

    var indexCount: Int {
        indices.count
    }

    init() {
        createMesh()
        createBuffers()
    }

    func createMesh() {}

    func createBuffers() {
        if vertexCount > 0 {
            vertexBuffer = Engine.device.makeBuffer(bytes: vertices, length: MemoryLayout<Vertex>.stride * vertices.count, options: [])
        }
        if indexCount > 0 {
            indexBuffer = Engine.device.makeBuffer(bytes: indices, length: MemoryLayout<UInt32>.stride * indices.count, options: [])
        }
    }

    func addVertex(position: float3,
                   normal: float3 = float3(0, 1, 0),
                   color: float4 = float4(1,0,1,1),
                   uv: float2 = float2(repeating: 0)) {
        vertices.append(Vertex(position: position,
                               normal: normal,
                               uv: uv,
                               tangent: float3(0, 0, 1),
                               bitangent: float3(1, 0, 0),
                               color: color))
    }

    func addIndices(_ indices: [UInt32]) {
        self.indices.append(contentsOf: indices)
    }

    func setInstance(count: Int) {
        self.instanceCount = count
    }

    func drawPrimitives(renderEncoder: MTLRenderCommandEncoder) {
        if vertexCount > 0 {
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

            if indexCount > 0 {
                renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexCount, indexType: .uint32, indexBuffer: indexBuffer, indexBufferOffset: 0, instanceCount: instanceCount)
            } else {
                renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount, instanceCount: instanceCount)
            }
        }
    }
}

class TerrainFaceMesh: CustomMesh {
    var resolution: Int
    var localUp: float3
    var axisA: float3
    var axisB: float3

    init(resolution: Int, localUp: float3) {
        self.resolution = resolution
        self.localUp = localUp
        self.axisA = float3(localUp.y, localUp.z, localUp.x)
        self.axisB = cross(localUp, axisA)
        super.init()
    }

    override func createMesh() {
        for y in 0..<resolution {
            for x in 0..<resolution {
                let percent = float2(Float(x), Float(y)) / Float(resolution - 1)
                let pointOnUnitCube = localUp + (percent.x - 0.5) * 2 * axisA + (percent.y - 0.5) * 2 * axisB
                let pointOnUnitSphere = normalize(pointOnUnitCube)

                let planetRadius: Float = 2.0
                let scale: Float = 2.0

                let elevation: Float = calculateElevation(position: pointOnUnitSphere)
                let gradient = calculateGradient(position: pointOnUnitSphere) / (planetRadius + scale * elevation)

                let gradientNoRadial = gradient - dot(gradient, pointOnUnitSphere) * pointOnUnitSphere
                let normal = pointOnUnitSphere - scale * gradientNoRadial

                let pointOnPlanet = pointOnUnitSphere * (planetRadius + scale * elevation)
                addVertex(position: pointOnPlanet, normal: normal, color: float4(0.3,0.3,0.3,1), uv: float2(0,0))
            }
        }

        for y in 0..<resolution-1 {
            for x in 0..<resolution-1 {
                let i0 = UInt32(x + 0 + y * resolution)
                let i1 = UInt32(x + 0 + (y + 1) * resolution)
                let i2 = UInt32(x + 1 + y * resolution)
                let i3 = UInt32(x + 1 + (y + 1) * resolution)

                addIndices([i0, i1, i2, i1, i3, i2])
            }
        }
        
        print(vertices.count)
    }

    func calculateElevation(position: float3) -> Float {
        let layers: Int = 6
        let roughness: Float = 2.0
        let strength: Float = 1.0
        let persistance: Float = 0.5
        let baseRoughness: Float = 1.0
        let center = float3(0,0,0)

        var noiseValue: Float = 0.0
        var frequency: Float = baseRoughness
        var amplitude: Float = 1.0

        for _ in 0..<layers {
            let v = Float(PerlinNoise.noise(position * frequency + center))
            noiseValue += (v + 1) * 0.5 * amplitude
            frequency *= roughness
            amplitude *= persistance
        }

        return noiseValue * strength
    }

    func calculateGradient(position: float3) -> float3 {
        let layers: Int = 6
        let roughness: Float = 2.0
        let strength: Float = 1.0
        let persistance: Float = 0.5
        let baseRoughness: Float = 1.0
        let center = float3(0,0,0)

        var noiseValue: float3 = float3(repeating: 0.0)
        var frequency: Float = baseRoughness
        var amplitude: Float = 1.0

        // NOISE = (n(x * f + c) + 1 )* 0.5 * a
            //   = n(x * f + c) * 0.5 * a + 0.5 * a
        // NOISEP = 0.5 * a * dn/dx * f

        for _ in 0..<layers {
            let v = PerlinNoise.dnoise(position * frequency + center) * frequency
            noiseValue += v * 0.5 * amplitude
            frequency *= roughness
            amplitude *= persistance
        }

        return noiseValue * strength
    }
}

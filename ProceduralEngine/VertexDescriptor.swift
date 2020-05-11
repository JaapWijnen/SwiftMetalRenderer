import ModelIO

extension MDLVertexDescriptor {
    static var defaultVertexDescriptor: MDLVertexDescriptor = {
        let vertexDescriptor = MDLVertexDescriptor()

        var offset = 0
        // position attribute
        vertexDescriptor.attributes[Int(Position.rawValue)]
          = MDLVertexAttribute(name: MDLVertexAttributePosition,
                               format: .float3,
                               offset: 0,
                               bufferIndex: Int(BufferIndexVertices.rawValue))
        offset += MemoryLayout<float3>.stride

        // normal attribute
        vertexDescriptor.attributes[Int(Normal.rawValue)] =
          MDLVertexAttribute(name: MDLVertexAttributeNormal,
                             format: .float3,
                             offset: offset,
                             bufferIndex: Int(BufferIndexVertices.rawValue))
        offset += MemoryLayout<float3>.stride

        // add the uv attribute here
        vertexDescriptor.attributes[Int(UV.rawValue)] =
          MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate,
                             format: .float2,
                             offset: offset,
                             bufferIndex: Int(BufferIndexVertices.rawValue))
        offset += MemoryLayout<float3>.stride

        vertexDescriptor.attributes[Int(Tangent.rawValue)] =
          MDLVertexAttribute(name: MDLVertexAttributeTangent,
                             format: .float3,
                             offset: offset,
                             bufferIndex: Int(BufferIndexVertices.rawValue))
        offset += MemoryLayout<float3>.stride

        vertexDescriptor.attributes[Int(Bitangent.rawValue)] =
          MDLVertexAttribute(name: MDLVertexAttributeBitangent,
                             format: .float3,
                             offset: offset,
                             bufferIndex: Int(BufferIndexVertices.rawValue))
        offset += MemoryLayout<float3>.stride

        // color attribute
        vertexDescriptor.attributes[Int(Color.rawValue)] =
          MDLVertexAttribute(name: MDLVertexAttributeColor,
                             format: .float4,
                             offset: offset,
                             bufferIndex: Int(BufferIndexVertices.rawValue))

        offset += MemoryLayout<float4>.stride

        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: offset)
        //vertexDescriptor.layouts[1] = MDLVertexBufferLayout(stride: MemoryLayout<float3>.stride)
        //vertexDescriptor.layouts[2] = MDLVertexBufferLayout(stride: MemoryLayout<float3>.stride)
        return vertexDescriptor

    }()
}

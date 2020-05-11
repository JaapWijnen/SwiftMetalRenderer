import MetalKit

enum ShaderType {
    case vertexShadow
    case vertexGBuffer
    case vertexComposition
    
    case fragmentGBuffer
    case fragmentComposition
}

class ShaderLibrary: Library {
    typealias Title = ShaderType
    typealias Book = Shader
    
    private var library: [ShaderType: Shader] = [:]
    
    required init() {
        library.updateValue(Shader(name: "vertex_depth"), forKey: .vertexShadow)
        library.updateValue(Shader(name: "vertex_main"), forKey: .vertexGBuffer)
        library.updateValue(Shader(name: "compositionVert"), forKey: .vertexComposition)

        library.updateValue(Shader(name: "fragment_mainPBR"), forKey: .fragmentGBuffer)
        library.updateValue(Shader(name: "compositionFrag"), forKey: .fragmentComposition)
    }
    
    private func makeShader(name: String) -> MTLFunction {
        let shader = Engine.defaultLibrary.makeFunction(name: name)!
        shader.label = name
        return shader
    }
    
    subscript(type: ShaderType) -> Shader {
        return library[type]!
    }
}

class Shader {
    var function: MTLFunction
    
    init(name: String) {
        function = Engine.defaultLibrary.makeFunction(name: name)!
        function.label = name
    }
}

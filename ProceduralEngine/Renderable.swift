import MetalKit

protocol Renderable {
    var name: String { get }
    func render(renderEncoder: MTLRenderCommandEncoder, fragmentUniforms: FragmentUniforms)
}

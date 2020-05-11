import MetalKit

class Preferences {
    public static var clearColor: MTLClearColor = ClearColors.darkGrey
    public static var mainPixelFormat: MTLPixelFormat = .bgra8Unorm
    public static var mainDepthStencilPixelFormat: MTLPixelFormat = .depth32Float
    public static var gbufferPixelFormat: MTLPixelFormat = .rgba16Float
    public static var startingScene: SceneType = .helmet
    public static let constantBuffersInFlight = 3
}

public enum ClearColors {
    static let white = MTLClearColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    static let green = MTLClearColor(red: 0.22, green: 0.55, blue: 0.34, alpha: 1.0)
    static let grey = MTLClearColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
    static let darkGrey = MTLClearColor(red: 0.01, green: 0.01, blue: 0.01, alpha: 1.0)
    static let black = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
    static let limeGreen = MTLClearColor(red: 0.3, green: 0.7, blue: 0.3, alpha: 1.0)
}

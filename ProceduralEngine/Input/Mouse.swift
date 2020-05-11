import MetalKit

enum MouseCodes: Int {
    case left = 0
    case right = 1
    case center = 2
}

class Mouse {
    private static var mouseButtonCount = 12
    private static var mouseButtonList = [Bool].init(repeating: false, count: mouseButtonCount)
    
    private static var overallMousePosition = float2(0,0)
    private static var mousePositionDelta = float2(0,0)
    
    private static var scrollWheelPosition: Float = 0
    private static var lastWheelPosition: Float = 0.0
    private static var scrollWheelChange: Float = 0.0
    
    public static func setMouseButtonPressed(button: Int, isOn: Bool) {
        mouseButtonList[button] = isOn
    }
    
    public static func isMouseButtonPressed(button: MouseCodes) -> Bool {
        return mouseButtonList[Int(button.rawValue)] == true
    }
    
    public static func setOverallMousePosition(position: float2) {
        self.overallMousePosition = position
    }
    
    public static func setMousePositionChange(overallPosition: float2, deltaPosition: float2) {
        self.overallMousePosition = overallPosition
        self.mousePositionDelta = deltaPosition
    }
    
    public static func scrollMouse(deltaY: Float) {
        scrollWheelPosition += deltaY
        scrollWheelChange += deltaY
    }
    
    //Returns the overall position of the mouse on the current window
    public static func getMouseWindowPosition() -> float2 {
        return overallMousePosition
    }
    
    ///Returns the movement of the wheel since last time getDWheel() was called
    public static func getDWheel() -> Float {
        let position = scrollWheelChange
        scrollWheelChange = 0
        return -position
    }
    
    ///Movement on the y axis since last time getDY() was called.
    public static func getDY() -> Float {
        let result = mousePositionDelta.y
        mousePositionDelta.y = 0
        return result
    }
    
    ///Movement on the x axis since last time getDX() was called.
    public static func getDX() -> Float {
        let result = mousePositionDelta.x
        mousePositionDelta.x = 0
        return result
    }
    
    //Returns the mouse position in screen-view coordinates [-1, 1]
    public static func getMouseViewportPosition() -> float2 {
        let screenWidth = Renderer.screenSize.x
        let screenHeight = Renderer.screenSize.y
        let x = (overallMousePosition.x - screenWidth * 0.5) / (screenWidth * 0.5)
        let y = (overallMousePosition.y - screenHeight * 0.5) / (screenHeight * 0.5)
        return float2(x, y)
    }
}

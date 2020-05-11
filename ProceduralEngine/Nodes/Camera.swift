import simd

class Camera: Node {
    var fovDegrees: Float = 70
    var fovRadians: Float {
      return fovDegrees.toRadians
    }
    var aspect: Float = 1
    var near: Float = 0.001
    var far: Float = 100

    var projectionMatrix: float4x4 {
      return float4x4(projectionFov: fovRadians,
                      near: near,
                      far: far,
                      aspect: aspect)
    }

    var viewMatrix: float4x4 {
        let translateMatrix = float4x4(translation: position)
        let rotateMatrix = float4x4(rotation: rotation)
        let scaleMatrix = float4x4(scaling: scale)
        return (translateMatrix * scaleMatrix * rotateMatrix).inverse
    }

    func zoom(delta: Float) {}
    func rotate(delta: float2) {}
}

import MetalKit

public typealias float2 = SIMD2<Float>
public typealias float3 = SIMD3<Float>
public typealias float4 = SIMD4<Float>

public typealias double3 = SIMD3<Double>

extension Float {
    
    var toRadians: Float {
        return self / 180.0 * Float.pi
    }

    static func radians(fromDegrees degrees: Float) -> Float {
        degrees.toRadians
    }

    var toDegrees: Float {
        return self / Float.pi * 180.0
    }

    static func degrees(fromRadians radians: Float) -> Float {
        radians.toDegrees
    }

    static var randomZeroToOne: Float {
        return Float(arc4random()) / Float(UINT32_MAX)
    }
}

extension float3 {
    public static var xAxis = float3(1,0,0)
    public static var yAxis = float3(0,1,0)
    public static var zAxis = float3(0,0,1)
}

extension float4 {
    var xyz: float3 {
        return float3(self.x, self.y, self.z)
    }
}

extension matrix_float4x4 {
    init(translation: float3) {
      let matrix = float4x4(
        [            1,             0,             0, 0],
        [            0,             1,             0, 0],
        [            0,             0,             1, 0],
        [translation.x, translation.y, translation.z, 1]
      )
      self = matrix
    }

    mutating func translate(direction: float3) {
        let translation = matrix_float4x4(translation: direction)
        self = matrix_multiply(translation, self)
    }

    init(scaling: float3) {
      let matrix = float4x4(
        [scaling.x,         0,         0, 0],
        [        0, scaling.y,         0, 0],
        [        0,         0, scaling.z, 0],
        [        0,         0,         0, 1]
      )
      self = matrix
    }

    mutating func scale(scaling: float3) {
        let scale = matrix_float4x4(scaling: scaling)
        self = matrix_multiply(scale, self)
    }

    init(rotationX angle: Float) {
      let matrix = float4x4(
        [1,           0,          0, 0],
        [0,  cos(angle), sin(angle), 0],
        [0, -sin(angle), cos(angle), 0],
        [0,           0,          0, 1]
      )
      self = matrix
    }

    init(rotationY angle: Float) {
      let matrix = float4x4(
        [cos(angle), 0, -sin(angle), 0],
        [         0, 1,           0, 0],
        [sin(angle), 0,  cos(angle), 0],
        [         0, 0,           0, 1]
      )
      self = matrix
    }

    init(rotationZ angle: Float) {
      let matrix = float4x4(
        [ cos(angle), sin(angle), 0, 0],
        [-sin(angle), cos(angle), 0, 0],
        [          0,          0, 1, 0],
        [          0,          0, 0, 1]
      )
      self = matrix
    }

    init(rotation angle: float3) {
      let rotationX = float4x4(rotationX: angle.x)
      let rotationY = float4x4(rotationY: angle.y)
      let rotationZ = float4x4(rotationZ: angle.z)
      self = rotationX * rotationY * rotationZ
    }

    init(rotationYXZ angle: float3) {
      let rotationX = float4x4(rotationX: angle.x)
      let rotationY = float4x4(rotationY: angle.y)
      let rotationZ = float4x4(rotationZ: angle.z)
      self = rotationY * rotationX * rotationZ
    }

    mutating func rotate(angle: float3) {
        let rotation = float4x4(rotation: angle)
        self = matrix_multiply(rotation, self)
    }

    mutating func rotateYXZ(angle: float3) {
        let rotation = float4x4(rotationYXZ: angle)
        self = matrix_multiply(rotation, self)
    }

    static func rotation(angle: Float, axis: float3) -> matrix_float4x4 {
        var result = matrix_identity_float4x4

        let x: Float = axis.x
        let y: Float = axis.y
        let z: Float = axis.z

        let c: Float = cos(angle)
        let s: Float = sin(angle)

        let mc: Float = 1 - c

        let r1c1: Float = x * x * mc + c
        let r2c1: Float = x * y * mc + z * s
        let r3c1: Float = x * z * mc - y * s
        let r4c1: Float = 0.0

        let r1c2: Float = y * x * mc - z * s
        let r2c2: Float = y * y * mc + c
        let r3c2: Float = y * z * mc + x * s
        let r4c2: Float = 0.0

        let r1c3: Float = z * x * mc + y * s
        let r2c3: Float = z * y * mc - x * s
        let r3c3: Float = z * z * mc + c
        let r4c3: Float = 0.0

        let r1c4: Float = 0.0
        let r2c4: Float = 0.0
        let r3c4: Float = 0.0
        let r4c4: Float = 1.0

        result.columns = (
            float4(r1c1, r2c1, r3c1, r4c1),
            float4(r1c2, r2c2, r3c2, r4c2),
            float4(r1c3, r2c3, r3c3, r4c3),
            float4(r1c4, r2c4, r3c4, r4c4)
        )

        return result
    }

    mutating func rotate(angle: Float, axis: float3) {
        let rotation = matrix_float4x4.rotation(angle: angle, axis: axis)
        self = matrix_multiply(rotation, self)
    }

    init(projectionFov fov: Float, near: Float, far: Float, aspect: Float, lhs: Bool = true) {
      let y = 1 / tan(fov * 0.5)
      let x = y / aspect
      let z = lhs ? far / (far - near) : far / (near - far)
      let X = float4( x,  0,  0,  0)
      let Y = float4( 0,  y,  0,  0)
      let Z = lhs ? float4( 0,  0,  z, 1) : float4( 0,  0,  z, -1)
      let W = lhs ? float4( 0,  0,  z * -near,  0) : float4( 0,  0,  z * near,  0)
      self.init()
      columns = (X, Y, Z, W)
    }

    init(lookAtEye eye: float3, center: float3, up: float3) {
      let z = normalize(center-eye)
      let x = normalize(cross(up, z))
      let y = cross(z, x)

      let X = float4(x.x, y.x, z.x, 0)
      let Y = float4(x.y, y.y, z.y, 0)
      let Z = float4(x.z, y.z, z.z, 0)
      let W = float4(-dot(x, eye), -dot(y, eye), -dot(z, eye), 1)

      self.init()
      columns = (X, Y, Z, W)
    }

    init(orthoLeft left: Float, right: Float, bottom: Float, top: Float, near: Float, far: Float) {
      let X = float4(2 / (right - left), 0, 0, 0)
      let Y = float4(0, 2 / (top - bottom), 0, 0)
      let Z = float4(0, 0, 1 / (far - near), 0)
      let W = float4((left + right) / (left - right),
                     (top + bottom) / (bottom - top),
                     near / (near - far),
                     1)
      self.init()
      columns = (X, Y, Z, W)
    }
}

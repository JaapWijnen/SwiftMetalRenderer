//
//  Transform.swift
//  ProceduralEngine
//
//  Created by Jaap on 12/03/2020.
//  Copyright © 2020 workmoose. All rights reserved.
//

import Foundation

struct Transform {
    var position: float3 = float3(repeating: 0)
    var rotation: float3 = float3(repeating: 0) {
      didSet {
        let rotationMatrix = float4x4(rotation: rotation)
        quaternion = simd_quatf(rotationMatrix)
      }
    }
    var quaternion = simd_quatf()
    var scale: float3 = float3(repeating: 1)

    var modelMatrix: float4x4 {
        let translateMatrix = float4x4(translation: position)
        let rotateMatrix = float4x4(quaternion)
        let scaleMatrix = float4x4(scaling: scale)
        return translateMatrix * rotateMatrix * scaleMatrix
    }

    var forwardVector: float3 {
      return normalize([sin(rotation.y), 0, cos(rotation.y)])
    }

    var rightVector: float3 {
      return [forwardVector.z, forwardVector.y, -forwardVector.x]
    }
}

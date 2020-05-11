//
//  ROAM.swift
//  ProceduralEngine
//
//  Created by Paul Wijnen on 05/04/2020.
//  Copyright © 2020 workmoose. All rights reserved.
//

import Foundation

class RoamTriangle {
    var i1: Int // indices eigenlijk
    var i2: Int
    var i3: Int
    
    var e0: RoamTriangle!
    var e1: RoamTriangle!
    var e2 : RoamTriangle!
    var parent: RoamTriangle!
    var diamond: RoamDiamond!
    
    init(i1: Int, i2: Int, i3: Int) {
        self.i1 = i1
        self.i2 = i2
        self.i3 = i3
    }
}

class RoamDiamond {
    var c1: RoamTriangle!
    var c2: RoamTriangle!
    
    var p1: RoamTriangle!
    var p2: RoamTriangle!
}

class RoamSphere {
    var vertices: [Vertex]
    var triangles: [RoamTriangle]
    var diamonds: [RoamDiamond]
    
    init() {
        let positions: [float3] = [
            float3( 1, 1, 1),
            float3(-1, 1, 1),
            float3( 1,-1, 1),
            float3(-1,-1, 1),
            
            float3( 1, 1,-1),
            float3(-1, 1,-1),
            float3( 1,-1,-1),
            float3(-1,-1,-1),
        ]
        vertices = positions.map { position in
            let normalizedPos = normalize(position)
            return Vertex(position: normalizedPos, normal: normalizedPos, uv: float2(0,0), tangent: float3(0,0,0), bitangent: float3(0,0,0), color: float4(0.5, 0.5, 0.5, 1))
        }
        
        triangles = []
        
        diamonds = []
        
        let t01 = RoamTriangle(i1: 1, i2: 3, i3: 2) // Front
        let t02 = RoamTriangle(i1: 2, i2: 0, i3: 1)
        let t03 = RoamTriangle(i1: 0, i2: 2, i3: 6) // Right
        let t04 = RoamTriangle(i1: 6, i2: 4, i3: 0)
        let t05 = RoamTriangle(i1: 4, i2: 6, i3: 7) // Back
        let t06 = RoamTriangle(i1: 7, i2: 5, i3: 4)
        let t07 = RoamTriangle(i1: 5, i2: 7, i3: 3) // Left
        let t08 = RoamTriangle(i1: 3, i2: 1, i3: 5)
        let t09 = RoamTriangle(i1: 5, i2: 1, i3: 0) // Top
        let t10 = RoamTriangle(i1: 0, i2: 4, i3: 5)
        let t11 = RoamTriangle(i1: 3, i2: 7, i3: 6) // Bottom
        let t12 = RoamTriangle(i1: 6, i2: 2, i3: 3)
        
        // front
        t01.e0 = t08
        t01.e1 = t12
        t01.e2 = t02
        t02.e0 = t03
        t02.e1 = t09
        t02.e2 = t01
        // right
        t03.e0 = t02
        t03.e1 = t12
        t03.e2 = t04
        t04.e0 = t05
        t04.e1 = t10
        t04.e2 = t03
        // back
        t05.e0 = t04
        t05.e1 = t11
        t05.e2 = t06
        t06.e0 = t07
        t06.e1 = t10
        t06.e2 = t05
        // left
        t07.e0 = t06
        t07.e1 = t11
        t07.e2 = t08
        t08.e0 = t01
        t08.e1 = t09
        t08.e2 = t07
        // top
        t09.e0 = t08
        t09.e1 = t02
        t09.e2 = t10
        t10.e0 = t04
        t10.e1 = t06
        t10.e2 = t09
        // bottom
        t11.e0 = t07
        t11.e1 = t05
        t11.e2 = t12
        t12.e0 = t03
        t12.e1 = t01
        t12.e2 = t11
        
        triangles.append(contentsOf: [t01, t02, t03, t04, t05, t06, t07, t08, t09, t10, t11, t12])
    }
}

//
//  TrainAndLightsScene.swift
//  ProceduralEngine
//
//  Created by Jaap on 13/03/2020.
//  Copyright © 2020 workmoose. All rights reserved.
//

import Foundation


class TrainAndLightsScene: Scene {
    
    var lightNode: Node!
    var train: MeshModel!
    
    override func buildScene() {
        let camera = Camera(name: "the camera")
        camera.position = [0, 2, -5]
        //camera.transform.rotation = [-0.5, -0.5, 0]
        cameras.append(camera)
        currentCameraIndex = 1
        
        lightNode = Node(name: "light node")

        let sunlight = buildDefaultLight(name: "Sunlight")
        sunlight.position = [2, 1, -2]
        sunlight.position = [2, 1, -2]
        sunlight.intensity = 0.8
        lights.append(sunlight)

        //createPointLights(count: 30, min: [-10, 0.3, -10], max: [10, 2, 20])
        createPointLights(count: 30, min: [-3, 0.3, -3], max: [1, 2, 2])

        train = MeshModel(name: "train.obj")
        train.position = [-0.5, 0, 1]
        train.rotation = [0, Float.radians(fromDegrees: 45), 0]
        add(node: train)

        let tree = MeshModel(name: "treefir.obj")
        tree.position = [1.4, 0, 3]
        tree.position = [1.4, 0, 0]
        add(node: tree)

        let plane = MeshModel(name: "plane.obj")
        plane.scale = [8, 8, 8]
        plane.position = [0, 0, 0]
        add(node: plane)
    }
    
    override func updateScene(deltaTime: Float) {
        lightNode.rotation.y += 0.5 * deltaTime
        
        for light in lights {
            light.position = (light.worldTransform * float4(light.position, 0)).xyz
        }
        
        train.rotation.y += deltaTime
    }

    func buildDefaultLight(name: String) -> Light {
      let light = Light(name: name)
      light.position = [0, 0, 0]
      light.color = [1, 1, 1]
      light.intensity = 1
      light.attenuation = float3(1, 0, 0)
      light.type = sunLight
      return light
    }

    func createPointLights(count: Int, min: float3, max: float3) {
        let colors: [float3] = [
            float3(1, 0, 0),
            float3(1, 1, 0),
            float3(1, 1, 1),
            float3(0, 1, 0),
            float3(0, 1, 1),
            float3(0, 0, 1),
            float3(0, 1, 1),
            float3(1, 0, 1)
        ]
        let newMin: float3 = [min.x*100, min.y*100, min.z*100]
        let newMax: float3 = [max.x*100, max.y*100, max.z*100]
        for i in 0..<count {
            let light = buildDefaultLight(name: "light \(i)")
            light.type = pointLight
            let x = Float(random(range: Int(newMin.x)...Int(newMax.x))) * 0.01
            let y = Float(random(range: Int(newMin.y)...Int(newMax.y))) * 0.01
            let z = Float(random(range: Int(newMin.z)...Int(newMax.z))) * 0.01
            light.position = [x, y, z]
            light.position = [x, y, z]
            light.color = colors[random(range: 0...colors.count)]
            light.intensity = 0.6
            light.attenuation = float3(1.5, 1, 1)
            lightNode.add(childNode: light)
            lights.append(light)
        }
    }

    func random(range: CountableClosedRange<Int>) -> Int {
        var offset = 0
        if range.lowerBound < 0 {
            offset = abs(range.lowerBound)
        }
        let min = UInt32(range.lowerBound + offset)
        let max = UInt32(range.upperBound + offset)
        return Int(min + arc4random_uniform(max-min)) - offset
    }
}

class PlanetScene: Scene {
    
    var planet: Planet!
    
    override func buildScene() {
        let camera = Camera(name: "the camera")
        camera.position = [0, 0, -12]
        cameras.append(camera)
        currentCameraIndex = 1
        
        let sunlight = buildDefaultLight(name: "Sunlight")
        sunlight.position = [5, 5, -5]
        sunlight.intensity = 0.3
        sunlight.color = float3(1, 1, 1)
        sunlight.specularColor = float3(1, 1, 1)
        lights.append(sunlight)
        
        planet = Planet()
        
        for terrainFace in planet.terrainFaces {
            terrainFace.material.baseColor = float3(0.5, 0.5, 0.5)
            terrainFace.material.shininess = 1
        }
        
        add(node: planet)
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
    
    override func updateScene(deltaTime: Float) {
        if(Mouse.isMouseButtonPressed(button: .left)) {
            planet.rotation += float3(Mouse.getDY() * deltaTime, Mouse.getDX() * deltaTime, 0)
        }
        
        camera.position = camera.position + float3(0, 0, Mouse.getDWheel() * deltaTime)
    }
}

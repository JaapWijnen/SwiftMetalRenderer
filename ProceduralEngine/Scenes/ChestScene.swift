class ChestScene: Scene {
    
    var chest: MeshModel!
    override func buildScene() {
        chest = MeshModel(name: "chest/chest_obj.obj")
        add(node: chest)
        chest.scale = float3(0.02, 0.02, 0.02)
        
        let camera = Camera(name: "the camera")
        camera.position = [0, 0, -5]
        //camera.transform.rotation = [-0.5, -0.5, 0]
        cameras.append(camera)
        currentCameraIndex = 1
        
        let sunlight = buildDefaultLight(name: "Sunlight")
        sunlight.position = [2, 1, -2]
        sunlight.position = [2, 1, -2]
        sunlight.intensity = 0.8
        lights.append(sunlight)
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
        chest.rotation.y += deltaTime
    }
}

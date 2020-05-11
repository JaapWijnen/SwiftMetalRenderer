class HelmetScene: Scene {
    
    var helmet: MeshModel!
    override func buildScene() {
        helmet = MeshModel(name: "helmet/DamagedHelmet.obj")
        helmet.scale = float3(2, 2, 2)
        add(node: helmet)
        
        let camera = Camera(name: "the camera")
        camera.position = [0, 0, -5]
        //camera.rotation = [-0.5, -0.5, 0]
        cameras.append(camera)
        currentCameraIndex = 1
        
        let sunlight = buildDefaultLight(name: "Sunlight")
        sunlight.position = [0, 0, -5]
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
        if(Mouse.isMouseButtonPressed(button: .left)) {
            helmet.rotation += float3(Mouse.getDY() * deltaTime, Mouse.getDX() * deltaTime, 0)
            //helmet.rotation.x += Mouse.getDY() * deltaTime
            //helmet.rotation.y += Mouse.getDX() * deltaTime
        }
        //helmet.transform.rotation.y += deltaTime * 0.5
    }
}

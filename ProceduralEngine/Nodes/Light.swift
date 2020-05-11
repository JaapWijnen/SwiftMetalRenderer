
class Light: Node {
    private(set) var lightData = LightData()
    
    override var position: float3 {
        get { return super.position }
        set {
            lightData.position = newValue
            super.position = newValue
        }
    }
    
    var color: float3 {
        get { lightData.color }
        set { lightData.color = newValue }
    }
    
    var specularColor: float3 {
        get { lightData.specularColor }
        set { lightData.specularColor = newValue }
    }
    
    var intensity: Float {
        get { lightData.intensity }
        set { lightData.intensity = newValue }
    }
    
    var attenuation: float3 {
        get { lightData.attenuation }
        set { lightData.attenuation = newValue }
    }
    
    var type: LightType {
        get { lightData.type }
        set { lightData.type = newValue }
    }
    
    var coneAngle: Float {
        get { lightData.coneAngle }
        set { lightData.coneAngle = newValue }
    }
    
    var coneDirection: float3 {
        get { lightData.coneDirection }
        set { lightData.coneDirection = newValue }
    }
    
    var coneAttenuation: Float {
        get { lightData.coneAttenuation }
        set { lightData.coneAttenuation = newValue }
    }
}


import MetalKit

enum SceneType {
    case test
    case trainAndLight
    case chest
    case helmet
    case planet
}

class SceneManager {
    static var currentScene: Scene!

    public static func initialize(_ sceneType: SceneType) {
        setScene(sceneType)
    }

    public static func setScene(_ sceneType: SceneType) {
        switch sceneType {
        case .test:
            currentScene = TestScene(name: "Test")
        case .trainAndLight:
            currentScene = TrainAndLightsScene(name: "Train and Light")
        case .chest:
            currentScene = ChestScene(name: "Chest Scene")
        case .helmet:
            currentScene = HelmetScene(name: "Helmet Scene")
        case .planet:
            currentScene = PlanetScene(name: "Planet Scene")
       }
    }

    public static func updateScene(deltaTime: Float) {
        currentScene.update(deltaTime: deltaTime)
    }
}

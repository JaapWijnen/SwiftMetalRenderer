class TestScene: Scene {
    override func buildScene() {
        let instanceCount = 8
        let tree = MeshModel(name: "tree.obj", instanceCount: instanceCount)
        add(node: tree)
        for i in 0..<instanceCount {
          var transform = Transform()
          transform.position.x = .random(in: -15..<15)
          transform.position.z = .random(in: 10..<15)
          transform.rotation.y = .random(in: -Float.pi..<Float.pi)
          tree.updateModelConstantsBuffer(instance: i, transform: transform)
        }
    }
}

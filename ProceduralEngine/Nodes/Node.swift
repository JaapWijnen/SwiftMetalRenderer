import MetalKit

class Node {
    var name: String = "untitled"

    var parent: Node?
    var children: [Node] = []

    private var transform: Transform = Transform()
    
    var position: float3 {
        get { return transform.position }
        set { transform.position = newValue }
    }
    
    var rotation: float3 {
        get { return transform.rotation }
        set { transform.rotation = newValue}
    }
    
    var quaternion: simd_quatf {
        get { return transform.quaternion }
        set { transform.quaternion = newValue}
    }
    
    var scale: float3 {
        get { return transform.scale }
        set { transform.scale = newValue}
    }

    var forwardVector: float3 {
        return transform.forwardVector
    }

    var rightVector: float3 {
        return transform.rightVector
    }
    
    var modelMatrix: float4x4 {
        return transform.modelMatrix
    }

    var worldTransform: float4x4 {
        if let parent = parent { return parent.worldTransform * self.modelMatrix }
        return modelMatrix
    }

    var worldForwardVector: float3 {
        guard let parent = parent else { return forwardVector }
        return (parent.worldTransform * float4(forwardVector, 1)).xyz
    }

    var worldRightVector: float3 {
        guard let parent = parent else { return rightVector }
        return (parent.worldTransform * float4(rightVector, 1)).xyz
    }

    var boundingBox = MDLAxisAlignedBoundingBox()
    var size: float3 {
        return boundingBox.maxBounds - boundingBox.minBounds
    }

    init(name: String) {
        self.name = name
    }

    func update(deltaTime: Float) {
        // override this
    }

    final func add(childNode: Node) {
      children.append(childNode)
      childNode.parent = self
    }

    final func remove(childNode: Node) {
        for child in childNode.children {
            child.parent = self
            children.append(child)
        }
        childNode.children = []
        guard let index = (children.firstIndex { $0 === childNode }) else { return }
        children.remove(at: index)
        childNode.parent = nil
    }
}

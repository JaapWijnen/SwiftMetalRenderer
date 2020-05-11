#include <metal_stdlib>
#import "Shared.h"
using namespace metal;

struct VertexIn {
     float4 position [[ attribute(0) ]];
};

vertex float4 vertex_depth(const VertexIn vertexIn [[ stage_in ]],
                           constant ModelConstants &modelConstants [[ buffer(BufferIndexModelConstants) ]],
                           constant SceneConstants &sceneConstants [[ buffer(BufferIndexSceneConstants) ]]) {
    float4x4 mvp = sceneConstants.projectionMatrix * sceneConstants.viewMatrix * modelConstants.modelMatrix;
    float4 position = mvp * vertexIn.position;
    return position;
}

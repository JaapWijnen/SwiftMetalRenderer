#include <metal_stdlib>
#import "Shared.h"
using namespace metal;

struct VertexIn {
    float4 position [[ attribute(Position) ]];
    float3 normal [[ attribute(Normal)]];
    float2 uv [[ attribute(UV) ]];
    float3 tangent [[ attribute(Tangent) ]];
    float3 bitangent [[ attribute(Bitangent) ]];
};

struct VertexOut {
    float4 position [[ position ]];
    float3 worldPosition;
    float3 worldNormal;
    float3 worldTangent;
    float3 worldBitangent;
    float2 uv;
    float4 shadowPosition;
};

vertex VertexOut vertex_main(const VertexIn vertexIn [[ stage_in ]],
                             constant ModelConstants &modelConstants [[ buffer(BufferIndexModelConstants) ]],
                             constant SceneConstants &sceneConstants [[ buffer(BufferIndexSceneConstants) ]])
{
    VertexOut out;
    float4x4 mvp = sceneConstants.projectionMatrix * sceneConstants.viewMatrix * modelConstants.modelMatrix;
    out.position = mvp * vertexIn.position;
    out.worldPosition = (modelConstants.modelMatrix * vertexIn.position).xyz;
    out.worldNormal = normalize((modelConstants.modelMatrix * float4(vertexIn.normal, 0)).xyz);
    out.worldTangent = normalize((modelConstants.modelMatrix * float4(vertexIn.tangent, 0)).xyz);
    out.worldBitangent = normalize((modelConstants.modelMatrix * float4(vertexIn.bitangent, 0)).xyz);
    out.shadowPosition = sceneConstants.shadowMatrix * modelConstants.modelMatrix * vertexIn.position;
    out.uv = vertexIn.uv;
    return out;
}

struct Textures {
    texture2d<float> baseColor;
    texture2d<float> normal;
    texture2d<float> roughness;
    texture2d<float> metallic;
    texture2d<float> ao;
};

struct MaterialTextures {
    texture2d<float> albedo             [[ id(MaterialIndexAlbedo) ]];
    texture2d<float> normal             [[ id(MaterialIndexNormal) ]];
    texture2d<float> roughness          [[ id(MaterialIndexRoughness) ]];
    texture2d<float> metallic           [[ id(MaterialIndexMetallic) ]];
    texture2d<float> ao                 [[ id(MaterialIndexAO) ]];
    
    bool hasAlbedo                      [[ id(MaterialIndexHasAlbedo) ]];
    bool hasNormal                      [[ id(MaterialIndexHasNormal) ]];
    bool hasRoughness                   [[ id(MaterialIndexHasRoughness) ]];
    bool hasMetallic                    [[ id(MaterialIndexHasMetallic) ]];
    bool hasAO                          [[ id(MaterialIndexHasAO) ]];
    
};

struct GbufferOut {
    float4 albedo [[ color(0) ]];
    float4 normal [[ color(1) ]];
    float4 position [[ color(2) ]];
    float4 metallicRoughnessAO [[ color(3) ]];
};

/*fragment GbufferOut gBufferFragment(VertexOut in [[ stage_in ]],
                                    depth2d<float> shadowTexture [[ texture(ShadowTexture) ]],
                                    constant Material &material [[ buffer(BufferIndexMaterials) ]],
                                    constant Textures &textures [[ buffer(BufferIndexTextures) ]])
{
    GbufferOut out;
    //out.albedo = float4(material.baseColor, 1.0);
    constexpr sampler s1(min_filter::linear, mag_filter::linear);
    out.albedo = textures.baseColor.sample(s1, in.uv);
    out.albedo.a = 0;
    out.normal = float4(normalize(in.worldNormal), 1.0);
    out.position = float4(in.worldPosition, 1.0);
    float2 xy = in.shadowPosition.xy;
    xy = xy * 0.5 + 0.5;
    xy.y = 1 - xy.y;
    constexpr sampler s(coord::normalized, filter::linear, address::clamp_to_edge, compare_func:: less);

    const int neighborWidth = 3;
    const float neighbors = (neighborWidth * 2.0 + 1.0) *
                            (neighborWidth * 2.0 + 1.0);
    float mapSize = 4096;
    float texelSize = 1.0 / mapSize;
    float total = 0.0;
    for (int x = -neighborWidth; x <= neighborWidth; x++) {
      for (int y = -neighborWidth; y <= neighborWidth; y++) {
        float shadow_sample = shadowTexture.sample(
                                    s, xy + float2(x, y) * texelSize);
        float current_sample = in.shadowPosition.z / in.shadowPosition.w;
        if (current_sample > shadow_sample ) {
          total += 1.0;
        }
      }
    }
    total /= neighbors;
    float lightFactor = 1.0 - (total * in.shadowPosition.w);
    out.albedo.a = lightFactor;

    return out;
}*/

fragment GbufferOut fragment_mainPBR(VertexOut in [[stage_in]],
                                 depth2d<float> shadowTexture [[ texture(ShadowTexture) ]],
                                 constant Material &material [[buffer(BufferIndexMaterials)]],
                                 constant FragmentUniforms &fragmentUniforms [[buffer(BufferIndexFragmentUniforms)]],
                                 constant MaterialTextures &textures [[ buffer(BufferIndexTextures) ]]){
    
    constexpr sampler textureSampler(min_filter::linear, mag_filter::linear);
    //constexpr sampler shadowSampler(coord::normalized, filter::linear, address::clamp_to_edge, compare_func:: less);
    
    GbufferOut out;
    
    // extract color
    float3 albedo;
    if (textures.hasAlbedo) {
        albedo = textures.albedo.sample(textureSampler,
                                           in.uv * fragmentUniforms.tiling).rgb;
    } else {
        albedo = material.baseColor;
    }
    out.albedo = float4(albedo, 0);
    
    // extract metallic
    float metallic;
    if (textures.hasMetallic) {
        metallic = textures.metallic.sample(textureSampler, in.uv * fragmentUniforms.tiling).b;
    } else {
        metallic = material.metallic;
    }
    // extract roughness
    float roughness;
    if (textures.hasRoughness) {
        roughness = textures.roughness.sample(textureSampler, in.uv * fragmentUniforms.tiling).g;
    } else {
        roughness = material.roughness;
    }
    // extract ambient occlusion
    float ambientOcclusion;
    if (textures.hasAO) {
        ambientOcclusion = textures.ao.sample(textureSampler, in.uv * fragmentUniforms.tiling).r;
    } else {
        ambientOcclusion = 1.0;
    }
    
    out.metallicRoughnessAO = float4(metallic, roughness, ambientOcclusion, 1);
  
    // normal map
    float3 normal;
    if (textures.hasNormal) {
        float3 normalValue = textures.normal.sample(textureSampler, in.uv * fragmentUniforms.tiling).xyz * 2.0 - 1.0;
        normal = in.worldTangent * normalValue.x + in.worldBitangent * normalValue.y + in.worldNormal * normalValue.z;
    } else {
        normal = in.worldNormal;
    }
    normal = normalize(normal);
    out.normal = float4(normal, 1);
    
    out.position = float4(in.worldPosition, 1);
    
    return out;
}

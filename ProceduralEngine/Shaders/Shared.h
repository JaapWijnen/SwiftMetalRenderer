//
//  Shared.h
//  ProceduralEngine
//
//  Created by Jaap on 10/03/2020.
//  Copyright © 2020 workmoose. All rights reserved.
//

#ifndef Shared_h
#define Shared_h

#import <simd/simd.h>

typedef struct {
    matrix_float4x4 modelMatrix;
} ModelConstants;

typedef struct {
    matrix_float4x4 viewMatrix;
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 shadowMatrix;
} SceneConstants;

typedef struct {
    uint lightCount;
    vector_float3 cameraPosition;
    uint tiling;
} FragmentUniforms;

typedef enum {
    unused = 0,
    sunLight = 1,
    spotLight = 2,
    pointLight = 3,
    ambientLight = 4
} LightType;

typedef enum {
    Position = 0,
    Normal = 1,
    UV = 2,
    Tangent = 3,
    Bitangent = 4,
    Color = 5,
    Joints = 6,
    Weights = 7
} Attributes;

typedef struct {
    vector_float3 position;
    vector_float3 color;
    vector_float3 specularColor;
    float intensity;
    vector_float3 attenuation;
    LightType type;
    float coneAngle;
    vector_float3 coneDirection;
    float coneAttenuation;
} LightData;

typedef struct {
    vector_float3 baseColor;
    vector_float3 specularColor;
    float roughness;
    float metallic;
    vector_float3 ambientOcclusion;
    float shininess;
} Material;

typedef enum {
    BaseColorTexture = 0,
    NormalTexture = 1,
    RoughnessTexture = 2,
    MetallicTexture = 3,
    AOTexture = 4,
    ShadowTexture = 5,
    GBAlbedoTexture = 6,
    GBNormalTexture = 7,
    GBPositionTexture = 8
} TextureIndices;

typedef enum {
    BufferIndexVertices = 0,
    BufferIndexTextures = 5,
    BufferIndexSceneConstants = 11,
    BufferIndexModelConstants = 12,
    BufferIndexLights = 13,
    BufferIndexFragmentUniforms = 14,
    BufferIndexMaterials = 15,
    BufferIndexInstances = 16,
    BufferIndexSkybox = 20,
    BufferIndexSkyboxDiffuse = 21,
    BufferIndexBRDFLut = 22
} BufferIndices;

#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type

typedef NS_ENUM(int32_t, MaterialIndex)
{
    MaterialIndexAlbedo,
    MaterialIndexNormal,
    MaterialIndexRoughness,
    MaterialIndexMetallic,
    MaterialIndexAO,
    MaterialIndexHasAlbedo,
    MaterialIndexHasNormal,
    MaterialIndexHasRoughness,
    MaterialIndexHasMetallic,
    MaterialIndexHasAO
};

#endif /* Shared_h */

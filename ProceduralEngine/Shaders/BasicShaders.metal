//
//  BasicShaders.metal
//  ProceduralEngine
//
//  Created by Jaap on 09/03/2020.
//  Copyright © 2020 workmoose. All rights reserved.
//

#include <metal_stdlib>
#import "Shared.h"
using namespace metal;



/*float3 diffuseLighting(float3 normal,
                       float3 position,
                       constant FragmentUniforms &fragmentUniforms,
                       constant LightData *lights,
                       float3 baseColor) {
    float3 diffuseColor = 0;
    float3 normalDirection = normalize(normal);
    for (uint i = 0; i < fragmentUniforms.lightCount; i++) {
        LightData light = lights[i];
        if (light.type == 1) { // sunlight
            float3 lightDirection = normalize(light.position);
            float diffuseIntensity = saturate(dot(lightDirection, normalDirection));
            diffuseColor += light.color * light.intensity * baseColor * diffuseIntensity;
        } else if (light.type == 3) { //pointLight
              float d = distance(light.position, position);
              float3 lightDirection = normalize(light.position - position);
              float attenuation = 1.0 / (light.attenuation.x + light.attenuation.y * d + light.attenuation.z * d * d);
              float diffuseIntensity = saturate(dot(lightDirection, normalDirection));
              float3 color = light.color * baseColor * diffuseIntensity;
              color *= attenuation;
              diffuseColor += color;
        } else if (light.type == 2) { //spotLight
            float d = distance(light.position, position);
            float3 lightDirection = normalize(light.position - position);
            float3 coneDirection = normalize(-light.coneDirection);
            float spotResult = (dot(lightDirection, coneDirection));
            if (spotResult > cos(light.coneAngle)) {
                float attenuation = 1.0 / (light.attenuation.x + light.attenuation.y * d + light.attenuation.z * d * d);
                attenuation *= pow(spotResult, light.coneAttenuation);
                float diffuseIntensity = saturate(dot(lightDirection, normalDirection));
                float3 color = light.color * baseColor * diffuseIntensity;
                color *= attenuation;
                diffuseColor += color;
            }
        }
    }
    return diffuseColor;
}

fragment float4 fragment_main(VertexOut in [[ stage_in ]],
                              constant FragmentUniforms &fragmentUniforms [[ buffer(3)]],
                              constant LightData *lights [[ buffer(2)]],
                              constant Material &material [[ buffer(1) ]],
                              depth2d<float> shadowTexture [[ texture(0) ]])
{
    float3 baseColor = material.baseColor;
    float3 diffuseColor = diffuseLighting(in.worldNormal, in.worldPosition, fragmentUniforms, lights, baseColor);
    float2 xy = in.shadowPosition.xy;
    xy = xy * 0.5 + 0.5;
    xy.y = 1 - xy.y;
    constexpr sampler s(coord::normalized, filter::linear,
                        address::clamp_to_edge, compare_func:: less);
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
    return float4(diffuseColor * lightFactor, 1);
}
*/

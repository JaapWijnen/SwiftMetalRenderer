#include <metal_stdlib>
#import "Shared.h"
using namespace metal;

constant float pi = 3.1415926535897932384626433832795;

struct VertexOut {
  float4 position [[ position ]];
  float2 texCoords;
};

vertex VertexOut compositionVert(
                                 constant float2 *quadVertices [[buffer(0)]],
                                 constant float2 *quadTexCoords [[buffer(1)]],
                                 uint id [[vertex_id]])
{
    VertexOut out;
    out.position = float4(quadVertices[id], 0.0, 1.0);
    out.texCoords = quadTexCoords[id];
    return out;
}

float3 compositeLighting(float3 normal,
                         float3 position,
                         constant FragmentUniforms &fragmentUniforms,
                         constant LightData *lights,
                         float3 baseColor) {
    float3 diffuseColor = 0;
    float3 normalDirection = normalize(normal);
    for (uint i = 0; i < fragmentUniforms.lightCount; i++) {
        LightData light = lights[i];
        if (light.type == sunLight) {
            float3 lightDirection = normalize(light.position);
            float diffuseIntensity = saturate(dot(lightDirection, normalDirection));
            diffuseColor += light.color * light.intensity * baseColor * diffuseIntensity;
        } else if (light.type == pointLight) {
            float d = distance(light.position, position);
            float3 lightDirection = normalize(light.position - position);
            float attenuation = 1.0 / (light.attenuation.x + light.attenuation.y * d + light.attenuation.z * d * d);
            float diffuseIntensity = saturate(dot(lightDirection, normalDirection));
            float3 color = light.color * baseColor * diffuseIntensity;
            color *= attenuation;
            diffuseColor += color;
        } else if (light.type == spotLight) {
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

struct GBufferTextures {
    texture2d<float> albedoTexture;
    texture2d<float> normalTexture;
    texture2d<float> positionTexture;
    texture2d<float> metallicRoughnessAOTexture;
};

typedef struct Lighting {
  float3 lightDirection;
  float3 viewDirection;
  float3 baseColor;
  float3 normal;
  float metallic;
  float roughness;
  float ambientOcclusion;
  float3 lightColor;
} Lighting;

float3 render(Lighting lighting);

fragment float4 compositionFrag2(VertexOut in [[stage_in]],
                                constant FragmentUniforms &fragmentUniforms [[ buffer(BufferIndexFragmentUniforms)]],
                                constant LightData *lightsBuffer [[buffer(BufferIndexLights)]],
                                constant GBufferTextures &textures [[ buffer(5) ]],
                                depth2d<float> shadowTexture [[ texture(ShadowTexture) ]])
{
    constexpr sampler s(min_filter::linear, mag_filter::linear);
    float4 albedo = textures.albedoTexture.sample(s, in.texCoords);
    float3 normal = textures.normalTexture.sample(s, in.texCoords).xyz;
    float3 position = textures.positionTexture.sample(s, in.texCoords).xyz;
    float3 metallicRoughnessAO = textures.metallicRoughnessAOTexture.sample(s, in.texCoords).xyz;
    float metallic = metallicRoughnessAO.r;
    float roughness = metallicRoughnessAO.g;
    float ambientOcclusion = metallicRoughnessAO.b;
    float3 baseColor = albedo.rgb;
    //float3 diffuseColor = compositeLighting(normal, position, fragmentUniforms, lightsBuffer, baseColor);
    //float lightFactor = albedo.a;
    //return float4(diffuseColor * lightFactor, 1);
    
    float3 viewDirection = normalize(fragmentUniforms.cameraPosition - position);

    LightData light = lightsBuffer[0];
    float3 lightDirection = normalize(light.position);

    // all the necessary components are in place
    Lighting lighting;
    lighting.lightDirection = lightDirection;
    lighting.viewDirection = viewDirection;
    lighting.baseColor = baseColor;
    lighting.normal = normal;
    lighting.metallic = metallic;
    lighting.roughness = roughness;
    lighting.ambientOcclusion = ambientOcclusion;
    lighting.lightColor = light.color;

    float3 specularOutput = render(lighting);
    // compute Lambertian diffuse
    float nDotl = max(0.001, saturate(dot(lighting.normal, lighting.lightDirection)));
    // rescale from -1 : 1 to 0.3 - 1 to lighten shadows
    // nDotl = ((nDotl + 1) / (1 + 1)) * (1 - 0.3) + 0.3;
    float3 diffuseColor = light.color * baseColor * nDotl * ambientOcclusion;
    diffuseColor *= 1.0 - metallic;
    float4 finalColor = float4(specularOutput + diffuseColor, 1.0);
    return finalColor;
}


float3 render(Lighting lighting) {
    // Rendering equation courtesy of Apple et al.
    float nDotl = max(0.001, saturate(dot(lighting.normal, lighting.lightDirection)));
    float3 halfVector = normalize(lighting.lightDirection + lighting.viewDirection);
    float nDoth = max(0.001, saturate(dot(lighting.normal, halfVector)));
    float nDotv = max(0.001, saturate(dot(lighting.normal, lighting.viewDirection)));
    float hDotl = max(0.001, saturate(dot(lighting.lightDirection, halfVector)));

    // specular roughness
    float specularRoughness = lighting.roughness * (1.0 - lighting.metallic) + lighting.metallic;

    // Distribution
    float Ds;
    if (specularRoughness >= 1.0) {
        Ds = 1.0 / pi;
    }
    else {
        float roughnessSqr = specularRoughness * specularRoughness;
        float d = (nDoth * roughnessSqr - nDoth) * nDoth + 1;
        Ds = roughnessSqr / (pi * d * d);
    }
  
    // Fresnel
    float3 Cspec0 = float3(1.0);
    float fresnel = pow(clamp(1.0 - hDotl, 0.0, 1.0), 5.0);
    float3 Fs = float3(mix(float3(Cspec0), float3(1), fresnel));

    // Geometry
    float alphaG = (specularRoughness * 0.5 + 0.5) * (specularRoughness * 0.5 + 0.5);
    float a = alphaG * alphaG;
    float b1 = nDotl * nDotl;
    float b2 = nDotv * nDotv;
    float G1 = (float)(1.0 / (b1 + sqrt(a + b1 - a*b1)));
    float G2 = (float)(1.0 / (b2 + sqrt(a + b2 - a*b2)));
    float Gs = G1 * G2;

    float3 specularOutput = (Ds * Gs * Fs * lighting.lightColor) * (1.0 + lighting.metallic * lighting.baseColor) + lighting.metallic * lighting.lightColor * lighting.baseColor;
    specularOutput = specularOutput * lighting.ambientOcclusion;

    return specularOutput;
}

inline float distributionGGX(float3 normal, float3 H, float roughness) {
    float a      = roughness*roughness;
    float a2     = a*a;
    float NdotH  = max(dot(normal, H), 0.0);
    float NdotH2 = NdotH*NdotH;
    
    float num   = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = pi * denom * denom;
    
    return num / denom;
}

inline float GeometrySchlickGGX(float NdotV, float roughness) {
    float r = (roughness + 1.0);
    float k = (r*r) / 8.0;

    float num   = NdotV;
    float denom = NdotV * (1.0 - k) + k;
    
    return num / denom;
}

inline float GeometrySmith(float3 normal, float3 viewDirection, float3 lightDirection, float roughness) {
    float NdotV = max(dot(normal, viewDirection), 0.0);
    float NdotL = max(dot(normal, lightDirection), 0.0);
    float ggx2  = GeometrySchlickGGX(NdotV, roughness);
    float ggx1  = GeometrySchlickGGX(NdotL, roughness);
    
    return ggx1 * ggx2;
}

fragment float4 compositionFrag(VertexOut in [[stage_in]],
                                constant FragmentUniforms &fragmentUniforms [[ buffer(BufferIndexFragmentUniforms)]],
                                constant LightData *lightsBuffer [[buffer(BufferIndexLights)]],
                                constant GBufferTextures &textures [[ buffer(5) ]],
                                depth2d<float> shadowTexture [[ texture(ShadowTexture) ]])
{
    constexpr sampler s(min_filter::linear, mag_filter::linear);
    float4 albedo = textures.albedoTexture.sample(s, in.texCoords);
    float3 normal = textures.normalTexture.sample(s, in.texCoords).xyz;
    float3 position = textures.positionTexture.sample(s, in.texCoords).xyz;
    float3 metallicRoughnessAO = textures.metallicRoughnessAOTexture.sample(s, in.texCoords).xyz;
    float metallic = metallicRoughnessAO.r;
    float roughness = metallicRoughnessAO.g;
    float ambientOcclusion = metallicRoughnessAO.b;
    float3 baseColor = albedo.rgb;
    
    float3 viewDirection = normalize(fragmentUniforms.cameraPosition - position);
        
    float3 F0 = float3(0.2, 0.2, 0.2);
    F0 = mix(F0, baseColor, metallic);
    
    float3 result = float3(0, 0, 0);
    for(uint i = 0; i < fragmentUniforms.lightCount; i++){
        LightData light = lightsBuffer[i];
        
        #warning not a sun then?
        float3 lightDirection = normalize(light.position - position);
        float3 H = normalize(viewDirection + lightDirection);
        
        float NDF = distributionGGX(normal, H, roughness);
        float G = GeometrySmith(normal, viewDirection, lightDirection, roughness);
        
        #warning breaks when dot product == 1
        // breakdown of below single line for debug
        float dot_product = dot(H, viewDirection);
        float max_val = max(dot_product, 0.0);
        float one_minmax = 1.0 - max_val;
        float maxed = max(one_minmax, 0.0);
        float power_val = pow(maxed, 5.0);
        float3 one_minF0 = 1.0 - F0;
        float3 product_val = one_minF0 * power_val;
        float3 F = F0 + product_val;
        // original
        //float3 F = F0 + (1.0 - F0) * pow(1.0 - max(dot(H, viewDirection), 0.0), 5.0);
        
        float3 kS = F;
        float3 kD = float3(1.0) - kS;
        kD *= 1.0 - metallic;
        
        float3 numerator    = NDF * G * F;
        float denominator = 4 * max(dot(normal, viewDirection), 0.0) * max(dot(normal, lightDirection), 0.0) + 0.001; // 0.001 to prevent divide by zero.
        
        float3 specular     = numerator / denominator;
        
        float NdotL = max(dot(normal, lightDirection), 0.0);
        
        float radiance = 1.0;
        result += (kD * baseColor / pi + specular) * radiance * NdotL;
    }
    
    float3 color = baseColor + result;
    
    return float4(color * ambientOcclusion, 1);
}

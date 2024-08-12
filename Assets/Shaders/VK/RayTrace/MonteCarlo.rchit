/******************************************************************************
This file is part of the Newcastle Vulkan Tutorial Series

Author:Rich Davison
Contact:richgdavison@gmail.com
License: MIT (see LICENSE file at the top of the source tree)
*//////////////////////////////////////////////////////////////////////////////
#version 460
#extension GL_GOOGLE_include_directive		: enable
#extension GL_ARB_separate_shader_objects	: enable
#extension GL_ARB_shading_language_420pack	: enable
#extension GL_EXT_ray_tracing : require
#extension GL_EXT_ray_tracing_position_fetch : require
#extension GL_EXT_nonuniform_qualifier : enable

#include "RayStructs.glslh"
#include "SceneNode.glslh"
#include "cookTohorenceBrdf.glslh"

layout(location = 0) rayPayloadInEXT BasicPayload payload;

layout(set = 0, binding = 0) uniform accelerationStructureEXT tlas;

layout(binding = 0, set = 4) buffer VertexPositionBuffer 
{
    vec3 positions[];
} vertexPositionBuffer;

layout(binding = 1, set = 4) buffer IndexBuffer 
{
    int indices[];
} indicesBuffer;

layout(binding = 2, set = 4) buffer VertexTexCordBuffer 
{
    vec2 textureCoords[];
} vertexTexCoords;

layout(binding = 3, set = 4) buffer VertexNormalBuffer 
{
    vec3 normals[];
} vertexNormals;

layout(binding = 4, set = 4) buffer VertexTangentBuffer 
{
    vec4 tangents[];
} vertexTangents;

layout(binding  = 5, set = 4) uniform  texture2D textureMap[]; //Default Sampler descriptor
layout(binding = 6, set = 4) buffer MatlayerBuffer 
{
    GLTFMaterialLayer matLayerList[];
} matlayerBuffer;

layout(binding = 7, set = 4) buffer PrimInfoBuffer 
{
    GLTFPrimInfo primeInfoList[];
} primeInfoBuffer;

layout(binding = 8, set = 4) uniform PointLightInfo
{
    PointLightCpp pointLightList[10];
} pointLights;

layout(binding  = 0, set = 5) uniform sampler mySampler; //Default Sampler descriptor

hitAttributeEXT vec2 hitBarycentrics;

void main() 
{
    GLTFPrimInfo pinfo = primeInfoBuffer.primeInfoList[gl_InstanceCustomIndexEXT + gl_GeometryIndexEXT];

    // Getting the 'first index' for this mesh (offset of the mesh + offset of the triangle)
    uint indexOffset  = pinfo.indexOffset + (3 * gl_PrimitiveID);
    uint vertexOffset = pinfo.vertexOffset; 
    uint matIndex     = max(0, pinfo.materialLayerID);  // material of primitive mesh
    GLTFMaterialLayer material = matlayerBuffer.matLayerList[matIndex];
  
    ivec3 index = ivec3(
        indicesBuffer.indices[0 + indexOffset],
        indicesBuffer.indices[1 + indexOffset],
        indicesBuffer.indices[2 + indexOffset]);
    index += ivec3(vertexOffset);


    const vec3 barycentrics = vec3(
        1 - hitBarycentrics.x - hitBarycentrics.y,
        hitBarycentrics.x,
        hitBarycentrics.y);// (w,u,v)

    const vec2 uv0 = vertexTexCoords.textureCoords[index.x];
    const vec2 uv1 = vertexTexCoords.textureCoords[index.y];
    const vec2 uv2 = vertexTexCoords.textureCoords[index.z];

    // Vertex Position of the triangle
    const vec3 pos0 = vertexPositionBuffer.positions[index.x];
    const vec3 pos1 = vertexPositionBuffer.positions[index.y];
    const vec3 pos2 = vertexPositionBuffer.positions[index.z];

    // Vertex Normal of the triangle
    const vec3 nrm0 = vertexNormals.normals[index.x];
    const vec3 nrm1 = vertexNormals.normals[index.y];
    const vec3 nrm2 = vertexNormals.normals[index.z];

    const vec4 t0 = vertexTangents.tangents[index.x];
    const vec4 t1 = vertexTangents.tangents[index.x];
    const vec4 t2 = vertexTangents.tangents[index.x];

    //https://computergraphics.stackexchange.com/questions/7738/how-to-assign-calculate-triangle-texture-coordinates
    const vec2 texCoord = (uv0 * barycentrics.x) +
                          (uv1 * barycentrics.y) +
                          (uv2 * barycentrics.z);

    const vec3 position = (pos0 * barycentrics.x) +
                          (pos1 * barycentrics.y) +
                          (pos2 * barycentrics.z);
    const vec3 vertexNormal = (nrm0 * barycentrics.x) +
                              (nrm1 * barycentrics.y) +
                              (nrm2 * barycentrics.z);

    const vec4 vertexTangent = vec4((t0 * barycentrics.x) +
                                    (t1 * barycentrics.y) +
                                    (t2 * barycentrics.z));

    const vec3 world_position = vec3( gl_ObjectToWorldEXT * vec4(position, 1.0));
    const vec3 normal = GetNormalFromTexture(
        texture(sampler2D(textureMap[material.bumpId], mySampler), texCoord).rgb,
        vertexNormal,
        vertexTangent
    );
    const vec4 albedoTex = texture(sampler2D(textureMap[material.albedoId], mySampler), texCoord);
    const vec3 metalicRoughnessTex = texture(sampler2D(textureMap[material.metallicRoughnessId], mySampler), texCoord).xyz;
    const vec4 emmissionTex = texture(sampler2D(textureMap[material.emissionId], mySampler), texCoord);
    const float roughness = metalicRoughnessTex.g;
    const float metal = metalicRoughnessTex.b;

    vec4 lightOut = vec4(0.0f, 0.0f, 0.0f, 0.0f);
    PointLight pointLight;

    for(int i = 0; i < 10; i++)
    {
        pointLight.position = pointLights.pointLightList[i].position;
        pointLight.color = pointLights.pointLightList[i].color;
        pointLight.radius = pointLights.pointLightList[i].radius;

        const vec3 L = normalize(pointLight.position - world_position);
        const vec3 V = normalize(gl_WorldRayDirectionEXT);
        const float lightDistance = length(pointLight.position - world_position);

        const vec3 brdf = MicrofacetSpecularBrdf(metal, roughness, albedoTex.rgb,  normal, L, V);
        const float attenuation = PointLightAttenuation(lightDistance, pointLight.radius);
        const vec3 radiance = pointLight.color.rgb;
        
        lightOut += vec4(brdf, albedoTex.a) *
                vec4(radiance, albedoTex.a) *
                clamp(dot(L, normal), 0.0f, 1.0f);
        // lightOut *= attenuation; TODO attenuation is 0
    }   
    payload.hitValue = lightOut + emmissionTex;
}
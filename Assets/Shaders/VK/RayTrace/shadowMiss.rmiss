#version 460
#extension GL_GOOGLE_include_directive		: enable
#extension GL_ARB_separate_shader_objects	: enable
#extension GL_ARB_shading_language_420pack	: enable
#extension GL_EXT_ray_tracing : require

#include "RayStructs.glslh"

layout(location = 0) rayPayloadInEXT BasicPayload payload;

void main() 
{
    payload.isShadow = true;
}
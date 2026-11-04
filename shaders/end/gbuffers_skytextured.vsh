#version 330 compatibility
#include "/lib/settings.glsl"
#if defined(DETAILED_SKY) || defined(END_MIST)
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
out vec3 vRay;
#endif
#ifndef DETAILED_SKY
out vec2 vUV;
out vec4 vColor;
#endif
void main() {
    gl_Position = ftransform();
#if defined(DETAILED_SKY) || defined(END_MIST)
    vec3 ray = (gbufferProjectionInverse * vec4(gl_Position.xy, gl_Position.ww)).xyz;
    vRay = mat3(gbufferModelViewInverse) * ray;
#endif
#ifndef DETAILED_SKY
    vUV = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vColor = gl_Color;
#endif
}

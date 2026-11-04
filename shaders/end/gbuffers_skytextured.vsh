#version 330 compatibility
#include "/lib/settings.glsl"
#ifdef DETAILED_SKY
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
out vec3 vRay;
#else
out vec2 vUV;
out vec4 vColor;
#endif
void main() {
    gl_Position = ftransform();
#ifdef DETAILED_SKY
    vec3 ray = (gbufferProjectionInverse * vec4(gl_Position.xy, gl_Position.ww)).xyz;
    vRay = mat3(gbufferModelViewInverse) * ray;
#else
    vUV = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vColor = gl_Color;
#endif
}

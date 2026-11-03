#version 330 compatibility
#include "/lib/settings.glsl"
out vec2 vUV;
out vec4 vColor;
#if CLOUD_STYLE > 0
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
out vec3 vRay;
#endif
void main() {
    gl_Position = ftransform();
    vUV = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vColor = gl_Color;
#if CLOUD_STYLE > 0
    vec3 viewRay = (gbufferProjectionInverse * vec4(gl_Position.xy, gl_Position.ww)).xyz;
    vRay = mat3(gbufferModelViewInverse) * viewRay;
#endif
}

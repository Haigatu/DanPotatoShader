#version 330 compatibility
#include "/lib/settings.glsl"
#ifdef ROUND_DISKS
uniform int renderStage;
out vec2 vDiskUV;
#endif
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
#ifdef ROUND_DISKS
    // The game's moon UVs already select the current phase in a 4 by 2 grid.
    vDiskUV = renderStage == MC_RENDER_STAGE_MOON ? vUV*vec2(4.0,2.0)
             : vUV+vec2(0.0,2.0);
#endif
#if CLOUD_STYLE > 0
    vec3 viewRay = (gbufferProjectionInverse * vec4(gl_Position.xy, gl_Position.ww)).xyz;
    vRay = mat3(gbufferModelViewInverse) * viewRay;
#endif
}

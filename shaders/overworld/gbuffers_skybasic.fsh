#version 330 compatibility
#include "/lib/sky.glsl"
uniform int renderStage;
uniform int isEyeInWater;
uniform float blindness;
in vec3 vRay;
flat in vec3 vSun;
flat in vec3 vUp;
flat in float vLowSun;
in vec4 vColor;
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 sky;

void main() {
    if (renderStage == MC_RENDER_STAGE_STARS || renderStage == MC_RENDER_STAGE_SUNSET
            || renderStage == MC_RENDER_STAGE_VOID) {
        sky = vColor;
    } else if (isEyeInWater != 0) {
        sky = vec4(fogColor, 1.0);
    } else {
        vec3 ray = normalize(vRay);
        vec3 color = paintedSky(dot(ray, vUp), dot(ray, vSun), vLowSun);
        sky = vec4(mix(color, fogColor, clamp(blindness, 0.0, 1.0)), 1.0);
    }
}

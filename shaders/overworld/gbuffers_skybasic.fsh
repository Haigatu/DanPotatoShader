#version 330 compatibility
#include "/lib/settings.glsl"
#include "/lib/sky.glsl"
uniform int renderStage;
uniform int isEyeInWater;
uniform float blindness;
in vec3 vRay;
flat in vec3 vSun;
flat in float vLowSun;
in vec4 vColor;
const float sunPathRotation = -28.0;
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 sky;
void main() {
    if (renderStage == MC_RENDER_STAGE_STARS || renderStage == MC_RENDER_STAGE_VOID) {
        sky = vColor;
#if CLOUD_STYLE > 0
        if (renderStage == MC_RENDER_STAGE_STARS) sky.rgb *= 1.0 - cloudCover(normalize(vRay), rainStrength);
#endif
    } else if (renderStage == MC_RENDER_STAGE_SUNSET) {
        // The main sky already contains the low-sun belt. Retain a little vanilla glow.
        sky = vec4(vColor.rgb, vColor.a * 0.22);
    } else if (isEyeInWater != 0) {
        sky = vec4(fogColor, 1.0);
    } else {
        vec3 color = paintedSky(normalize(vRay), vSun, vLowSun, vec3(0.0), 0.0);
        sky = vec4(mix(color, fogColor, clamp(blindness, 0.0, 1.0)), 1.0);
    }
}

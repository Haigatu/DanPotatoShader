#version 330 compatibility
#include "/lib/settings.glsl"
uniform sampler2D gtexture;
uniform float alphaTestRef;
in vec2 vUV;
in vec4 vColor;
#ifdef ROUND_DISKS
uniform int renderStage;
uniform sampler2D celestialAtlas;
in vec2 vDiskUV;
#endif
#if CLOUD_STYLE > 0
#include "/lib/weather_uniforms.glsl"
#include "/lib/clouds.glsl"
uniform float rainStrength;
in vec3 vRay;
#endif
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 disk;
void main() {
#ifdef ROUND_DISKS
    if (renderStage == MC_RENDER_STAGE_SUN || renderStage == MC_RENDER_STAGE_MOON) {
        disk = texture(celestialAtlas,vDiskUV) * vColor;
    } else
#endif
    {
        disk = texture(gtexture,vUV) * vColor;
    }
    if (disk.a < max(alphaTestRef,0.001)) discard;
#if CLOUD_STYLE > 0
    disk.rgb *= 1.0 - cloudCover(normalize(vRay), rainStrength);
#endif
}

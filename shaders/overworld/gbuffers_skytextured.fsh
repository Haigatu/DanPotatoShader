#version 330 compatibility
#include "/lib/settings.glsl"
uniform sampler2D gtexture;
uniform float alphaTestRef;
in vec2 vUV;
in vec4 vColor;
#if CLOUD_STYLE > 0
#include "/lib/weather_uniforms.glsl"
#include "/lib/clouds.glsl"
uniform float rainStrength;
in vec3 vRay;
#endif
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 disk;
void main() {
    disk = texture(gtexture, vUV) * vColor;
    if (disk.a < alphaTestRef) discard;
#if CLOUD_STYLE > 0
    disk.rgb *= 1.0 - 0.96 * cloudCover(normalize(vRay), rainStrength);
#endif
}

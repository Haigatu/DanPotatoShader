#include "/lib/settings.glsl"
uniform vec3 fogColor;
uniform float fogStart;
uniform float fogEnd;
in vec4 vColor;
in float vFogDistance;
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 scene;
void main() {
#if CUSTOM_CLOUDS == 1 && CLOUD_STYLE > 0
    discard;
#else
    float fog = smoothstep(fogStart, max(fogEnd, fogStart + 0.001), vFogDistance);
    scene = vec4(mix(vColor.rgb, fogColor, fog), vColor.a);
#endif
}

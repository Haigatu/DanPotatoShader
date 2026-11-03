uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform vec3 fogColor;
uniform float fogStart;
uniform float fogEnd;
uniform float alphaTestRef;
#if APPLY_OVERLAY == 1
uniform vec4 entityColor;
#endif
in vec2 vUV;
in vec2 vLightUV;
in vec4 vColor;
in float vFogDistance;
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 scene;
void main() {
    scene = texture(gtexture, vUV) * vColor;
    if (scene.a < alphaTestRef) discard;
#if APPLY_OVERLAY == 1
    scene.rgb = mix(scene.rgb, entityColor.rgb, entityColor.a);
#endif
    scene.rgb *= texture(lightmap, vLightUV).rgb;
    float fog = clamp((vFogDistance - fogStart) / max(fogEnd - fogStart, 0.001), 0.0, 1.0);
    scene.rgb = mix(scene.rgb, fogColor, fog * fog * (3.0 - 2.0 * fog));
}

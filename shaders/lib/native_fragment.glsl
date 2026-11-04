uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform vec3 fogColor;
uniform float fogStart;
uniform float fogEnd;
uniform float alphaTestRef;
#if PORTAL_PASS == 1 && defined(PORTAL_DEPTH)
#include "/lib/portal.glsl"
#endif
#if END_HAZE == 1 || (END_PASS == 1 && defined(END_MIST))
uniform float blindness;
uniform float darknessFactor;
uniform int isEyeInWater;
#endif
#if END_PASS == 1 && defined(END_MIST)
in float vEndMist;
#include "/lib/end_mist.glsl"
#endif
#if ENTITY_PASS == 1 && defined(END_ENERGY)
#include "/lib/end_energy.glsl"
#endif
#if APPLY_OVERLAY == 1
uniform vec4 entityColor;
#endif
in vec2 vUV;
in vec2 vLightUV;
in vec4 vColor;
in float vFogDistance;
#if END_TERRAIN == 1 && defined(END_MATERIALS)
in vec2 vEndAccent;
#endif
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 scene;
void main() {
#if PORTAL_PASS == 1 && defined(PORTAL_DEPTH)
    if (blockEntityId == 10102) {
        vec3 portal = portalColor();
#if END_PASS == 1 && defined(END_MIST)
        float mistVisible = isEyeInWater == 0 ? 1.0 - max(blindness, darknessFactor) : 0.0;
        portal = mix(portal, endMistColor, vEndMist * mistVisible);
#endif
        scene = vec4(mix(portal, fogColor, smoothstep(fogStart, max(fogEnd, fogStart + 0.001), vFogDistance)), 1.0);
        return;
    }
#endif
    vec4 albedo = texture(gtexture, vUV);
    scene = albedo * vColor;
    if (scene.a < alphaTestRef) discard;
#if APPLY_OVERLAY == 1
    scene.rgb = mix(scene.rgb, entityColor.rgb, entityColor.a);
#endif
    scene.rgb *= texture(lightmap, vLightUV).rgb;
#if ENTITY_PASS == 1 && defined(END_ENERGY)
    endEnergy(scene.rgb, albedo, vUV);
#endif
#if END_TERRAIN == 1 && defined(END_MATERIALS)
    if (vEndAccent.x > 0.0) {
        float sheen = vEndAccent.x * (0.25 + 0.75 * smoothstep(0.02, 0.24, albedo.b));
        scene.rgb += sheen * vec3(0.105, 0.081, 0.16);
    } else if (vEndAccent.y > 0.0) {
        float tip = smoothstep(0.42, 0.82, albedo.g);
        scene.rgb = mix(scene.rgb, max(scene.rgb, albedo.rgb * vec3(0.96, 0.84, 1.0)), 0.82 * tip);
    }
#endif
    float fog = clamp((vFogDistance - fogStart) / max(fogEnd - fogStart, 0.001), 0.0, 1.0);
    fog = fog * fog * (3.0 - 2.0 * fog);
#if END_HAZE == 1 || (END_PASS == 1 && defined(END_MIST))
    float visible = isEyeInWater == 0 ? 1.0 - max(blindness, darknessFactor) : 0.0;
#endif
#if END_PASS == 1 && defined(END_MIST)
    scene.rgb = mix(scene.rgb, endMistColor, vEndMist * visible);
#endif
#if END_HAZE == 1
    // A violet haze leaves distant End stone and the darker towers distinguishable.
    // Use the game's fog again while submerged, blinded or affected by Darkness.
    vec3 endFog = mix(scene.rgb, vec3(.17,.125,.22), .62);
    scene.rgb = mix(scene.rgb, mix(fogColor,endFog,visible), fog);
#else
    scene.rgb = mix(scene.rgb, fogColor, fog);
#endif
}

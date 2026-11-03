#include "/lib/settings.glsl"
uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform float alphaTestRef;
uniform float fogStart;
uniform float fogEnd;
in vec2 vUV;
in vec2 vLightUV;
in vec4 vTint;
in float vFogDistance;
in vec3 vLighting;

#if SURFACE_KIND == 3
uniform vec4 entityColor;
#endif
#if SURFACE_KIND == 1
#ifdef COPPER_EDGE
in vec2 vEdge;
#endif
#endif
#ifdef CAST_SHADOWS
uniform sampler2DShadow shadowtex0;
in vec3 vShadow;
in float vShadowDistance;

float visibility() {
    vec3 p = vShadow;
    float border = min(min(p.x, 1.0 - p.x), min(p.y, 1.0 - p.y));
    float weight = smoothstep(0.0, 0.04, border)
                 * (1.0 - smoothstep(0.78 * shadowDistance, shadowDistance, vShadowDistance));
    if (weight <= 0.0 || p.z <= 0.0 || p.z >= 1.0 || vLighting.x < 0.003) return 1.0;
    return mix(1.0, texture(shadowtex0, vec3(p.xy, p.z - 0.00012)), weight);
}
#endif

#include "/lib/sky.glsl"
#if SURFACE_KIND == 2
flat in int vWater;
in float vWaterTop;
#ifdef WATER_RIPPLES
in vec2 vWavePhase;
#endif
#ifdef WATER_SKY
uniform int isEyeInWater;
uniform mat4 gbufferModelViewInverse;
uniform vec3 sunPosition;
in vec3 vWaterView;
in vec3 vWaterNormal;
in float vLowSun;
#endif

void shadeWater(inout vec4 surface) {
    surface.rgb *= vec3(0.89, 1.04, 1.015);
    vec2 slope = vec2(0.0);
#ifdef WATER_RIPPLES
    float strength = vWaterTop * (1.0 - smoothstep(18.0, 55.0, vFogDistance));
    vec2 waves = sin(vWavePhase) * strength;
    slope = vec2(waves.x * 0.045 - waves.y * 0.019, waves.y * 0.038 + waves.x * 0.014);
    surface.rgb *= 1.0 + dot(waves, vec2(0.035, 0.025));
#endif
#ifdef WATER_SKY
    if (isEyeInWater == 0 && vWaterTop > 0.0) {
        vec3 n = normalize(vWaterNormal + vec3(slope.x, 0.0, slope.y));
        vec3 incident = normalize(vWaterView);
        vec3 reflected = reflect(incident, n);
        vec3 sun = normalize(mat3(gbufferModelViewInverse) * sunPosition);
        float grazing = 1.0 - clamp(dot(-incident, n), 0.0, 1.0);
        float weight = (0.035 + 0.46 * grazing * grazing * grazing)
                     * smoothstep(0.48, 0.97, vLightUV.y) * vWaterTop;
        vec3 reflection = paintedSky(reflected.y, dot(reflected, sun), vLowSun);
        surface.rgb = mix(surface.rgb, reflection, weight);
        surface.a += (1.0 - surface.a) * weight;
    }
#endif
}
#endif

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 scene;
void main() {
    vec4 albedo = texture(gtexture, vUV) * vTint;
    if (albedo.a < alphaTestRef) discard;
#if SURFACE_KIND == 3
    albedo.rgb = mix(albedo.rgb, entityColor.rgb, entityColor.a);
#endif
    float visible = 1.0;
#ifdef CAST_SHADOWS
    visible = visibility();
#endif
    vec3 lamp = texture(lightmap, vLightUV).rgb;
    vec3 tint = vec3(1.0) - vLighting.y * vec3(0.11, 0.065, 0.005)
               + vLighting.x * visible * vec3(0.21, 0.125, 0.036)
               - vLighting.x * (1.0 - visible) * vec3(0.23, 0.21, 0.16)
               + vLighting.z * vec3(0.035, 0.0, -0.055);
    scene = vec4(albedo.rgb * lamp * tint, albedo.a);
#if SURFACE_KIND == 1
#ifdef COPPER_EDGE
    // Antialias the narrow strip and retire it before courses become subpixel.
    float span = max(fwidth(vEdge.x), 0.002);
    float stripe = smoothstep(0.90 - span, 0.96 + span, fract(vEdge.x));
    stripe *= 1.0 - smoothstep(0.035, 0.13, span);
    scene.rgb += stripe * vEdge.y * visible * lamp * vec3(0.19, 0.080, 0.025);
#endif
#endif
#if SURFACE_KIND == 2
    if (vWater != 0) shadeWater(scene);
#endif
    float fog = clamp((vFogDistance - fogStart) / max(fogEnd - fogStart, 0.001), 0.0, 1.0);
    scene.rgb = mix(scene.rgb, fogColor, fog * fog * (3.0 - 2.0 * fog));
}

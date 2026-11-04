#include "/lib/settings.glsl"
uniform sampler2D gtexture;
uniform float alphaTestRef;
uniform float fogStart;
uniform float fogEnd;
in vec2 vUV;
in vec4 vTint;
in vec3 vFill;
in vec3 vDirect;
in float vFogDistance;
in float vOutdoor;
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
    float border = min(min(vShadow.x, 1.0-vShadow.x), min(vShadow.y, 1.0-vShadow.y));
    float weight = smoothstep(0.0, 0.04, border)
                 * (1.0 - smoothstep(0.78 * shadowDistance, shadowDistance, vShadowDistance));
    if (weight <= 0.0 || vShadow.z <= 0.0 || vShadow.z >= 1.0 || vDirect.r < 0.003) return 1.0;
    return mix(1.0, texture(shadowtex0, vec3(vShadow.xy, vShadow.z - 0.00012)), weight);
}
#endif
#if SURFACE_KIND == 2 && defined(WATER_SKY)
#include "/lib/sky.glsl"
#else
uniform vec3 fogColor;
#endif
#if SURFACE_KIND == 2
flat in int vWater;
in float vWaterTop;
#ifdef WATER_RIPPLES
in vec2 vWavePhase;
#endif
#if defined(WATER_SKY) || defined(WATER_DEPTH)
uniform int isEyeInWater;
in vec3 vWaterView;
#endif
#ifdef WATER_SKY
in vec3 vWaterNormal;
flat in vec3 vWaterSun;
flat in float vLowSun;
#endif
#ifdef WATER_DEPTH
uniform sampler2D depthtex1;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
#endif
void shadeWater(inout vec4 surface, float visible) {
    float light = dot(vFill + vDirect * visible, vec3(0.28, 0.53, 0.19));
    float detail = dot(surface.rgb, vec3(0.20, 0.55, 0.25));
    // Blend a muted lake colour with the local biome tint.
    vec3 lake = vec3(0.030, 0.185, 0.21) * (0.68 + 0.78 * detail) * light;
    surface.rgb = mix(surface.rgb, lake, 0.76 * vOutdoor);
    surface.a += (1.0 - surface.a) * 0.36 * vOutdoor;
    vec2 slope = vec2(0.0);
#ifdef WATER_RIPPLES
    float strength = vWaterTop * (1.0 - smoothstep(26.0, 74.0, vFogDistance));
    vec2 waves = sin(vWavePhase + 0.61 * sin(vWavePhase.yx * vec2(0.50, 0.25)));
    slope = vec2(waves.x * 0.106 - waves.y * 0.045, waves.y * 0.089 + waves.x * 0.057) * strength;
    surface.rgb *= 1.0 + dot(waves, vec2(0.024, 0.016)) * strength;
#endif
#if defined(WATER_SKY) || defined(WATER_DEPTH)
    if (isEyeInWater != 0 || vWaterTop <= 0.0) return;
#endif
#ifdef WATER_DEPTH
    // local includes the inverse view translation. Measure from the projected eye.
    vec3 eyeRay = vWaterView - gbufferModelViewInverse[3].xyz;
    float rayLength = length(eyeRay);
    float d = texelFetch(depthtex1, ivec2(gl_FragCoord.xy), 0).r * 2.0 - 1.0;
    float backZ = -(gbufferProjectionInverse[2][2] * d + gbufferProjectionInverse[3][2])
                  / (gbufferProjectionInverse[2][3] * d + gbufferProjectionInverse[3][3]);
    float gap = max(backZ - 1.0 / gl_FragCoord.w, 0.0) * (rayLength * gl_FragCoord.w);
    float deep = gap / (1.8 + gap);
    surface.rgb = mix(surface.rgb + vec3(0.013, 0.065, 0.045)*light, surface.rgb * vec3(0.48, 0.66, 0.84), deep);
    surface.a = mix(surface.a * 0.55, min(0.91, surface.a + 0.34), deep);
#endif
#ifdef WATER_SKY
    if (vOutdoor > 0.005) {
        vec3 n = normalize(vWaterNormal + vec3(slope.x, 0.0, slope.y));
#ifdef WATER_DEPTH
        vec3 incident = eyeRay / rayLength;
#else
        vec3 incident = normalize(vWaterView);
#endif
        vec3 reflected = reflect(incident, n);
        float grazing = 1.0 - clamp(dot(-incident, n), 0.0, 1.0);
        float weight = (0.042 + 0.36 * grazing * grazing) * vOutdoor * vWaterTop;
        vec3 flatReflection = reflect(incident, normalize(vWaterNormal));
        // Warp the projected cloud footprint, keeping the horizon stable as waves tilt.
        vec3 footprint = vWaterView + vec3(slope.x, 0.0, slope.y) * (5.0 + 8.0 * grazing);
        vec3 sky = paintedSky(flatReflection, vWaterSun, vLowSun, footprint, 1.0);
        surface.rgb = mix(surface.rgb, sky, weight);
        surface.a += (1.0 - surface.a) * (0.55 * weight);
        float day = smoothstep(-0.10, 0.12, vWaterSun.y);
        vec3 emitter = day > 0.5 ? vWaterSun : -vWaterSun;
        float s = max(dot(reflected, emitter), 0.0);
        s *= s; s *= s; s *= s;
        float trail = s*s; trail *= trail;
        surface.rgb += mix(vec3(0.20, 0.31, 0.52), vec3(1.0, 0.80, 0.44), day) *
                       (0.055*s + 0.46*trail*trail) * vOutdoor * visible * (1.0-rainStrength) * vWaterTop;
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
    scene = vec4(albedo.rgb * (vFill + vDirect * visible), albedo.a);
#if SURFACE_KIND == 1
#ifdef COPPER_EDGE
    float span = max(fwidth(vEdge.x), 0.002);
    float stripe = smoothstep(0.90 - span, 0.96 + span, fract(vEdge.x));
    stripe *= 1.0 - smoothstep(0.035, 0.13, span);
    scene.rgb += stripe * vEdge.y * visible * vFill * vec3(0.31, 0.12, 0.040);
#endif
#endif
#if SURFACE_KIND == 2
    if (vWater != 0) shadeWater(scene, visible);
#endif
    float fog = clamp((vFogDistance - fogStart) / max(fogEnd - fogStart, 0.001), 0.0, 1.0);
    float air = 0.22 * vOutdoor * smoothstep(12.0, max(fogEnd, 28.0), vFogDistance);
    scene.rgb = mix(scene.rgb, fogColor, mix(air, 1.0, fog * fog * (3.0 - 2.0 * fog)));
}

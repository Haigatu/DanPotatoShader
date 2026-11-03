#include "/lib/settings.glsl"
#include "/lib/daylight.glsl"

uniform mat4 gbufferModelViewInverse;
uniform sampler2D lightmap;
uniform int fogShape;
#include "/lib/weather_uniforms.glsl"
#if CLOUD_STYLE == 2
#include "/lib/clouds.glsl"
#endif
#if SURFACE_KIND == 1
#ifdef FOLIAGE_WIND
in vec2 mc_midTexCoord;
uniform mat4 gbufferModelView;
#include "/lib/wind.glsl"
#endif
#endif

out vec2 vUV;
out vec4 vTint;
out vec3 vFill;
out vec3 vDirect;
out float vFogDistance;
out float vOutdoor;
#if SURFACE_KIND == 1 || SURFACE_KIND == 2
in vec4 mc_Entity;
#endif
#if SURFACE_KIND == 1
#ifdef COPPER_EDGE
out vec2 vEdge;
#endif
#endif
#ifdef CAST_SHADOWS
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 shadowLightPosition;
out vec3 vShadow;
out float vShadowDistance;
#endif

#if SURFACE_KIND == 2
flat out int vWater;
out float vWaterTop;
#ifdef WATER_SKY
out vec3 vWaterView;
out vec3 vWaterNormal;
flat out vec3 vWaterSun;
flat out float vLowSun;
#endif
#ifdef WATER_RIPPLES
out vec2 vWavePhase;
#endif
#endif

void main() {
    vec4 view = gl_ModelViewMatrix * gl_Vertex;
    vUV = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vec2 lightUV = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vTint = gl_Color;
    vec3 local = (gbufferModelViewInverse * view).xyz;
#if SURFACE_KIND == 1
#ifdef FOLIAGE_WIND
    int plant = int(mc_Entity.x);
    if (plant >= 10003 && plant <= 10006) {
        vec3 delta = windOffset(plant, local, step(gl_MultiTexCoord0.t, mc_midTexCoord.t));
        local += delta;
        view.xyz += mat3(gbufferModelView) * delta;
    }
#endif
#endif
    gl_Position = gl_ProjectionMatrix * view;
    vFogDistance = fogShape == 1 ? max(length(local.xz), abs(local.y)) : length(local);
    vec3 n = gl_NormalMatrix * gl_Normal;
    n *= inversesqrt(max(dot(n, n), 0.00001));
    vec3 up = normalize(upPosition);
    vec3 sun = normalize(sunPosition);
    vec3 cycle = daylight(sun, up);
    float nl = dot(n, sun);
    float sky = smoothstep(0.20, 0.965, lightUV.y);
    float torch = smoothstep(0.32, 0.96, lightUV.x);
    vOutdoor = sky * (1.0 - torch);
    float clear = 1.0 - rainStrength * 0.82;
    float direct = smoothstep(0.65, 0.965, lightUV.y) * (1.0 - torch) * cycle.z * clear;
    float sunFace = max(nl, 0.0);
    float transmission = 0.0;
#if SURFACE_KIND == 1
    if (mc_Entity.x >= 10003.0 && mc_Entity.x <= 10006.0) {
        // Thin leaves transmit some light even on the side facing away from the sun.
        transmission = max(-nl, 0.0) * direct;
        sunFace = 0.21 + 0.79 * sunFace;
    }
#endif
    vec3 worldSun = mat3(gbufferModelViewInverse) * sun;
#if CLOUD_STYLE == 2
    if (direct > 0.01 && worldSun.y > 0.08) {
        float density = textureLod(noisetex, cloudUV(local, worldSun), 0.0).r;
        direct *= 1.0 - 0.63 * smoothstep(0.48, 0.70, density) * smoothstep(0.08, 0.24, worldSun.y);
    }
#endif
    vec3 lamp = textureLod(lightmap, lightUV, 0.0).rgb;
    vec3 fill = mix(vec3(1.0), vec3(0.52, 0.69, 0.89), vOutdoor * cycle.z * clear);
    fill *= mix(vec3(1.0), vec3(0.80, 0.90, 1.13), vOutdoor * (1.0 - cycle.z));
    fill *= mix(vec3(1.0), vec3(1.18, 0.94, 0.73), torch);
    vFill = lamp * fill;
    vec3 sunlight = mix(vec3(0.81, 0.60, 0.34), vec3(1.06, 0.53, 0.22), cycle.y);
    vDirect = lamp * (sunlight * direct * sunFace + transmission * vec3(0.22, 0.33, 0.07));
#if SURFACE_KIND == 1
#ifdef COPPER_EDGE
    float wall = 1.0 - smoothstep(0.14, 0.50, abs(dot(n, up)));
    vEdge = vec2(local.y + fract(cameraPosition.y),
                 float(int(mc_Entity.x) == 10002) * wall * cycle.y * direct * sunFace);
#endif
#endif
#ifdef CAST_SHADOWS
    float footprint = 2.0 * shadowDistance / float(shadowMapResolution);
    float incidence = clamp(dot(n, normalize(shadowLightPosition)), 0.0, 1.0);
    vec3 receiver = local + mat3(gbufferModelViewInverse) * n * (0.35 + 0.85 * (1.0 - incidence)) * footprint;
    vec4 lightClip = shadowProjection * shadowModelView * vec4(receiver, 1.0);
    vShadow = lightClip.xyz / lightClip.w * 0.5 + 0.5;
    vShadowDistance = length(local);
#endif
#if SURFACE_KIND == 2
    vWater = int(mc_Entity.x) == 10001 ? 1 : 0;
    vWaterTop = smoothstep(0.35, 0.85, dot(n, up));
#ifdef WATER_SKY
    vWaterView = local;
    vWaterNormal = mat3(gbufferModelViewInverse) * n;
    vWaterSun = worldSun;
    vLowSun = cycle.y;
#endif
#ifdef WATER_RIPPLES
    vec2 p = local.xz + mod(cameraPosition.xz, 256.0);
    vWavePhase = 0.09817477 * vec2(dot(p, vec2(8.0, 3.0)), dot(p, vec2(-3.0, 13.0)))
               + frameTimeCounter * vec2(1.08, -1.41);
#endif
#endif
}

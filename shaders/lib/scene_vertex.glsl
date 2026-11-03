#include "/lib/settings.glsl"
#include "/lib/daylight.glsl"

uniform mat4 gbufferModelViewInverse;
uniform int fogShape;
out vec2 vUV;
out vec2 vLightUV;
out vec4 vTint;
out float vFogDistance;
out vec3 vLighting;

#if SURFACE_KIND == 1 || SURFACE_KIND == 2
in vec4 mc_Entity;
#endif

#if SURFACE_KIND == 1
#ifdef COPPER_EDGE
uniform vec3 cameraPosition;
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
out float vLowSun;
#endif
#ifdef WATER_RIPPLES
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
out vec2 vWavePhase;
#endif
#endif

void main() {
    vec4 view = gl_ModelViewMatrix * gl_Vertex;
    gl_Position = gl_ProjectionMatrix * view;
    vUV = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vLightUV = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vTint = gl_Color;
    vec3 local = (gbufferModelViewInverse * view).xyz;
    vFogDistance = fogShape == 1 ? max(length(local.xz), abs(local.y)) : length(local);

    vec3 n = gl_NormalMatrix * gl_Normal;
    n *= inversesqrt(max(dot(n, n), 0.00001));
    vec3 up = normalize(upPosition);
    vec3 sun = normalize(sunPosition);
    vec3 cycle = daylight(sun, up);
    float facingSun = max(dot(n, sun), 0.0);
    float openSky = smoothstep(0.20, 0.96, vLightUV.y);
    float torch = smoothstep(0.40, 0.95, vLightUV.x);
    float exposure = openSky * (1.0 - torch);
    float clearDay = cycle.z * (1.0 - rainStrength * 0.75);
    // Independent weights for sun, cool ambient and warm block light.
    vLighting = vec3(exposure * facingSun * clearDay, exposure * clearDay, torch);

#if SURFACE_KIND == 1
#ifdef COPPER_EDGE
    float wall = 1.0 - smoothstep(0.14, 0.50, abs(dot(n, up)));
    vEdge = vec2(local.y + fract(cameraPosition.y),
                 float(int(mc_Entity.x) == 10002) * wall * cycle.y * vLighting.x);
#endif
#endif

#ifdef CAST_SHADOWS
    // Bias in block units follows the footprint of one shadow texel.
    float footprint = 2.0 * shadowDistance / float(shadowMapResolution);
    float incidence = clamp(dot(n, normalize(shadowLightPosition)), 0.0, 1.0);
    vec3 localNormal = mat3(gbufferModelViewInverse) * n;
    vec3 receiver = local + localNormal * (0.35 + 0.85 * (1.0 - incidence)) * footprint;
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
    vLowSun = cycle.y;
#endif
#ifdef WATER_RIPPLES
    // Integer lattice periods keep the two waves continuous across chunk borders.
    vec2 p = local.xz + mod(cameraPosition.xz, 32.0);
    vWavePhase = 0.19634954 * vec2(dot(p, vec2(3.0, 1.0)), dot(p, vec2(-1.0, 5.0)))
               + frameTimeCounter * vec2(0.83, -1.17);
#endif
#endif
}

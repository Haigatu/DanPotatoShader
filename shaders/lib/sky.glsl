uniform vec3 skyColor;
uniform vec3 fogColor;
uniform float rainStrength;
#if CLOUD_STYLE > 0
#include "/lib/weather_uniforms.glsl"
#include "/lib/clouds.glsl"
#endif

vec3 paintedSky(vec3 ray, vec3 sun, float lowSun, vec3 origin, float roughness) {
    float h = clamp(ray.y, 0.0, 1.0);
    float day = smoothstep(-0.14, 0.12, sun.y);
    float clear = 1.0 - rainStrength;
    float grad = h / (h + 0.25);
    vec3 zenith = mix(skyColor * vec3(0.67, 0.84, 1.04), skyColor, rainStrength);
    vec3 sky = mix(fogColor, zenith, grad);
    float facing = dot(ray, sun);
    float solar = max(facing, 0.0);
    float halo = solar * solar;
    halo *= halo;
    float core = halo * halo;
    core *= core;
    vec3 gold = mix(vec3(1.0, 0.84, 0.61), vec3(1.0, 0.38, 0.12), lowSun);
    float belt = smoothstep(0.0, 0.065, h) * (1.0 - smoothstep(0.10, 0.49, h));
    sky += clear * day * (gold * (0.073 * halo + 0.24 * core * core)
                       + lowSun * belt * mix(vec3(0.16, 0.047, 0.095), vec3(0.44, 0.115, 0.025), solar));
    // A restrained halo also follows the opposite (lunar) direction at night.
    float lunar = max(-facing, 0.0);
    lunar *= lunar; lunar *= lunar; lunar *= lunar;
    sky += vec3(0.055, 0.085, 0.17) * lunar * lunar * (1.0 - day) * clear;
#if CLOUD_STYLE > 0
    if (ray.y > 0.035) {
        vec4 field = texture(noisetex, cloudUV(origin, ray));
        float density = mix(field.r, field.a, roughness);
        float cover = opacityFromDensity(density, rainStrength, h);
        float thickness = smoothstep(0.48, 0.81, density);
        vec2 slope = (field.gb * 2.0 - 1.0) * (1.0 - 0.75 * roughness);
        vec3 light = mix(-sun, sun, day);
        float lit = clamp(0.54 + 1.45 * dot(slope, light.xz) + 0.34 * light.y - 0.47 * thickness, 0.0, 1.0);
        vec3 base = mix(vec3(0.075, 0.099, 0.167), vec3(0.59, 0.66, 0.79), day);
        base = mix(base, vec3(0.51, 0.35, 0.46), lowSun * 0.85);
        vec3 bright = mix(vec3(0.20, 0.26, 0.38), mix(vec3(1.0, 0.98, 0.90), vec3(1.0, 0.68, 0.38), lowSun), day);
        vec3 cloud = mix(base, bright, lit);
        cloud += gold * (0.31 * halo) * (1.0 - thickness) * day * clear;
        cloud = mix(cloud, fogColor * (0.70 + 0.25 * lit), rainStrength * 0.85);
        sky = mix(sky, cloud, cover);
    }
#endif
    return mix(fogColor, sky, smoothstep(-0.025, 0.06, ray.y));
}

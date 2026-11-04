uniform vec3 skyColor;
uniform vec3 fogColor;
uniform float rainStrength;
#if CLOUD_STYLE > 0
#include "/lib/weather_uniforms.glsl"
#include "/lib/clouds.glsl"
#endif
#if defined(SKY_BACKGROUND) && defined(DETAILED_SKY)
#include "/lib/night_sky.glsl"
#endif

vec3 paintedSky(vec3 ray, vec3 sun, float lowSun, vec3 origin, float roughness) {
    float h = clamp(ray.y, 0.0, 1.0);
    float day = smoothstep(-0.14, 0.12, sun.y);
    float clear = 1.0 - rainStrength;
    vec3 zenith = mix(skyColor * vec3(0.67, 0.84, 1.04), skyColor, rainStrength);
    vec3 sky = mix(fogColor, zenith, h/(h+0.25));
    float facing = dot(ray, sun);
    float solar = max(facing, 0.0);
    float halo = solar * solar; halo *= halo;
    float core = halo * halo; core *= core;
    vec3 gold = mix(vec3(1.0, 0.84, 0.61), vec3(1.0, 0.38, 0.12), lowSun);
    float belt = smoothstep(0.0, 0.065, h) * (1.0 - smoothstep(0.10, 0.49, h));
    sky += clear * day * (gold * (0.073 * halo + 0.24 * core * core)
                       + lowSun * belt * mix(vec3(0.16, 0.047, 0.095), vec3(0.44, 0.115, 0.025), solar));
    float lunar = max(-facing, 0.0); lunar *= lunar; lunar *= lunar; lunar *= lunar;
    sky += vec3(0.055, 0.085, 0.17) * lunar * lunar * (1.0 - day) * clear;
#if defined(SKY_BACKGROUND) && defined(DETAILED_SKY)
    sky += starlight(ray.y);
#endif
#if CLOUD_STYLE > 0
    float cloudFade = cloudHorizon(h) * cloudLayerFade(origin.y);
    if (cloudFade > 0.0) {
        vec2 uv = cloudUV(origin,ray);
        vec4 bank = texture(noisetex,uv);
        vec3 shade = mix(vec3(0.05,0.067,0.112),vec3(0.51,0.58,0.70),day);
        vec3 ivory = mix(vec3(0.16,0.19,0.29),mix(vec3(0.98,0.965,0.91),vec3(1.0,0.72,0.49),lowSun),day);
        shade = mix(shade,vec3(0.49,0.38,0.48),lowSun*0.75);
        float cover;
        vec3 cloud;
        if (roughness > 0.5) {
            // Alpha already stores a wide convolution of coverage. Thresholding it
            // again would turn a soft, distant reflection back into white stripes.
            float filtered = mix(bank.a, 0.48*smoothstep(0.80,0.99,bank.a), cloudClearNight);
            cover = filtered * (0.18 + 0.48*smoothstep(0.04,0.56,h));
            cloud = mix(shade,ivory,0.52);
        } else {
            vec2 normal;
            cover = cloudShape(uv,ray,bank,rainStrength,normal);
            vec3 emitter = mix(-sun,sun,day);
            float light = clamp(0.68+0.50*dot(normal,emitter.xz)+0.28*emitter.y,0.0,1.0);
            float thickness = smoothstep(0.51,0.88,bank.r);
            light = clamp(light - cover*(0.14 + 0.24*thickness) + (bank.r-0.62)*0.32*cover, 0.0, 1.0);
            cloud = mix(shade,ivory,light);
            cloud += gold*(0.14*halo*clear*day)*(1.0-cover*thickness);
        }
        cloud = mix(cloud, fogColor, 0.26*(1.0-smoothstep(0.07,0.45,h)));
        cloud = mix(cloud,fogColor*0.85,rainStrength*0.81);
        sky = mix(sky,cloud,cover*cloudFade);
    }
#endif
    return mix(fogColor, sky, smoothstep(-0.025, 0.06, ray.y));
}

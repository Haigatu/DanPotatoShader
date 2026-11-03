// R: density, GB: signed lighting slopes, A: low-pass density for rough water.
uniform sampler2D noisetex;

vec2 cloudUV(vec3 base, vec3 ray) {
    float rise = max(224.0 - cameraPosition.y - base.y, 24.0);
    vec2 plane = mod(cameraPosition.xz, 768.0) + base.xz
               + ray.xz * (rise / max(ray.y, 0.055));
    return plane / 768.0 + frameTimeCounter * vec2(1.0, -0.35) / 768.0;
}

float opacityFromDensity(float density, float rain, float elevation) {
    return smoothstep(0.51 - 0.20 * rain, 0.62 - 0.20 * rain, density)
         * smoothstep(0.035, 0.17, elevation);
}

float cloudCover(vec3 ray, float rain) {
    if (ray.y <= 0.035) return 0.0;
    return opacityFromDensity(texture(noisetex, cloudUV(vec3(0.0), ray)).r, rain, ray.y);
}

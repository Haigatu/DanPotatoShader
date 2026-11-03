// R: cumulus height, GB: outward normal components, A: filtered fractional coverage.
uniform sampler2D noisetex;

vec2 cloudUV(vec3 base, vec3 ray) {
    float rise = max(224.0 - cameraPosition.y - base.y, 24.0);
    float horizon = 1.0 - clamp(ray.y, 0.0, 1.0);
    float elevation = max(ray.y, 0.0) + 0.26 * horizon * horizon;
    vec2 origin = mod(cameraPosition.xz, 768.0) + base.xz;
    return (origin + ray.xz * (rise / elevation) + frameTimeCounter * vec2(1.0, -0.35)) / 768.0;
}

float cloudMask(float density, float rain) {
    return smoothstep(0.41 - 0.15*rain, 0.60 - 0.13*rain, density);
}

float cloudHorizon(float h) { return smoothstep(0.015, 0.19, h); }

// The higher crown is displaced against the lower bank with view angle.
vec2 crownOffset(vec3 ray) { return ray.xz * (0.023 / (max(ray.y, 0.0) + 0.42)); }

float cloudCover(vec3 ray, float rain) {
    if (ray.y <= 0.015) return 0.0;
    vec2 uv = cloudUV(vec3(0.0), ray);
    float bank = cloudMask(texture(noisetex, uv).r, rain);
    float crown = cloudMask(texture(noisetex, uv + crownOffset(ray)).r - 0.13, rain);
    return (bank + (1.0-bank)*crown) * cloudHorizon(ray.y);
}

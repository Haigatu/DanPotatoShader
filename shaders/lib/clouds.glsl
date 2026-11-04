// R: cumulus density, GB: horizontal open-sky direction, A: filtered coverage.
uniform sampler2D noisetex;
uniform vec2 cloudOriginXZ;
uniform vec2 cloudDetailShift;
uniform vec2 cloudDryShift;
uniform float cloudClearNight;

const float cloudHeight = 224.0;
float cloudLayerFade(float baseY) {
    return smoothstep(0.0, 16.0, cloudHeight - (cameraPosition.y + baseY));
}

vec2 cloudUV(vec3 base, vec3 ray) {
    float rise = max(cloudHeight - (cameraPosition.y + base.y), 0.0);
    float horizon = 1.0 - clamp(ray.y, 0.0, 1.0);
    float elevation = max(ray.y, 0.0) + 0.26 * horizon * horizon;
    return (cloudOriginXZ + base.xz + ray.xz * (rise / elevation)) / 768.0;
}

// A slow dry front eats into individual banks. Integer UV frequencies stay
// continuous when the camera origin or the hourly animation timer wraps.
float cloudErosion(vec2 uv, float rain) {
    vec2 axes = vec2(uv.x + uv.y, uv.y - uv.x) + cloudDryShift;
    vec2 ramps = abs(fract(axes) - 0.5);
    return smoothstep(0.36, 0.82, ramps.x + ramps.y) * (0.80 - 0.74 * rain);
}

// The broad field carries the bank; the smaller, shearing field erodes and rebuilds its edges.
float cloudShape(vec2 uv, vec3 ray, vec4 bank, float rain, out vec2 normal) {
    vec2 detailUV = 2.0 * uv + cloudDetailShift + ray.xz * (0.035 / (max(ray.y,0.0) + 0.42));
    vec4 detail = texture(noisetex, detailUV);
    float density = bank.r + 0.30 * (detail.r - 0.50) - cloudErosion(uv, rain);
    normal = mix(bank.gb, detail.gb, 0.23) * 2.0 - 1.0;
    float low = 0.38 - 0.20 * rain + 0.38 * cloudClearNight;
    float high = 0.60 - 0.18 * rain + 0.32 * cloudClearNight;
    return smoothstep(low, high, density);
}

float cloudHorizon(float h) { return smoothstep(0.015, 0.19, h); }

float cloudCover(vec3 ray, float rain) {
    float fade = cloudHorizon(ray.y) * cloudLayerFade(0.0);
    if (fade <= 0.0) return 0.0;
    vec2 uv = cloudUV(vec3(0.0), ray);
    vec2 unusedNormal;
    return cloudShape(uv, ray, texture(noisetex, uv), rain, unusedNormal) * fade;
}

// Identical world-space offsets in the color and shadow passes keep silhouettes aligned.
vec3 windOffset(int material, vec3 local, float tip) {
    vec3 p = local + mod(cameraPosition, 256.0);
    float gust = sin(dot(p.xz, vec2(0.09817477, 0.04908739)) + frameTimeCounter * 0.84);
    float flutter = sin(dot(p, vec3(0.34361170, 0.09817477, -0.19634954)) - frameTimeCounter * 1.67);
    float bend = 0.10 * gust + 0.042 * flutter;
    if (material == 10003) return vec3(0.30 * bend, 0.007 * flutter, 0.012 * gust);
    float height = material == 10005 ? 0.5 + 0.5 * tip : material == 10006 ? 0.5 * tip : tip;
    return vec3(bend, -0.015 * abs(gust), bend * 0.40) * height;
}

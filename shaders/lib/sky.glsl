uniform vec3 skyColor;
uniform vec3 fogColor;

// Starts exactly at Minecraft's fog color, including rain and biome changes.
vec3 paintedSky(float elevation, float towardSun, float lowSun) {
    float h = clamp(elevation, 0.0, 1.0);
    float grad = h * (2.0 - h);
    vec3 base = mix(fogColor, skyColor * vec3(0.91, 0.97, 1.035), grad);
    float belt = smoothstep(0.0, 0.09, h) * (1.0 - smoothstep(0.10, 0.46, h));
    return base + vec3(0.16, 0.061, 0.016) * belt * lowSun
                * smoothstep(-0.18, 0.91, towardSun);
}

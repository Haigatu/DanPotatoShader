uniform int entityId;
uniform float endEnergyPhase;

// Iris identifies the healing beam separately from the dragon.
// The aspect-ratio fallback also handles loaders that retain the crystal's ID.
void endEnergy(inout vec3 color, vec4 albedo, vec2 uv) {
    if (entityId != 13001 && entityId != 13002) return;
    ivec2 size = textureSize(gtexture, 0);
    if (entityId == 13002 || size.y >= size.x * 8) {
        float pulse = 0.5 + 0.5 * sin(uv.y * 25.132741 + endEnergyPhase);
        float core = smoothstep(0.12, 0.72, max(albedo.r, albedo.b));
        vec3 energy = mix(vec3(0.32, 0.10, 0.62), vec3(0.91, 0.73, 1.0), core);
        color = mix(color, energy * (0.82 + 0.18 * pulse), 0.88);
    } else if (entityId == 13001 && size.x == 2 * size.y && uv.x >= 0.5 && uv.y < 0.5) {
        float pulse = 0.93 + 0.07 * sin(endEnergyPhase);
        vec3 core = mix(albedo.rgb * vec3(1.0, 0.66, 1.0), vec3(0.96, 0.78, 1.0), 0.36);
        color = max(color, core * pulse);
    }
}

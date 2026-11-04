uniform int heldItemId;
uniform int heldItemId2;
uniform vec3 relativeEyePosition;

// Return a lightmap coordinate. Two torches produce the same light as one.
float handTorch(vec3 playerSpace) {
    if (heldItemId != 12001 && heldItemId2 != 12001) return 0.0;
    vec3 fromTorch = playerSpace + relativeEyePosition + vec3(0.0, 0.55, 0.0);
    return 0.90 * max(1.0 - length(fromTorch) / 10.0, 0.0);
}

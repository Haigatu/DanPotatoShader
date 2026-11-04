// Integral of a triangular layer from Y=18 to Y=86, densest below the islands.
float mistIntegral(float height) {
    float t = clamp((height - 52.0) / 34.0, -1.0, 1.0);
    return 34.0 * (t - 0.5 * t * abs(t) + 0.5);
}

float endMist(vec3 segment, float eyeHeight) {
    float density;
    if (abs(segment.y) < 0.1) {
        density = max(1.0 - abs((eyeHeight + 0.5 * segment.y - 52.0) / 34.0), 0.0);
    } else {
        density = (mistIntegral(eyeHeight + segment.y) - mistIntegral(eyeHeight)) / segment.y;
    }
    float distance = length(segment);
    float optical = max(density, 0.0) * max(distance - 10.0, 0.0) * 0.009;
    return optical / (1.0 + optical);
}

const vec3 endMistColor = vec3(0.24, 0.185, 0.32);

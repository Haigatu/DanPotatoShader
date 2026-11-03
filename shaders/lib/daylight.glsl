uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform float rainStrength;

// x: elevation, y: low clear sunlight, z: daylight. Evaluated per vertex.
vec3 daylight(vec3 sun, vec3 up) {
    float height = dot(sun, up);
    float lowSun = (1.0 - smoothstep(0.04, 0.42, abs(height)))
                 * smoothstep(-0.09, 0.04, height) * (1.0 - rainStrength);
    return vec3(height, lowSun, smoothstep(-0.12, 0.24, height));
}

uniform ivec3 cameraPositionInt;
uniform vec3 cameraPositionFract;

// Keep the raster and receiver on the same world-anchored texel grid.
// Split integers before converting to float, including at negative/world-border coordinates.
vec2 shadowGridOffset(mat4 lightMatrix) {
    float halfResolution = 0.5 * float(shadowMapResolution);
    vec2 x = lightMatrix[0].xy * halfResolution;
    vec2 y = lightMatrix[1].xy * halfResolution;
    vec2 z = lightMatrix[2].xy * halfResolution;
    vec3 low = vec3(cameraPositionInt & ivec3(255)) + cameraPositionFract;
    vec3 middle = vec3((cameraPositionInt >> 8) & ivec3(255));
    vec3 high = vec3(cameraPositionInt >> 16);
    vec2 origin = lightMatrix[3].xy * halfResolution - x * low.x - y * low.y - z * low.z;
    origin = fract(origin - fract(x * 256.0) * middle.x - fract(y * 256.0) * middle.y - fract(z * 256.0) * middle.z);
    origin = fract(origin - fract(x * 65536.0) * high.x - fract(y * 65536.0) * high.y - fract(z * 65536.0) * high.z);
    return (floor(origin + 0.5) - origin) / halfResolution;
}

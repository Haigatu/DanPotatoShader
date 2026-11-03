#version 330 compatibility
#include "/lib/daylight.glsl"
uniform mat4 gbufferProjectionInverse;
out vec3 vRay;
flat out vec3 vSun;
flat out vec3 vUp;
flat out float vLowSun;
out vec4 vColor;

void main() {
    gl_Position = ftransform();
    // Reconstruct on vertices so the gradient is independent of the sky mesh.
    vRay = (gbufferProjectionInverse * vec4(gl_Position.xy, gl_Position.ww)).xyz;
    vSun = normalize(sunPosition);
    vUp = normalize(upPosition);
    vLowSun = daylight(vSun, vUp).y;
    vColor = gl_Color;
}

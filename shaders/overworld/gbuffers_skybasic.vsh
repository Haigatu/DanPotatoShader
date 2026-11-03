#version 330 compatibility
#include "/lib/daylight.glsl"
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
out vec3 vRay;
flat out vec3 vSun;
flat out float vLowSun;
out vec4 vColor;

void main() {
    gl_Position = ftransform();
    vec3 viewRay = (gbufferProjectionInverse * vec4(gl_Position.xy, gl_Position.ww)).xyz;
    vRay = mat3(gbufferModelViewInverse) * viewRay;
    vec3 sun = normalize(sunPosition);
    vSun = mat3(gbufferModelViewInverse) * sun;
    vLowSun = daylight(sun, normalize(upPosition)).y;
    vColor = gl_Color;
}

#version 330 compatibility
#include "/lib/settings.glsl"
#include "/lib/daylight.glsl"
#ifdef DETAILED_SKY
uniform int renderStage;
out vec3 vStarsDirection;
flat out float vStarsStrength;
#endif
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
#ifdef DETAILED_SKY
    // The rotation is constant over a primitive and direction is linear in vRay.
    vec3 axis = vec3(0.0,-0.46947,0.88295);
    vStarsDirection = vec3(dot(vRay,cross(axis,vSun)),dot(vRay,axis),dot(vRay,vSun));
    vStarsStrength = (1.0-smoothstep(-0.25,-0.045,vSun.y))*(1.0-rainStrength);
    if (renderStage == MC_RENDER_STAGE_STARS) {
        // Each vanilla indexed quad supplies four vertices for a single star.
        uint id = uint(gl_VertexID) >> 2u;
        uint bits = (id * 747796405u + 2891336453u);
        bits ^= bits >> 16u;
        float heat = float(bits & 255u) / 255.0;
        float power = float((bits >> 8u) & 255u) / 255.0;
        vColor.rgb *= mix(vec3(0.66,0.78,1.0),vec3(1.0,0.80,0.60),heat)
                    * (0.61 + 1.31*power*power);
    }
#endif
}

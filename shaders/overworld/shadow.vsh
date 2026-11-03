#version 330 compatibility
#include "/lib/settings.glsl"
#ifdef FOLIAGE_WIND
in vec4 mc_Entity;
in vec2 mc_midTexCoord;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowModelView;
#include "/lib/weather_uniforms.glsl"
#include "/lib/wind.glsl"
#endif
out vec2 vUV;
out float vAlpha;
void main() {
    vec4 view = gl_ModelViewMatrix * gl_Vertex;
#ifdef FOLIAGE_WIND
    int plant = int(mc_Entity.x);
    if (plant >= 10003 && plant <= 10006) {
        vec3 local = (shadowModelViewInverse * view).xyz;
        view.xyz += mat3(shadowModelView) * windOffset(plant, local, step(gl_MultiTexCoord0.t, mc_midTexCoord.t));
    }
#endif
    gl_Position = gl_ProjectionMatrix * view;
    vUV = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vAlpha = gl_Color.a;
}

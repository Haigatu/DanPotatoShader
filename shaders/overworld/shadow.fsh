#version 330 compatibility
#include "/lib/settings.glsl"
uniform sampler2D gtexture;
uniform float alphaTestRef;
const bool shadowHardwareFiltering = true;
const float shadowDistanceRenderMul = 1.0;
in vec2 vUV;
in float vAlpha;
// Empty draw list: only fixed-function depth is needed after the cutout test.
/* DRAWBUFFERS: */
void main() {
    if (texture(gtexture, vUV).a * vAlpha < max(alphaTestRef, 0.1)) discard;
}

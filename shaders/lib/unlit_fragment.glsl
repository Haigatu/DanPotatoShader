uniform sampler2D gtexture;
uniform float alphaTestRef;
in vec2 vUV;
in vec4 vColor;
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;
void main() {
    color = texture(gtexture, vUV) * vColor;
    if (color.a < alphaTestRef) discard;
}

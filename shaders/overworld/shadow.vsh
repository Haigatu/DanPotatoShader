#version 330 compatibility
out vec2 vUV;
out float vAlpha;
void main() {
    gl_Position = ftransform();
    vUV = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vAlpha = gl_Color.a;
}

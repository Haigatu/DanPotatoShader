uniform mat4 gbufferModelViewInverse;
uniform int fogShape;
out vec2 vUV;
out vec2 vLightUV;
out vec4 vColor;
out float vFogDistance;
void main() {
    vec4 view = gl_ModelViewMatrix * gl_Vertex;
    gl_Position = gl_ProjectionMatrix * view;
    vUV = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vLightUV = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vColor = gl_Color;
    vec3 local = (gbufferModelViewInverse * view).xyz;
    vFogDistance = fogShape == 1 ? max(length(local.xz), abs(local.y)) : length(local);
}

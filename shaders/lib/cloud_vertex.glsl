uniform mat4 gbufferModelViewInverse;
uniform int fogShape;
out vec4 vColor;
out float vFogDistance;
void main() {
    vec4 view = gl_ModelViewMatrix * gl_Vertex;
    gl_Position = gl_ProjectionMatrix * view;
    vec3 local = (gbufferModelViewInverse * view).xyz;
    vFogDistance = fogShape == 1 ? max(length(local.xz), abs(local.y)) : length(local);
    vColor = gl_Color;
}

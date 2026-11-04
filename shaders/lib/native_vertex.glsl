#include "/lib/settings.glsl"
#ifdef HAND_TORCH
#include "/lib/hand_torch.glsl"
#endif
#if PORTAL_PASS == 1
#ifdef PORTAL_DEPTH
out vec3 vPortalLocal;
#endif
#endif
uniform mat4 gbufferModelViewInverse;
uniform int fogShape;
#if END_PASS == 1 && defined(END_MIST)
uniform vec3 cameraPosition;
out float vEndMist;
#include "/lib/end_mist.glsl"
#endif
out vec2 vUV;
out vec2 vLightUV;
out vec4 vColor;
out float vFogDistance;
#if END_TERRAIN == 1
#ifdef END_MATERIALS
in vec4 mc_Entity;
out vec2 vEndAccent;
#endif
#endif
void main() {
    vec4 view = gl_ModelViewMatrix * gl_Vertex;
    gl_Position = gl_ProjectionMatrix * view;
    vUV = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vLightUV = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vColor = gl_Color;
    vec3 local = (gbufferModelViewInverse * view).xyz;
#if END_PASS == 1 && defined(END_MIST)
    vec3 eye = gbufferModelViewInverse[3].xyz;
    vEndMist = endMist(local - eye, cameraPosition.y + eye.y);
#endif
#ifdef HAND_TORCH
    vLightUV.x = max(vLightUV.x, handTorch(local));
#endif
#if PORTAL_PASS == 1 && defined(PORTAL_DEPTH)
    vPortalLocal = local;
#endif
#if END_TERRAIN == 1 && defined(END_MATERIALS)
    vec3 normal = gl_NormalMatrix * gl_Normal;
    normal *= inversesqrt(max(dot(normal, normal), 0.00001));
    vec3 worldNormal = mat3(gbufferModelViewInverse) * normal;
    float facing = smoothstep(-0.65, 0.75, dot(worldNormal, vec3(-0.55, 0.70, 0.45)));
    vec3 fill = mix(vec3(0.86, 0.80, 1.04), vec3(1.18, 1.10, 1.21), facing);
    float blockLight = smoothstep(0.25, 0.95, vLightUV.x);
    vColor.rgb *= mix(fill, vec3(1.0), blockLight);

    vEndAccent = vec2(0.0);
    if (int(mc_Entity.x) == 10100) {
        float grazing = 1.0 - clamp(abs(dot(normal, view.xyz)) / max(length(view.xyz), 0.001), 0.0, 1.0);
        vEndAccent.x = grazing * grazing;
    } else if (int(mc_Entity.x) == 10101) {
        vEndAccent.y = 1.0;
    }
#endif
    vFogDistance = fogShape == 1 ? max(length(local.xz), abs(local.y)) : length(local);
}

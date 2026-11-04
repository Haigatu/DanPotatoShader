uniform int blockEntityId;
uniform sampler2D portalField;
uniform vec4 portalFrame;
in vec3 vPortalLocal;

// The tilted plane gives horizontal portals and vertical gateway faces a continuous field.
vec2 portalPlane(vec3 p) {
    return vec2(p.x - p.z, p.y - 0.5 * (p.x + p.z));
}

vec3 portalColor() {
    vec2 surface = portalPlane(vPortalLocal + portalFrame.xyz);
    vec2 ray = portalPlane(normalize(vPortalLocal));
    vec2 farUV = surface * 0.0625 + ray * 0.43 + vec2(5.0, -3.0) * portalFrame.w;
    vec2 nearUV = surface * 0.125 + ray * 0.14 + vec2(-9.0, 4.0) * portalFrame.w;
    vec2 dust = texture(portalField, farUV).rb;
    float stars = texture(portalField, nearUV).g;
    vec2 footprint = fwidth(nearUV);
    stars *= 1.0 - smoothstep(0.005, 0.024, max(footprint.x, footprint.y));
    return vec3(0.025, 0.016, 0.085) + dust.x * vec3(0.28, 0.12, 0.46)
         + dust.y * vec3(0.17, 0.38, 0.48) + stars * vec3(0.76, 0.89, 1.0);
}

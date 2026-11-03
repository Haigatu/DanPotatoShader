uniform sampler2D colortex0;
in vec2 vUV;
layout(location = 0) out vec4 displayColor;
void main() {
    vec3 c = texture(colortex0, vUV).rgb;
    float y = dot(c, vec3(0.2126, 0.7152, 0.0722));
    // Zero at black and white; small midtone lift keeps caves legible.
    c = mix(vec3(y), c, 1.035) + 0.048 * y * (1.0 - y);
    displayColor = vec4(clamp(c, 0.0, 1.0), 1.0);
}

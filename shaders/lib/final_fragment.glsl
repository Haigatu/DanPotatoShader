uniform sampler2D colortex0;
in vec2 vUV;
layout(location = 0) out vec4 displayColor;
void main() {
    vec3 c = texture(colortex0, vUV).rgb;
    float y = dot(c, vec3(0.2126, 0.7152, 0.0722));
    // Luma-only S curve with a lifted toe keeps hue and black/white endpoints stable.
    float tone = y * (1.0 - y) * (0.34 * (2.0 * y - 1.0) + 0.085);
    float chroma = 1.0 + 0.12 * (1.0 - max(c.r, max(c.g, c.b)));
    displayColor = vec4(clamp(vec3(y + tone) + (c - y) * chroma, 0.0, 1.0), 1.0);
}

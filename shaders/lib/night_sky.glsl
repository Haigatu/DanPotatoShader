uniform sampler2D nightAtlas;
in vec3 vStarsDirection;
flat in float vStarsStrength;

// Octahedral mapping avoids per-pixel longitude/latitude trigonometry.
vec2 atlasUV(vec3 dir) {
    vec2 uv = dir.xy / (abs(dir.x)+abs(dir.y)+abs(dir.z));
    if (dir.z < 0.0) uv = (1.0-abs(uv.yx)) * mix(vec2(-1.0), vec2(1.0), greaterThanEqual(uv,vec2(0.0)));
    return uv * 0.5 + 0.5;
}

vec3 starlight(float elevation) {
    if (vStarsStrength < 0.004 || elevation <= 0.015) return vec3(0.0);
    vec2 uv = atlasUV(vStarsDirection);
    vec2 grid = clamp(uv,0.0,0.999999) * 384.0;
    float dust = texture(nightAtlas,uv).r;
    vec4 star = texelFetch(nightAtlas,ivec2(grid),0);
    vec2 delta = fract(grid) - mix(vec2(0.30),vec2(0.70),star.gb);
    float radius = 0.09 + 0.105*star.a;
    vec2 footprint = fwidth(grid);
    float aa = clamp(max(footprint.x,footprint.y)*0.52,0.025,0.26);
    float point = (1.0 - smoothstep(radius-aa,radius+aa,length(delta))) * star.a;
    vec3 tint = mix(vec3(0.66,0.79,1.0),vec3(1.0,0.85,0.70),star.g);
    vec3 band = dust * (vec3(0.16,0.20,0.34) + dust*vec3(0.18,0.10,0.04));
    return (band + point*tint)*vStarsStrength*smoothstep(0.015,0.25,elevation);
}

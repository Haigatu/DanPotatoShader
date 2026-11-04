// Octahedral mapping avoids per-pixel longitude/latitude trigonometry.
vec2 atlasUV(vec3 dir) {
    vec2 uv = dir.xy / (abs(dir.x)+abs(dir.y)+abs(dir.z));
    if (dir.z < 0.0) uv = (1.0-abs(uv.yx)) * mix(vec2(-1.0), vec2(1.0), greaterThanEqual(uv,vec2(0.0)));
    return uv * 0.5 + 0.5;
}

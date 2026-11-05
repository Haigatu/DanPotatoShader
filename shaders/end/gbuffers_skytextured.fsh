#version 330 compatibility
#include "/lib/settings.glsl"
#if defined(DETAILED_SKY) || defined(END_MIST)
in vec3 vRay;
uniform int isEyeInWater;
uniform vec3 fogColor;
#endif
#ifdef END_MIST
uniform vec3 cameraPosition;
uniform mat4 gbufferModelViewInverse;
uniform float far;
uniform float blindness;
uniform float darknessFactor;
#include "/lib/end_mist.glsl"
#endif
#ifdef DETAILED_SKY
#include "/lib/atlas_uv.glsl"
uniform sampler2D endGlowField;
uniform vec3 endGlowOrigin;

float pillar(vec3 field, float elevation) {
    float height = .13 + .26*field.g + .10*field.r;
    float y = (elevation-.07*(field.b-.5))/height;
    float falloff = 1.0/(1.0+y*y);
    return field.r*falloff*falloff;
}

vec3 endStars(vec3 ray) {
    vec2 grid = clamp(atlasUV(ray),0.0,.999999)*256.0;
    vec4 cell = texelFetch(endGlowField,ivec2(grid),0);
    if (cell.a == 0.0) return vec3(0.0);
    vec2 p = (floor(grid)+mix(vec2(.38),vec2(.62),cell.gb))*(2.0/256.0)-1.0;
    vec3 point = vec3(p,1.0-abs(p.x)-abs(p.y));
    point.xy -= sign(p)*max(-point.z,0.0);
    vec3 delta = ray-normalize(point);
    float radius = .00085+.0019*cell.a;
    float star = 1.0-smoothstep(radius*radius,(radius+.00080)*(radius+.00080),dot(delta,delta));
    return star*cell.a*mix(vec3(.64,.42,.88),vec3(.90,.91,1.),cell.g);
}
#else
uniform sampler2D gtexture;
in vec2 vUV;
in vec4 vColor;
#endif
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 sky;
void main() {
#if defined(DETAILED_SKY) || defined(END_MIST)
    if (isEyeInWater != 0) {
        sky = vec4(fogColor, 1.0);
        return;
    }
    vec3 ray = normalize(vRay);
#endif
#ifdef DETAILED_SKY
    float invHorizontal = inversesqrt(max(dot(ray.xz,ray.xz),.0001));
    vec2 bearing = ray.xz*invHorizontal;
    float slope = ray.y*invHorizontal;
    // Two distances give the curtains different parallax. Stars stay at infinity.
    vec3 nearField = textureLod(endGlowField,endGlowOrigin.xz+bearing*(460.0/1024.0),0.0).rgb;
    vec3 farField = textureLod(endGlowField,endGlowOrigin.xz+bearing*(950.0/1024.0)+vec2(.31,.57),0.0).rgb;
    float nearLight = pillar(nearField,slope+endGlowOrigin.y/460.0);
    float farLight = pillar(farField,slope+endGlowOrigin.y/950.0);
    vec3 space = vec3(.165,.125,.234) + farLight*vec3(.32,.21,.53)
               + nearLight*mix(vec3(.52,.29,.66),vec3(.69,.33,.55),nearField.b) + endStars(ray);
    space += (fract(dot(gl_FragCoord.xy,vec2(.754878,.569840)))-.5)/255.0;
    sky = vec4(space,1.0);
#else
    sky = texture(gtexture,vUV)*vColor;
#endif
#ifdef END_MIST
    float visible = isEyeInWater == 0 ? 1.0 - max(blindness, darknessFactor) : 0.0;
    float mist = endMist(ray * min(far, 256.0), cameraPosition.y + gbufferModelViewInverse[3].y);
    sky.rgb = mix(sky.rgb, endMistColor, mist * visible);
#endif
}

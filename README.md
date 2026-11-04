# DanPotatoShader

A shader pack for **Minecraft Java 1.21.1, Fabric, and Iris**, designed for Intel UHD integrated graphics. At a riverbank, the low sun lights the edges of stone and foliage, nearby trees cast shadows, and ripples break up the reflected sky. Both profiles include these effects.

**0.2.9 UHD preview.** Lilac light picks out the faces of End islands. Obsidian catches a soft violet highlight at grazing angles, and the pale tips of growing chorus flowers glow. **End island lighting** controls these effects independently of the sky.

**[Download the 0.2.9 UHD preview](https://github.com/Haigatu/DanPotatoShader/releases/download/v0.2.9-uhd-preview/DanPotatoShader-0.2.9-UHD-preview.zip)** · [Release notes](https://github.com/Haigatu/DanPotatoShader/releases/tag/v0.2.9-uhd-preview)

![End island lighting, obsidian and chorus in 0.2.8 and 0.2.9](https://github.com/Haigatu/DanPotatoShader/releases/download/v0.2.9-uhd-preview/DanPotatoShader-0.2.9-End-comparison.png)

*Paired captures from the same positions in Minecraft 1.21.1 on Intel UHD at 1920 × 1080, using the Light profile.*

## Install

1. Use **Minecraft Java 1.21.1**, **64-bit Java 21**, and a compatible **Fabric Loader 0.16.0 or later**. Install the Fabric builds of Iris and Sodium for 1.21.1. The original 0.2 baseline used [Iris 1.8.8](https://modrinth.com/mod/iris/version/1.8.8%2B1.21.1-fabric) and [Sodium 0.6.13](https://modrinth.com/mod/sodium/version/mc1.21.1-0.6.13-fabric).
2. Open the shader pack folder from the Iris video settings and place the downloaded ZIP inside it. Keep the archive zipped. Prism Launcher has a separate folder for each instance.
3. Select the same ZIP and apply. **Light** is the default. Shader settings, profile names, and tooltips follow Minecraft's language and include English and Russian.

## Profiles

| Setting | Light · default | Balanced |
| --- | --- | --- |
| Nearby terrain and foliage shadows | 384 × 384, 24 blocks | 512 × 512, 32 blocks |
| Cloud layer | Painted sky and its water reflection | Also casts moving shade on sunlit ground |
| Sky reflection and ripples | On | On |
| Shoreline depth | Off | One opaque-depth read on visible water |
| Foliage wind, copper edges, star field and round disks | On | On |

For an i5-12450H with Intel UHD and 16 GB DDR4, start with **Light at your native 1920 × 1080, 8–12 chunks of render distance, and 5 chunks of simulation distance**. If slowdowns appear mostly at night, turn off **Star field** to keep the moon and nearby tree shadows. Turning off **Cast shadows** also saves the extra geometry pass throughout the day. Try 1600 × 900 if reducing pixel cost is necessary. All water features switch independently. The **Cloud layer** setting cycles between game clouds, painted clouds, and painted clouds with moving ground shade.

## How it works

- **End island lighting.** The terrain vertex shader uses each face's world-space normal to tint ambient light. Its influence fades near bright block lights. Obsidian picks up a grazing highlight masked by the block texture. Growing chorus flowers (ages 0–4) brighten only at their pale tips. Both accents reuse the existing terrain texture sample and are applied before distance fog.

- **Storms.** Iris supplies separate rain and thunder strengths. The pack calculates an overcast amount and a color blend once per frame. The sky, its water reflection and the ground shade in Balanced use the same overcast amount. The existing density texture also darkens the thickest parts of the storm.
- **End sky.** Two samples of a repeating 256 × 256 field control pillar height, intensity and hue at different distances. The shader calculates the vertical glow for each screen pixel from the viewing ray and the player's altitude. The stars use one unfiltered read of a separate channel in the same field and have their own angular size. The **Star field** setting also controls the End sky. The visual reference was [Complementary Unbound](https://www.curseforge.com/minecraft/shaders/complementary-unbound).

- **Light and leaves.** The vertex shader samples Minecraft's lightmap and separates cool ambient light from direct sunlight. Open sides of leaves and grass transmit some light. Torches retain a warm falloff. Short grass bends from its base, tall plants bend continuously across both blocks, and the shadow pass uses the same displacement as the foliage. In Balanced, moving cloud cover also dims the sunlight that passes through leaves.
- **Clouds.** A broad bank and finer detail move across a world-space layer at Y=224. Two samples of the same 256 × 256 atlas provide their densities and lighting directions. A separate moving pattern thins the cloud from its edges to its core in dry patches. Rain weakens this effect. The same dry patches open gaps in the sky, its water reflection and the ground shade in Balanced. Clear nights retain the densest cores. Stars and celestial disks use the same cloud mask. Water reads the broad pattern in one filtered sample. The sky layer fades when approached from below and clears overhead above its altitude.
- **Water.** A muted blue-green tint and lower transparency darken the water while keeping the lakebed visible near shore. The cloud atlas alpha channel stores broad fractional cloud coverage filtered during the texture bake. Water reads it once, blends it into the sky tint and reduces cloud contrast near the horizon. Two moving ripple directions still catch low sunlight. Balanced measures the underwater segment along the viewing ray for clearer shallows and darker pools. The reflection shows sky and clouds.
- **Night sky and celestial bodies.** A 384 × 384 octahedral star map adds a broken band of galactic light and dust lanes that rotate with the celestial sphere. A tag distinguishes constant dust, filtered dust and star cells. The shader reads a second time only where filtering is needed and evaluates point shapes only for occupied cells. Both fade in rain. The existing star mesh supplies brighter points in cool and warm colors. The sun and all eight moon phases are baked into a cropped 192 KiB atlas. Each sprite reads one texture on the existing game quad. The game selects the phase through its usual lunar texture coordinates. **Star field** switches the 576 KiB night atlas on and off. **Round sun and moon** controls the sprite textures separately. [Night-sky generator](https://github.com/Haigatu/DanPotatoShader/blob/v0.2.2-beta/tools/bake_night_sky.py)
- **Stone and distance.** Low sunlight catches the upper courses of full masonry blocks, with the highlight fading before it becomes subpixel. Distant outdoor terrain picks up the biome's fog color. One final color sample shapes midtone contrast while preserving the black and white endpoints.

The Overworld uses the custom sun, clouds, wind, water, and shadows. The Nether uses its native light and fog. In the End, block faces receive directional light with **End island lighting**. Bright block light retains its native color. **Star field** controls the sky and violet distance haze. All three dimensions use the shared final color grade. The pack writes one scene color target, reads no frame history, and uses no volumetric ray marching, SSR, or bloom chain. The optional shadow map covers opaque and cutout terrain. Mobs, translucent blocks, and block entities do not cast into it. Low shadow-map resolutions can show steps on thin silhouettes.

## Performance and verification

For 0.2.8, the new End sky added 0.39 ms to the median frame time at the central island on Light and 0.43 ms at an outer island on Balanced. The storm at the lake differed by at most 0.01 ms. These comparisons used Intel UHD at 1080p, Fast graphics and 8 render chunks. [Test conditions and timings](https://github.com/Haigatu/DanPotatoShader/blob/v0.2.8-uhd-preview/docs/sky-research-plan.md)

The test client ran **Minecraft 1.21.1, Fabric Loader 0.20.1, Iris 1.8.14-beta.1 and Sodium 0.8.13** on an **i5-12450H with Intel UHD Graphics**, driver **32.0.101.7088**. An isolated single-player lake scene was generated for the comparison. The framebuffer was 1920 × 1080, with 12 chunks of render distance, 5 chunks of simulation distance, and VSync off. Tests used a stationary camera after chunk loading.

In four paired Light-profile tests at moonrise, the 0.2.1 baseline averaged **134.3 FPS** and the tagged star atlas averaged **139.6 FPS**. Median frame time across runs fell from **7.41 ms to 7.10 ms**. A separate water-table experiment averaged 147.8 FPS against 148.9 FPS for analytic ripples in the daytime lake view, so 0.2.2 retains analytic ripples. Results describe this stationary world after chunk loading. [Source analysis, test method and results](https://github.com/Haigatu/DanPotatoShader/blob/v0.2.2-beta/docs/intel-uhd-optimizations.md)

For 0.2.3, both profiles were loaded in the test world. The water tint was compared against 0.2.2 in daylight and evening light.

For 0.2.2, the Iris 1.8.8 offline parser also checked both profiles, all eleven options and 29 English and Russian menu entries per language. The Intel OpenGL driver compiled and linked 18 programs across 194 configurations, including both shipping profiles after Iris's core-profile transformations. Pixel tests exercised water, wind, shadow cutouts, light, fog, and grading.

## Files and packaging

| Location | Contents |
| --- | --- |
| `shaders/` | Base programs, profile settings, dimension mapping, and block IDs |
| `shaders/overworld/` | Terrain, water, sky, entities, hand, shadow, and final program entry points |
| `shaders/end/` | End sky, distance haze and native material entry points |
| `shaders/lib/` | Shared lighting, cloud projection, water, foliage wind, fog, and color-grading code |
| `shaders/textures/` | Cloud and night-sky atlases with sampling metadata |
| `shaders/lang/` | English and Russian menu strings |
| `tools/`, `docs/` | Offline texture generators, comparison images and optimization notes, excluded from the installable ZIP |

To package a clone, run this command at the repository root.

```sh
git archive --format=zip --output=DanPotatoShader.zip HEAD README.md shaders
```

## References

Uses RustingShader by Vasyl Trefilov. The offline generator adapts its lunar phase lighting, removes the procedural craters and bakes eight antialiased sprites with a short glow along the lit edge. The faint surface markings use the 2019 lunar color map by Ernie Wright, NASA's Scientific Visualization Studio, from LRO camera and altimeter data. Their contrast is reduced for a bright disk at game scale. The moon and its glow use one atlas read in game. [Original lunar shader](https://github.com/RustingStudio/RustingShader/blob/b1a6b978bb12820c67c1b952f0e073ba8e08fd22/shaders/lib/common.glsl#L141-L210) · [RustingShader License 1.0](shaders/licenses/RustingShader.md) · [NASA CGI Moon Kit](https://svs.gsfc.nasa.gov/4720/)

The GLSL and cloud texture were created for this pack. Structure and shadow mapping follow the [Iris reference](https://shaders.properties/current/reference/overview/), [Iris documentation repository](https://github.com/IrisShaders/docs), [Base-330](https://github.com/shaderLABS/Base-330), and [Shadow Tutorial](https://github.com/shaderLABS/Shadow-Tutorial). Independent quality controls were informed by [MakeUp Ultra Fast](https://github.com/javiergcim/MakeUpUltraFast) and its [developer notes](https://github.com/javiergcim/MakeUpUltraFast/blob/master/ForDevelopers.EN.md). Additional visual references included [Photon](https://github.com/sixthsurge/photon), [Bliss](https://github.com/X0nk/Bliss-Shader), and [Revelation](https://github.com/HaringPro/Revelation).

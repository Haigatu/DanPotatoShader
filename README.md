# DanPotatoShader

A Minecraft Java 1.21.1 shader pack for Intel UHD integrated graphics, built for Fabric and Iris. At dawn and dusk, a thin copper highlight catches the top edge of sunlit stonework. It runs while the blocks are drawn and needs no extra render pass.

**[Download DanPotatoShader.zip](https://github.com/Haigatu/DanPotatoShader/releases/download/v0.1.0-beta/DanPotatoShader.zip)** · [v0.1.0-beta release notes](https://github.com/Haigatu/DanPotatoShader/releases/tag/v0.1.0-beta)

**Beta status.** Both profiles compiled and linked on Intel UHD. The effects have been tested on small scenes outside Minecraft. In-game testing and FPS measurements are pending.

## Installation

1. Use Minecraft Java **1.21.1**, 64-bit **Java 21**, and a compatible **Fabric Loader 0.16.0 or later**. Install the Fabric builds of **Iris 1.8.8** and **Sodium 0.6.13** in your instance’s `mods` folder. [Iris 1.8.8](https://modrinth.com/mod/iris/version/1.8.8%2B1.21.1-fabric) · [Sodium 0.6.13](https://modrinth.com/mod/sodium/version/mc1.21.1-0.6.13-fabric) · [Fabric for 1.21.1](https://fabricmc.net/2024/05/31/121.html).
2. In the video settings, open the Iris shader pack screen and use the button to open the shader pack folder. Copy **DanPotatoShader.zip** into it without extracting it. The default Windows launcher uses `%APPDATA%\.minecraft\shaderpacks\`. Prism Launcher uses the selected instance’s folder.
3. Select **DanPotatoShader.zip** and apply it. **Light** is the default profile. Open **Shader Pack Settings** to switch profiles or adjust individual effects.

Shader settings follow the language selected in Minecraft. English and Russian are available for profile names, menus, options, and tooltips.

## Profiles

| Setting | Light (default) | Balanced |
| --- | --- | --- |
| Cast shadows | Off. The shadow pass is skipped. | Nearby terrain and cutout foliage cast shadows |
| Shadow map and radius | 512 × 512 and 32 blocks if enabled manually | 512 × 512 and 32 blocks |
| Sky reflection on water | Off | On |
| Water ripples | Off | On |
| Copper edge on stonework | On | On |

**Starting settings for Intel UHD.** For a Core i5-12450H laptop with 16 GB of DDR4, start with **Light**, 1600 × 900, an 8-chunk render distance, a 5-chunk simulation distance, fast clouds, and the default 16× textures. Keep smooth lighting on for shaded corners. If frame pacing is uneven, try 1280 × 720 in the same scene.

The **Near shadows** menu offers map sizes of **256, 512, or 1024 pixels per side** and radii of **16, 32, or 48 blocks**. For lower-cost cast shadows, try 256 pixels and 16 blocks. A wider radius spreads the same texels over more terrain and makes stepped edges more visible.

## Visual features

- **Light and stonework.** The vanilla lightmap preserves torchlight, caves, and night lighting. In the Overworld, sunlight warms exposed faces while shaded faces stay cool. To see the copper edge, stand beside a stone-brick wall facing the low sun. The highlight follows the top of each course and fades with distance.
- **Sky and fog.** The biome’s fog color blends into a deeper sky overhead. A warm band appears near the horizon toward the rising or setting sun. The pack keeps Minecraft’s sun, moon, stars, and clouds.
- **Water.** Light keeps the biome tint, texture animation, and transparency, with a small shift toward turquoise. Balanced adds two animated ripples and a sky reflection that strengthens at shallow viewing angles. Both effects have independent switches and apply only to water.
- **Color grading.** One sample of the finished scene gently lifts midtones and saturation while preserving black and white.

## Rendering and limitations

The pack writes the scene to one color target, `colortex0`. Its only full-screen shader is `final`, which reads the scene once. It uses no history buffers, noise textures, volumetric lighting, ray tracing, or screen-space reflections.

Balanced renders a nearby shadow depth map in the Overworld. Each receiving surface needs at most one hardware-filtered shadow comparison. Shadows fade at the edge of the configured radius. Mobs, the player, block entities, and translucent blocks are excluded as shadow casters. Low resolutions can show stepped edges or a slight offset on thin geometry.

Water reflects the sky gradient only. Ripples change the shading and reflection angle without moving the water mesh. The copper edge applies to the full masonry blocks listed in `shaders/block.properties`. The Nether, End, and other dimensions use the game’s lighting and fog with the shared color grade. The pack has no dedicated Distant Horizons shaders.

## Pack contents

<details>
<summary>Shader programs, configuration, and translations</summary>

Every program listed below includes a vertex shader (`.vsh`) and a fragment shader (`.fsh`).

| Location | Files or programs |
| --- | --- |
| Archive root | `README.md` |
| `shaders/` | `shaders.properties`, `dimension.properties`, `block.properties` |
| `shaders/` base programs | `final`, `gbuffers_block`, `gbuffers_damagedblock`, `gbuffers_entities`, `gbuffers_hand`, `gbuffers_terrain`, `gbuffers_textured_lit` |
| `shaders/overworld/` | The same seven program names, plus `gbuffers_skybasic`, `gbuffers_skytextured`, `gbuffers_water`, and `shadow` |
| `shaders/lib/` | `daylight.glsl`, `sky.glsl`, `settings.glsl`, and the vertex and fragment modules for `scene`, `native`, `unlit`, and `final` |
| `shaders/lang/` | `en_US.lang` (English), `ru_RU.lang` (Russian) |

</details>

To build an installable ZIP from a clone, run this command at the repository root.

```sh
git archive --format=zip --output=DanPotatoShader.zip HEAD README.md shaders
```

## Verification

Offline tests ran on **Intel(R) UHD Graphics**, driver **32.0.101.7088**.

- The Iris 1.8.8 option parser and preprocessor read the ZIP, recognized all six settings and both profiles, and selected Light by default.
- All 18 programs compiled and linked under OpenGL 3.3 in 18 configurations. These covered both profiles and all 16 combinations of the four switches, including the smallest and largest shadow settings. Both profiles also compiled and linked after Iris transformed their shaders for the core profile.
- Pixel readbacks checked shadow depth and cutouts, the copper edge and its material mask, ripple animation and sky reflections, the sky gradient, fog, and the final color grade.

Minecraft has not been launched with this pack. In-game appearance, dimension transitions, and mod compatibility still need testing. Gameplay FPS, frame times, and memory use have not been measured.

## References

The GLSL and settings were written for DanPotatoShader. The following projects informed the implementation.

- Pack structure and program selection follow the [Iris reference](https://shaders.properties/current/reference/overview/), [Iris documentation repository](https://github.com/IrisShaders/docs), and [shaderLABS Base-330](https://github.com/shaderLABS/Base-330).
- The depth map and receiver bias draw on the [shaderLABS Shadow Tutorial](https://github.com/shaderLABS/Shadow-Tutorial).
- Independent effect switches and a shadow-free default were informed by [MakeUp Ultra Fast’s profiles](https://github.com/javiergcim/MakeUpUltraFast/blob/master/shaders/shaders.properties) and [developer notes](https://github.com/javiergcim/MakeUpUltraFast/blob/master/ForDevelopers.EN.md).
- Lighting, atmosphere, and reflection approaches were compared with [Photon](https://github.com/sixthsurge/photon), [Bliss](https://github.com/X0nk/Bliss-Shader), and [Revelation](https://github.com/HaringPro/Revelation).

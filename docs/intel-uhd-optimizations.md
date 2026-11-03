# Where the Intel UHD spent time in 0.2.1

Two isolated experiments changed one shader effect at a time. The tagged star atlas improved frame time in the moonrise scene. A water-wave lookup table closely reproduced the existing ripple, but the lake view ran just as well with the original arithmetic. Version 0.2.2 includes the star optimization and a separate reduction in celestial texture storage.

## Minecraft measurements

Minecraft Java 1.21.1 ran under Fabric Loader 0.20.1, Iris 1.8.14-beta.1 and Sodium 0.8.13 on an i5-12450H and Intel UHD, driver 32.0.101.7088. The Light profile used a 1920 × 1080 framebuffer, render distance 12, simulation distance 5 and VSync off. The camera stayed at a preloaded shoreline. The night view faced the moon. The daytime water test aimed down over the lake.

| Effect isolated | Configuration | Average FPS | Median frame time | 95th percentile |
| --- | --- | ---: | ---: | ---: |
| Night sky | 0.2.1 | 134.3 | 7.41 ms | 9.78 ms |
| Night sky | Tagged atlas | 139.6 | 7.10 ms | 9.26 ms |
| Water | 0.2.1 | 148.9 | 6.64 ms | 8.57 ms |
| Water | 16 KiB wave lookup | 147.8 | 6.67 ms | 8.52 ms |

Each row contains four ten-second captures. Each shader reload was followed by five seconds of warm-up. The order for the night test was A/B, B/A, B/A, A/B. The water test reversed that order. FPS is the frame count divided by the nominal sampling time. The two frame-time columns are medians of the four per-run statistics. The four night pairs all favored the tagged atlas in median frame time. Moving cameras, dense player worlds, chunk generation and other GPU drivers were outside this measurement.

Median frame times for each adjacent pair are shown below in milliseconds. The baseline is listed first in each cell, regardless of capture order.

| View | Pair 1 | Pair 2 | Pair 3 | Pair 4 |
| --- | ---: | ---: | ---: | ---: |
| Moonrise, baseline / tagged sky | 7.349 / 7.094 | 8.093 / 7.062 | 7.430 / 7.104 | 7.382 / 7.135 |
| Lake, baseline / wave table | 6.627 / 6.847 | 6.629 / 6.667 | 6.671 / 6.665 | 6.660 / 6.669 |

The completed 0.2.2 ZIP was also compared against the 0.2.1 release in a second client session. At moonrise, two ten-second captures per pack in A/B/B/A order yielded about 130 FPS for 0.2.1 and 134.5 FPS for 0.2.2. The baseline varied between sessions, so comparisons above use runs from the same session.

## Changes that shipped

**Use the star atlas as a map of where work is needed.** The existing atlas stores galactic dust in red, star position in green and blue, and star intensity in alpha. Only 3.3% of its cells contain a star, but 0.2.1 sampled the dust and evaluated the star shape for every visible night-sky fragment. The new baker examines each red texel and its eight neighbors with edge clamping. An empty cell with constant dust gets tag zero. An empty cell needing filtering gets byte value one. Star cells retain their original intensity and offsets.

One unfiltered read now identifies the cell. About 61.2% of atlas cells can skip the filtered dust read, and the star-shape calculation runs only for a star cell. These are atlas proportions. The mix on screen varies with the camera. The alpha tags use existing storage, and clearing unused position bytes also reduced the PNG from 417,774 to 76,140 bytes. The decoded atlas still occupies 576 KiB. On the Intel driver, ten fixed sky orientations covering both hemispheres and the projection fold produced identical RGB8 output across 5,184,000 pixels.

**Crop transparent padding around the sun and moon.** Each 128 × 128 tile used only its center. The new atlas stores the central 64 × 64 texels of each tile, including a transparent guard border. The sprite shader rejects the cropped margins and remaps the surviving coordinates. This preserves the original disk size, phase UVs, crater detail and filter footprint. Base-level RGBA8 storage fell from 768 to 192 KiB. A CPU comparison of 122,049 bilinearly filtered coordinates, including tile seams and boundaries, had zero channel error. The 576 KiB saving is texture payload, not a measurement of total driver allocation.

## What the reference shaders do differently

| Source | Technique examined | Decision for DanPotatoShader |
| --- | --- | --- |
| MakeUp Ultra Fast | Its developer notes describe an RG8 water-normal map. The water shader can use a sky gradient and evaluate reflected clouds with a smaller step budget. [Developer notes](https://github.com/javiergcim/MakeUpUltraFast/blob/fed6d05f841389fb5981f078e2fcac8dfb9c0080/ForDevelopers.EN.md) · [Water shader](https://github.com/javiergcim/MakeUpUltraFast/blob/fed6d05f841389fb5981f078e2fcac8dfb9c0080/shaders/common/water_blocks_fragment.glsl) | Tested a table indexed by our two periodic wave phases. One bilinear RG8 read replaced four scalar sine evaluations. Over 150,000 phase pairs the maximum absolute wave-component error was 0.00794 on a −1 to +1 scale. The measured result favored keeping the existing water shader. |
| Photon | Its star field interpolates four procedurally generated neighboring cells for stability. A separate sky map serves reflections and lighting. [Stars](https://github.com/sixthsurge/photon/blob/40c887116c70d47c9e7e36cbad3178e04e622746/shaders/include/sky/stars.glsl) · [Sky map](https://github.com/sixthsurge/photon/blob/40c887116c70d47c9e7e36cbad3178e04e622746/shaders/program/d0_sky_map.fsh) | Keep the positions and antialiasing already present. Use tags to skip work in empty cells. |
| Bliss | The water normal uses three height evaluations. Each combines multiple noise scales, and the spacing between height probes changes with distance. [Water normals](https://github.com/X0nk/Bliss-Shader/blob/81e403ed308141039a09d792a36f8eb328898a60/shaders/lib/waterBump.glsl) | Keep two analytic wave phases and their existing distance fade. A layered height field would be a visual upgrade with a different cost. |
| Revelation | Cloud scattering reads a baked 512 × 3 phase-function table indexed by angle and cloud type. [Cloud lookup](https://github.com/HaringPro/Revelation/blob/d5911393856d9dd97375b46a1a088e6b8fddd755/shaders/lib/atmosphere/clouds/PhaseLut.glsl) | Apply the principle of classifying fixed data during the bake to our night texture. The existing two-sample cloud silhouette and one-sample water reflection remain suitable for Light. |
| shaderLABS | Base-330 samples the block texture and lightmap in the terrain fragment shader. Shadow Tutorial demonstrates depth comparison and optional colored shadows. [Base terrain](https://github.com/shaderLABS/Base-330/blob/3722d8b3ad42f251e270b9c0ab6549a9a90a0773/shaders/gbuffers_terrain.fsh) · [Shadow example](https://github.com/shaderLABS/Shadow-Tutorial/blob/4d5a98ccbdb3a6164131e7405399ba6cfd792d49/shaders/gbuffers_terrain.fsh) | DanPotatoShader already samples the lightmap per vertex and uses one hardware depth comparison for nearby shadows. Retain the established shadow appearance and radius. |

The wave experiment also follows the precomputed periodic-wave idea described in *GPU Gems*. Its performance on this Intel driver is reported above. Iris documents raw custom texture formats, filtering and wrapping, which matter for a repeating RG8 table. All experiment code and generated texture data originated in this project. [GPU Gems, chapter 1](https://developer.nvidia.com/gpugems/gpugems/part-i-natural-effects/chapter-1-effective-water-simulation-physical-models) · [Iris texture reference](https://shaders.properties/current/reference/buffers/custom_textures/) · [Iris docs](https://github.com/IrisShaders/docs)

# DanPotatoShader — Linggango / Oculus

**0.2.12 Linggango Oculus preview**, a separate edition of DanPotatoShader for **Minecraft 1.20.1, Forge and Oculus**, aimed at Intel UHD integrated graphics. It keeps the moving clouds, round moon, End sky, island mist, crystal/beam effects, wet stone and shoreline foam of the 1.21.1 edition.

**[Download the Linggango Oculus ZIP](https://github.com/Haigatu/DanPotatoShader/releases/download/v0.2.12-linggango-oculus-preview/DanPotatoShader-0.2.12-Linggango-Oculus-preview.zip)** · [Release notes](https://github.com/Haigatu/DanPotatoShader/releases/tag/v0.2.12-linggango-oculus-preview) · [Standard 1.21.1 Iris edition](https://github.com/Haigatu/DanPotatoShader/tree/main)

## Install in Linggango

The target is **Linggango V6.6.6hf, Minecraft 1.20.1, Forge 47.4.20, Java 17**, with its bundled **Emberlens 1.8.6** (Oculus fork) and **Emberbium 0.3.32-beta.114** (Embeddium fork).

1. Keep Linggango's bundled **Emberlens and Emberbium**. They already provide shader support; do not add a second Oculus or Embeddium JAR alongside them. OptiFine and Fabric Iris/Sodium are not part of this setup.
2. Put `DanPotatoShader-0.2.12-Linggango-Oculus-preview.zip` in this instance's `minecraft/shaderpacks` folder. Keep it zipped.
3. Select it under Video Settings → Shader Packs. Start with **Light**, Fast graphics, **6–8 render chunks** and **5 simulation chunks**. All shader options have Russian and English labels.
4. In **Video Settings → General**, set Emberlens **Shadow Update Interval to 1**. Values 2–4 reuse an older shadow map while the camera moves and cause jumping shadows. This loader setting is outside the shader ZIP.
5. If needed, turn off **Cast shadows / Тени от блоков** first; individual sky, water and material effects also have switches. Lowering resolution to 1600×900 reduces pixel cost. Performance still depends on structures, machines, mobs, resource packs and world generation.

The shader ZIP contains no loader mods. Each Prism instance has its own mods and shaderpacks folders. The pack also passes offline parsing, transformation and Intel compilation using official Oculus 1.8.0, but the full Linggango game test uses its bundled forks.

## Fixes in 0.2.12

- Align the shadow map and its receivers to the same world-anchored texel grid. Crossing the loader's 2-block grid no longer shifts shadow edges by a fractional texel. Integer camera coordinates are split before conversion to float, preserving phase near the world border.
- Require Emberlens's shadow update interval 1; document it in the shadow option tooltips. Skipping shadow updates is a separate loader issue that a shader ZIP cannot override.
- Restore native clouds in other dimensions, including Ad Astra Glacio. Only Overworld vanilla cloud geometry is suppressed when painted clouds are selected; Cloud layer 0 preserves the loader's original fallback.
- Use the water fog color for the End background while submerged, including with island mist disabled.

## Adaptation

- Oculus 1.8.0 supplies numeric biome precipitation values without the newer `PPT_RAIN` macro. The wetness expression uses its rain value directly, so stone can become wet and then dry gradually.
- Oculus draws the dragon's healing beam under the dragon entity ID. Texture proportions distinguish the tall beam from the square dragon texture and the crystal atlas, preserving the dragon's body and the crystal glass/base.
- Vanilla block IDs match 1.20.1: grass is `minecraft:grass`; unavailable 1.21 tuff variants are omitted.
- Wind and soft leaf lighting cover 58 BWG leaf types, 51 short plants and 11 tall plants with separate upper/lower halves. Wet stone and masonry accents include 29 verified full stone blocks from BWG, Create, Quark, Undergarden and Goety. Their installed blockstates and models were checked; stairs, slabs and machines are excluded from the added masonry list.
- Custom dimensions retain their native light, fog and sky through the root programs. The violet End sky and height mist apply to `minecraft:the_end` only.

## Rendering budget

The pack uses one scene color target and no frame history, volumetric ray marching, SSR or bloom chain. Mist is integrated directly, mostly at vertices. Wet stone reuses existing material samples. Foam adds one opaque-depth read on top water surfaces in Light and shares the existing depth read in Balanced. The optional shadow map covers nearby terrain and foliage; entities and translucent geometry do not cast into it.

Special material effects target the explicitly listed blocks in `shaders/block.properties`; machines and arbitrary modded blocks are not automatically treated as glowing or wet stone.

This branch is maintained separately from the Fabric/Iris 1.21.1 edition. Measurements and actual validation conditions for this release are recorded in its release notes.

Tested in a separate copy of Linggango with the bundled loader forks on Intel UHD Graphics: 1920×1080, Fast, 8 render / 5 simulation chunks, 8 GB Java heap. Validation includes continuous camera movement, negative coordinates/world-border precision, submersion, native dimension clouds, shader option combinations and actual Intel compilation. Current paired performance measurements are in the release notes; they are scene measurements, not a minimum-FPS guarantee for busy bases or chunk generation.

## References

Uses RustingShader by Vasyl Trefilov. The offline generator adapts its lunar phase lighting, removes the procedural craters and bakes eight antialiased sprites with a short glow along the lit edge. The faint surface markings use the 2019 lunar color map by Ernie Wright, NASA's Scientific Visualization Studio, from LRO camera and altimeter data. Their contrast is reduced for a bright disk at game scale. The moon and its glow use one atlas read in game. [Original lunar shader](https://github.com/RustingStudio/RustingShader/blob/b1a6b978bb12820c67c1b952f0e073ba8e08fd22/shaders/lib/common.glsl#L141-L210) · [RustingShader License 1.0](shaders/licenses/RustingShader.md) · [NASA CGI Moon Kit](https://svs.gsfc.nasa.gov/4720/)

The GLSL and cloud texture were created for this pack. Structure and shadow mapping follow the [Iris reference](https://shaders.properties/current/reference/overview/), [Iris documentation repository](https://github.com/IrisShaders/docs), [Base-330](https://github.com/shaderLABS/Base-330), and [Shadow Tutorial](https://github.com/shaderLABS/Shadow-Tutorial). Independent quality controls were informed by [MakeUp Ultra Fast](https://github.com/javiergcim/MakeUpUltraFast) and its [developer notes](https://github.com/javiergcim/MakeUpUltraFast/blob/master/ForDevelopers.EN.md). Additional visual references included [Photon](https://github.com/sixthsurge/photon), [Bliss](https://github.com/X0nk/Bliss-Shader), and [Revelation](https://github.com/HaringPro/Revelation).

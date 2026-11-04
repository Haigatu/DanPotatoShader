"""Bake seamless violet dust and star masks for the two portal layers."""
from pathlib import Path
import numpy as np
from PIL import Image

size = 256
rng = np.random.default_rng(210)
y, x = np.indices((size, size)) * (2 * np.pi / size)
grain = np.zeros((size, size))
for frequency, amplitude in [(2, .46), (5, .26), (12, .16), (23, .08), (39, .04)]:
    lattice = rng.random((frequency, frequency))
    tiled = Image.fromarray(np.tile(lattice, (3, 3)).astype('float32'))
    field = tiled.resize((3 * size, 3 * size), Image.Resampling.BICUBIC)
    grain += amplitude * np.asarray(field)[size:2 * size, size:2 * size]

ribbon = np.abs(np.sin(x + y + .84*np.sin(y) + .45*np.cos(2*x-y) + 2.4*(grain-.5)))
dust = np.clip((1.05-ribbon) * (.24 + 1.1*grain), 0, 1) ** 1.6
stars = np.zeros_like(dust)
for _ in range(184):
    row, col = rng.integers(size, size=2)
    strength = rng.uniform(.32, 1.)
    stars[row,col] = strength
    for dy, dx in [(-1,0),(1,0),(0,-1),(0,1)]:
        iy, ix = (row+dy) % size, (col+dx) % size
        stars[iy,ix] = max(stars[iy,ix], .22*strength)
filaments = np.exp(-12*ribbon) * grain
pixels = np.stack((dust,stars,filaments), axis=-1)
dest = Path(__file__).resolve().parents[1]/'shaders/textures/portal-field.png'
Image.fromarray((255*pixels).round().astype('uint8')).save(dest, optimize=True)

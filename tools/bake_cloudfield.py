"""Bake tileable cumulus lobes, lighting normals, and filtered water coverage."""
from pathlib import Path
import numpy as np
from PIL import Image

rng = np.random.default_rng(4221)
size = 256
y, x = np.indices((size, size)) / size

def noise(n):
    grid = rng.uniform(-1, 1, (n, n))
    ix, iy = np.floor(x*n).astype(int), np.floor(y*n).astype(int)
    fx, fy = x*n-ix, y*n-iy
    fx, fy = fx*fx*(3-2*fx), fy*fy*(3-2*fy)
    def row(k):
        return grid[k%n, ix%n]*(1-fx) + grid[k%n, (ix+1)%n]*fx
    return row(iy)*(1-fy) + row(iy+1)*fy

# Groups of touching ellipsoids give the canopy a broken, scalloped outline.
u, v = x + 0.020*noise(12) + 0.009*noise(29) + 0.002*noise(77), y + 0.020*noise(12) + 0.009*noise(29) + 0.002*noise(77)
height = np.full_like(x, -2.0)
for cx, cy, scale in [(0.12,0.18,1.1),(0.48,0.15,0.78),(0.78,0.32,1.1),
                      (0.31,0.55,1.32),(0.77,0.77,1.05),(0.12,0.89,0.68)]:
    ex = ((u-cx+0.5)%1-0.5)/(0.14*scale)
    ey = ((v-cy+0.5)%1-0.5)/(0.073*scale)
    height = np.maximum(height,0.57*(1-ex*ex-ey*ey))
    for _ in range(28):
        bx, by = rng.normal([cx,cy], [0.065*scale,0.034*scale])
        radius = rng.uniform(0.020,0.068)*scale
        dx = ((u-bx+0.5)%1-0.5)/radius
        dy = ((v-by+0.5)%1-0.5)/(radius*rng.uniform(0.80,1.15))
        lobe = (1-dx*dx-dy*dy)*rng.uniform(0.70,1.05)
        # A soft maximum rounds the join without erasing the individual lobes.
        join = np.maximum(0.13-np.abs(height-lobe), 0.0)
        height = np.maximum(height,lobe) + join*join/0.52
height += 0.15*noise(24) + 0.085*noise(48) + 0.043*noise(93)
density = np.clip(0.48 + 0.47*height,0,1)
dx = np.roll(density,1,1) - np.roll(density,-1,1)
dy = np.roll(density,1,0) - np.roll(density,-1,0)
coverage = np.clip((density-0.43)/0.16,0,1)
freq = np.fft.fftfreq(size)
kernel = np.exp(-2*np.pi**2*8.5**2*(freq[:,None]**2+freq[None,:]**2))
soft = np.fft.ifft2(np.fft.fft2(coverage)*kernel).real
atlas = np.stack((density,0.5+2.4*dx,0.5+2.4*dy,soft),axis=-1)
out = Path(__file__).resolve().parents[1] / 'shaders/textures/cloudfield.png'
Image.fromarray(np.rint(np.clip(atlas,0,1)*255).astype('uint8')).save(out,optimize=True)

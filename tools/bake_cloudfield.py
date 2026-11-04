"""Bake tileable cumulus lobes, their open lighting direction, and water coverage."""
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


def open_direction(field, radii, height_scale):
    """Horizontal moment of the visible sky above a periodic height field."""
    moment = np.zeros((*field.shape, 2))
    for angle in np.arange(16) * (2*np.pi / 16):
        direction = np.array([np.cos(angle), np.sin(angle)])
        slope = np.zeros_like(field)
        for radius in radii:
            sx, sy = np.rint(radius * direction).astype(int)
            # A negative roll fetches the neighbour in the positive UV direction.
            ahead = np.roll(field, (-sy, -sx), axis=(0, 1))
            slope = np.maximum(slope, (ahead-field) * height_scale / np.hypot(sx, sy))
        # Integral of cos(elevation)^2 up to the horizon, scaled to [0,1].
        # The open sky points away from the part hidden by taller neighbours.
        blocked = (2/np.pi) * (np.arctan(slope) + slope/(1+slope*slope))
        moment -= blocked[:, :, None] * direction
    return moment / 16

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
coverage = np.clip((density-0.43)/0.16,0,1)
freq = np.fft.fftfreq(size)
freq_squared = freq[:,None]**2 + freq[None,:]**2

def periodic_blur(field, sigma):
    kernel = np.exp(-2*np.pi**2 * sigma**2 * freq_squared)
    return np.fft.ifft2(np.fft.fft2(field)*kernel).real

# Resolve nearby lobes and the wider bank separately so small ridges do not
# hide the open side of the whole bank. Radii and vertical relief are in texels.
lobes = open_direction(periodic_blur(density, 1.65), (3, 6, 10), 26)
bank = open_direction(periodic_blur(density, 6.0), (6, 12, 22, 34), 60)
tilt = 5.5 * (0.48*lobes + 0.52*bank)
# Project a unit-up vector tilted toward the open sky onto the texture plane.
normal = tilt / np.sqrt(1.0 + np.sum(tilt*tilt, axis=-1, keepdims=True))
soft = periodic_blur(coverage, 8.5)
atlas = np.dstack((density, 0.5 + 0.5*normal, soft))
out = Path(__file__).resolve().parents[1] / 'shaders/textures/cloudfield.png'
Image.fromarray(np.rint(np.clip(atlas,0,1)*255).astype('uint8')).save(out,optimize=True)

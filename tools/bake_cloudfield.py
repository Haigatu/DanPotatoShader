"""Bake one periodic density field and its two horizontal lighting slopes."""
from pathlib import Path
import numpy as np
from PIL import Image

rng = np.random.default_rng(4221)
y, x = np.indices((256, 256)) / 256.0
def noise(nx, ny, u, v):
    grid = rng.uniform(-1, 1, (ny, nx))
    a, b = u * nx, v * ny
    ix, iy = np.floor(a).astype(int), np.floor(b).astype(int)
    fx, fy = a-ix, b-iy
    fx, fy = fx*fx*(3-2*fx), fy*fy*(3-2*fy)
    def row(k):
        return grid[k%ny,ix%nx]*(1-fx) + grid[k%ny,(ix+1)%nx]*fx
    return row(iy)*(1-fy) + row(iy+1)*fy

u = x + 0.073*noise(4,4,x,y)
v = y + 0.069*noise(4,4,x,y)
shape = 0.58*noise(4,6,u,v) + 0.32*noise(9,13,u,v) + 0.14*noise(22,31,u,v) + 0.07*noise(51,62,u,v)
density = np.clip(0.49 + shape*0.80,0,1)
dx = np.roll(density,-2,axis=1)-np.roll(density,2,axis=1)
dy = np.roll(density,-2,axis=0)-np.roll(density,2,axis=0)
freq=np.fft.fftfreq(256)
kernel=np.exp(-2*np.pi**2*4.5**2*(freq[:,None]**2+freq[None,:]**2))
broad=np.fft.ifft2(np.fft.fft2(density)*kernel).real
rgb = np.stack((density,0.5+dx*1.7,0.5+dy*1.7,broad),axis=-1)
out = Path(__file__).resolve().parents[1] / 'shaders/textures/cloudfield.png'
Image.fromarray(np.rint(np.clip(rgb,0,1)*255).astype('uint8')).save(out,optimize=True)

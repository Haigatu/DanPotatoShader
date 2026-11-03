"""Bake starlight and dust lanes onto a continuous octahedral sky map."""
from pathlib import Path
import numpy as np
from PIL import Image

size = 384
rng = np.random.default_rng(12041)
y,x = (np.indices((size,size)) + 0.5) * 2/size - 1
z = 1 - np.abs(x) - np.abs(y)
x,y = np.where(z<0,(1-np.abs(y))*np.sign(x),x), np.where(z<0,(1-np.abs(x))*np.sign(y),y)
length = np.sqrt(x*x+y*y+z*z)
x,y,z = x/length,y/length,z/length
def noise(freq, waves):
    result = np.zeros_like(x)
    for direction,phase in zip(rng.normal(size=(waves,3)),rng.uniform(-np.pi,np.pi,waves)):
        a,b,c = direction/np.linalg.norm(direction)
        result += np.sin(freq*(a*x+b*y+c*z)+phase)
    return result/np.sqrt(waves)

lat = 0.78*x + 0.53*y + 0.33*z
warp = 0.026*noise(12,8)
belt = np.exp(-((lat+warp)/0.17)**2)
rift = np.exp(-((lat+warp+0.032*noise(21,8))/0.039)**2)
knots = np.clip(0.70+0.25*noise(15,9)+0.13*noise(44,8)+0.055*noise(94,6),0.16,1.5)
dust = belt*knots*(1-0.72*rift)
# R is a continuous dust lane. Each texel also describes one candidate star
# as an offset and an intensity; the shader reconstructs a sub-texel point.
present = rng.random(x.shape) < (0.018 + 0.11*belt)
brightness = np.where(present,0.22+0.78*rng.random(x.shape)**2,0)
atlas = np.stack((dust,rng.random(x.shape),rng.random(x.shape),brightness),axis=-1)
out = Path(__file__).resolve().parents[1] / 'shaders/textures/night-sky.png'
pixels = np.rint(np.clip(atlas,0,1)*255).astype('uint8')
red = pixels[:,:,0]
padded = np.pad(red,1,mode='edge')
needs_filter = np.zeros_like(red,dtype=bool)
for dy in range(3):
    for dx in range(3):
        needs_filter |= red != padded[dy:dy+size,dx:dx+size]
# Alpha 0: constant dust. Alpha 1: filter dust. Higher values are star intensities.
empty = pixels[:,:,3] == 0
pixels[empty,1:3] = 0
pixels[empty & needs_filter,3] = 1
Image.fromarray(pixels).save(out,optimize=True)

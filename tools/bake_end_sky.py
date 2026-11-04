"""Bake a seamless horizontal field of pillar strength, height and hue."""
from pathlib import Path
import numpy as np
from PIL import Image

size = 256
rng = np.random.default_rng(28042)
y,x = (np.indices((size,size))+.5)/size

def noise(cells):
    values = rng.uniform(-1,1,(cells,cells))
    u,v = x*cells,y*cells
    i,j = u.astype(int),v.astype(int)
    s,t = u-i,v-j
    s,t = s*s*(3-2*s),t*t*(3-2*t)
    a = (1-s)*values[j,i]+s*values[j,(i+1)%cells]
    b = (1-s)*values[(j+1)%cells,i]+s*values[(j+1)%cells,(i+1)%cells]
    return a+(b-a)*t

flow = .70*noise(8)+.27*noise(16)+.08*noise(30)
veil = .5+.5*noise(6)
ridge = np.exp(-(flow/.19)**2)
strength = .09+.42*veil+.52*ridge*(.50+.50*veil)
height = .5+.36*noise(7)+.12*noise(20)
hue = .5+.40*noise(5)+.10*noise(13)
# Independent stars scattered in solid angle, stored in the fourth channel.
stars = np.zeros_like(strength)
points = rng.normal(size=(1600,3))
uv = points[:,:2]/np.sum(abs(points),axis=1,keepdims=True)
uv = np.where(points[:,2:3]<0,(1-abs(uv[:,::-1]))*np.sign(uv),uv)
ix,iy = np.floor((uv.T*.5+.5)*size).astype(int)
np.maximum.at(stars,(iy,ix),.30+.70*rng.random(len(points))**1.5)
field = np.clip(np.stack([strength,height,hue,stars],axis=-1),0,1)
out = Path(__file__).resolve().parents[1]/'shaders/textures/end-field.png'
Image.fromarray(np.rint(255*field).astype('uint8')).save(out,optimize=True)

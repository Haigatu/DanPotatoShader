"""Bake the solar disk and eight lunar phases into the cropped sprite atlas."""
from pathlib import Path
import numpy as np
from PIL import Image

stored = 64
atlas = Image.new('RGBA',(4*stored,3*stored))


def grid(scale, samples=1):
    y,x = np.indices((stored*samples,stored*samples)) + 0.5
    pitch = scale/(stored*2*samples)
    return (x-stored*samples/2)*pitch,(y-stored*samples/2)*pitch


def sprite(color, edge):
    data = np.dstack((color*edge[:,:,None],edge))
    return Image.fromarray(np.rint(255*np.clip(data,0,1)).astype('uint8'))


def moon_phases(x, y):
    """Bake only the smooth-sphere phase lighting from RustingShader's moonColor.

    Original by Vasyl Trefilov, commit b1a6b978bb12820c67c1b952f0e073ba8e08fd22.
    See shaders/licenses/RustingShader.md.
    """
    z = np.sqrt(np.maximum(1-x*x-y*y,0))
    radius = np.hypot(x,y)
    # The NASA CGI Moon Kit map is equirectangular and centered on the near side.
    source = np.asarray(Image.open(Path(__file__).parent/'assets/lroc_color_poles_1k.jpg').convert('L'))
    h,w = source.shape
    u = .5 + np.arctan2(x,z)/(2*np.pi)
    v = .5 + np.arcsin(np.clip(y,-1,1))/np.pi
    albedo = np.clip((source[np.clip((v*h).astype(int),0,h-1),(u*w).astype(int)]-64.)/106.,0,1)
    surface = (.95+.10*albedo)[:,:,None]
    for phase in range(8):
        angle = phase*np.pi/4
        nl = z*np.cos(angle) - x*np.sin(angle)
        incidence = .5*(nl + np.sqrt(nl*nl + .0064))
        terminator = np.clip((nl+.18)/.42,0,1)
        terminator *= terminator*(3-2*terminator)
        diffuse = incidence/np.maximum(incidence+z,.025)
        light = terminator*(.27*incidence + 1.20*diffuse)
        earth = .007 + .003*(1-np.cos(angle))
        color = light[:,:,None]*np.array([1.,.975,.93]) + earth*np.array([.56,.66,.88])
        disk = surface*1.21*color/(.31+color)
        limb = .27*np.cos(angle) - x/np.maximum(radius,.001)*np.sin(angle)
        glow = .22*np.exp(-13*np.maximum(radius-1,0))*np.clip((limb+.04)/.30,0,1)
        yield np.where((radius<=1)[:,:,None],disk,glow[:,:,None]*np.array([.88,.92,1.]))


# The same smooth sun and transparent filter border as the original 128px tile.
x,y = grid(5.8)
rr = x*x+y*y
z = np.sqrt(np.maximum(1-rr,0))
edge = np.clip((1-np.sqrt(rr))*128/5.8+.5,0,1)
sun = np.array([1.,.73,.34]) + z[:,:,None]*np.array([0.,.24,.46])
atlas.paste(sprite(sun,edge),(0,2*stored))

# The vanilla quad spans 40 units at distance 100. Match starsOutsideMoon's radius.
scale = 0.40/0.05
ss = 4
x,y = grid(scale,ss)
edge = np.clip((1.34-np.hypot(x,y))*22,0,1)
for index,color in enumerate(moon_phases(x,y)):
    # Average each premultiplied channel exactly once, including partial limb texels.
    rgba = np.dstack((color*edge[:,:,None],edge))
    rgba = rgba.reshape(stored,ss,stored,ss,4).mean(axis=(1,3))
    disk = Image.fromarray(np.rint(255*np.clip(rgba,0,1)).astype('uint8'))
    atlas.paste(disk,((index%4)*stored,(index//4)*stored))

out = Path(__file__).resolve().parents[1]/'shaders/textures/celestial.png'
atlas.save(out,optimize=True)

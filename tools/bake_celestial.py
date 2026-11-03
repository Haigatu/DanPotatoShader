"""Paint the solar disk and an eight-phase lunar atlas at build time."""
from pathlib import Path
import numpy as np
from PIL import Image

tile = 128
y,x = (np.indices((tile,tile)) + 0.5) / tile - 0.5
atlas = np.zeros((3*tile,4*tile,4),dtype='uint8')
for index in range(9):
    sun = index == 8
    px,py = (5.8 if sun else 5.3)*x, (5.8 if sun else 5.3)*y
    rr = px*px+py*py
    nz = np.sqrt(np.maximum(1-rr,0))
    # Minecraft adds sky sprites. Premultiply the feather to keep black borders clean.
    edge = np.clip((1-np.sqrt(rr))*tile/(5.8 if sun else 5.3)+0.5,0,1)
    if sun:
        color = np.array([1.,.73,.34]) + nz[:,:,None]*np.array([0.,.24,.46])
    else:
        angle=index*np.pi/4
        lit=np.clip((nz*np.cos(angle)-px*np.sin(angle)+.075)/.18,0,1)
        lit=lit*lit*(3-2*lit)
        a=((px-.16)*2.5)**2+((py+.17)*3.2)**2
        b=((px+.32)*4.0)**2+((py+.29)*3.1)**2
        relief=.79+.19*nz-.16*np.clip((1.12-np.minimum(a,b))/.55,0,1)
        for cx,cy,r in [(-.39,.41,.135),(.43,.30,.085),(.26,-.42,.082),(-.54,-.24,.064),(.03,.60,.06)]:
            dist=np.sqrt((px-cx)**2+(py-cy)**2)/r
            relief+=.080*np.exp(-((dist-.92)/.23)**2)-.075*np.exp(-(dist/.68)**2)
        earth=np.array([.021,.030,.050])
        color=earth+lit[:,:,None]*(relief[:,:,None]*np.array([.86,.90,.99])-earth)
    data=np.dstack((color*edge[:,:,None],edge))
    row,col=divmod(index,4)
    atlas[row*tile:(row+1)*tile,col*tile:(col+1)*tile]=np.rint(255*np.clip(data,0,1)).astype('uint8')
out=Path(__file__).resolve().parents[1]/'shaders/textures/celestial.png'
Image.fromarray(atlas).save(out,optimize=True)

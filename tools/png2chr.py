#!/usr/bin/env python

# this script converts any image to a char map compatible with the 
# assembler's .chr directive 

import sys 
import os
from PIL import Image
from itertools import product

if len(sys.argv) < 2:
    print("Usage: png2chr.py <source>")
    sys.exit(-1)

# these colors are mapped
# maps color tuple to .chr string 
COLORS = {(0, 0, 0, 255): '3', (0, 0, 0, 0): '0', (107, 107, 107, 255): '1', (181, 181, 181, 255): '2', (255, 255, 255, 255): '0'}

src = sys.argv[1]

def tile(src, d):
    img = Image.open(src)
    w, h = img.size 
    tile_index = 0
    
    # split the image into even tiles 
    grid = product(range(0, h-h%d, d), range(0, w-w%d, d))
    for i, j in grid:
        box = (j, i, j+d, i+d)
        cropped = img.crop(box)
        cw, ch = cropped.size
        cropped = cropped.load()

        print('; tile ' + str(tile_index))
        tile_index += 1
        for y in range(0, ch):
            print(".chr ", end='')
            for x in range(0, cw): 
                color = cropped[x, y]
                if color in COLORS:
                    print(COLORS[color], end='')
                else:
                    print('Unknown color: ' + str(cropped[x,y]))
                    sys.exit(-1)
            print("")

tile(src, 8)

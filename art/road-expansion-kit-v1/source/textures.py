"""Lossless PNGs for the shared material palette and the six skybox faces."""
import math
import random
import struct
import zlib


def png(width, height, rgb):
    def chunk(kind, data):
        return (struct.pack('>I', len(data)) + kind + data
                + struct.pack('>I', zlib.crc32(kind + data)))
    # These textures use a small, exact set of colours. One index per pixel
    # preserves even the faint stars without storing three colour channels.
    colors = {}
    indices = bytearray()
    for pixel in struct.iter_unpack('3B',rgb):
        indices.append(colors.setdefault(pixel,len(colors)))
    stride = width
    rows = b''.join(bytes([0]) + indices[y*stride:(y+1)*stride] for y in range(height))
    table = bytes(channel for pixel in colors for channel in pixel)
    header = struct.pack('>2I5B', width, height, 8, 3, 0, 0, 0)
    return (bytes.fromhex('89504e470d0a1a0a') + chunk(b'IHDR', header)
            + chunk(b'PLTE',table) + chunk(b'IDAT',zlib.compress(rows,9)) + chunk(b'IEND',b''))


def palette(assets):
    from mesh import color
    swatches = sorted({hexcode for a in assets.values() for faces in a.faces.values() for _, hexcode in faces})
    cols = 16
    rows = 2**math.ceil(math.log2(math.ceil(len(swatches)/cols)))
    cell = 8
    coords = {}
    for i, swatch in enumerate(swatches):
        coords[color(swatch)] = ((i%cols + .5)/cols, (i//cols + .5)/rows)
    swatches.extend(['FFFFFF']*(rows*cols-len(swatches)))
    pixels = bytearray()
    for row in range(rows):
        line = b''.join(bytes.fromhex(s)*cell for s in swatches[row*cols:(row+1)*cols])
        pixels.extend(line*cell)
    return png(cols*cell, rows*cell, pixels), coords


def sky(directory):
    directory.mkdir(exist_ok=True, parents=True)
    size = 512
    for side, face in enumerate(('Bk', 'Dn', 'Ft', 'Lf', 'Rt', 'Up')):
        rng = random.Random(7185 + side)
        sky = bytearray(bytes((15, 22, 40))*size**2)
        def pixel(x,y,rgb):
            i = 3*(y*size+x)
            sky[i:i+3] = bytes(rgb)
        for _ in range(410):
            x,y = rng.randrange(3,size-3),rng.randrange(3,size-3)
            v = rng.randint(65,218)
            pixel(x,y,(int(v*.82), int(v*.9), v))
            if rng.random()<.15:
                for dx,dy in [(-1,0),(1,0),(0,1),(0,-1)]:
                    pixel(x+dx,y+dy,(v//4,v//4,v//3))
        (directory / f'Skybox{face}.png').write_bytes(png(size,size,sky))

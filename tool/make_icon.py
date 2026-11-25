"""Generates QuickPDF launcher icon PNGs into assets/icon (run: python3 tool/make_icon.py)."""
from PIL import Image, ImageDraw, ImageFont
import glob

S = 1024
BLUE = (37, 99, 235, 255)
DEEP = (30, 27, 75, 255)

def font(size):
    for p in glob.glob('/usr/share/fonts/**/Inter-ExtraBold.otf', recursive=True) + \
             glob.glob('/usr/share/fonts/**/Inter-Bold.otf', recursive=True) + \
             glob.glob('/usr/share/fonts/**/DejaVuSans-Bold.ttf', recursive=True):
        return ImageFont.truetype(p, size)
    return ImageFont.load_default()

def foreground(scale=1.0):
    """Transparent layer: white document with folded corner, PDF label and bolt.
    scale<1 keeps content inside the adaptive-icon safe zone (66%)."""
    k = 4  # supersample
    W = S * k
    im = Image.new('RGBA', (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx = cy = W // 2
    dw, dh = int(470 * scale * k), int(600 * scale * k)  # doc size
    x0, y0 = cx - dw // 2, cy - dh // 2
    x1, y1 = x0 + dw, y0 + dh
    fold = int(150 * scale * k)
    r = int(40 * scale * k)
    # soft shadow
    sh = Image.new('RGBA', (W, W), (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle((x0, y0 + 14 * k, x1, y1 + 14 * k), r, fill=(15, 23, 80, 90))
    from PIL import ImageFilter
    im = Image.alpha_composite(im, sh.filter(ImageFilter.GaussianBlur(18 * k)))
    d = ImageDraw.Draw(im)
    # page body with cut corner
    d.polygon([(x0 + r, y0), (x1 - fold, y0), (x1, y0 + fold), (x1, y1 - r), (x1 - r, y1), (x0 + r, y1), (x0, y1 - r), (x0, y0 + r)], fill='white')
    for (ax, ay) in [(x0 + r, y0 + r), (x1 - r, y1 - r), (x0 + r, y1 - r)]:
        d.ellipse((ax - r, ay - r, ax + r, ay + r), fill='white')
    # fold triangle
    d.polygon([(x1 - fold, y0), (x1, y0 + fold), (x1 - fold, y0 + fold)], fill=(203, 213, 245, 255))
    # PDF label bar
    bw, bh = int(300 * scale * k), int(110 * scale * k)
    bx0 = cx - bw // 2
    by0 = y0 + int(270 * scale * k)
    d.rounded_rectangle((bx0, by0, bx0 + bw, by0 + bh), int(22 * scale * k), fill=(225, 29, 72, 255))
    f = font(int(86 * scale * k))
    d.text((cx, by0 + bh // 2), 'PDF', font=f, fill='white', anchor='mm')
    # lightning bolt (speed)
    bs = scale * k
    bolt = [(-30, -120), (70, -120), (15, -25), (85, -25), (-45, 125), (-5, 15), (-75, 15)]
    bx, by = cx, y0 + int(150 * scale * k)
    pts = [(bx + px * 0.62 * bs, by + py * 0.62 * bs) for px, py in bolt]
    d.polygon(pts, fill=BLUE)
    # lines under label
    for i, w in enumerate((300, 220)):
        ly = by0 + bh + int((55 + i * 50) * scale * k)
        d.rounded_rectangle((bx0, ly, bx0 + int(w * scale * k), ly + int(20 * scale * k)), int(10 * scale * k), fill=(203, 213, 245, 255))
    return im.resize((S, S), Image.LANCZOS)

def background():
    im = Image.new('RGBA', (S, S))
    px = im.load()
    for y in range(S):
        for x in range(S):
            t = (x + y) / (2 * S)
            px[x, y] = tuple(int(BLUE[i] * (1 - t) + (29, 78, 216, 255)[i] * t) for i in range(4))
    return im

bg = background()
bg.save('assets/icon/background.png')
foreground(0.78).save('assets/icon/foreground.png')       # adaptive (safe zone)
full = Image.alpha_composite(bg, foreground(1.2))
full.save('assets/icon/icon.png')                          # legacy square icon

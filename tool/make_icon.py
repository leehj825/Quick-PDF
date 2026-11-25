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
    """Transparent layer: big white document with folded corner, bolt, PDF label and text lines.
    Design units are for scale=1.0 on a 1024 canvas. The adaptive layer uses ~0.80 so the
    document's corners stay inside the launcher's circular mask (72dp visible of 108dp)."""
    from PIL import ImageFilter
    k = 4  # supersample
    W = S * k
    im = Image.new('RGBA', (W, W), (0, 0, 0, 0))
    cx = cy = W // 2
    u = scale * k  # design unit -> pixels
    dw, dh = int(540 * u), int(660 * u)
    x0, y0 = cx - dw // 2, cy - dh // 2
    x1, y1 = x0 + dw, y0 + dh
    fold = int(150 * u)
    r = int(44 * u)
    # soft shadow
    sh = Image.new('RGBA', (W, W), (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle((x0, y0 + 12 * k, x1, y1 + 12 * k), r, fill=(15, 23, 80, 80))
    im = Image.alpha_composite(im, sh.filter(ImageFilter.GaussianBlur(16 * k)))
    d = ImageDraw.Draw(im)
    # page body with cut corner
    d.polygon([(x0 + r, y0), (x1 - fold, y0), (x1, y0 + fold), (x1, y1 - r), (x1 - r, y1), (x0 + r, y1), (x0, y1 - r), (x0, y0 + r)], fill='white')
    for (ax, ay) in [(x0 + r, y0 + r), (x1 - r, y1 - r), (x0 + r, y1 - r)]:
        d.ellipse((ax - r, ay - r, ax + r, ay + r), fill='white')
    d.polygon([(x1 - fold, y0), (x1, y0 + fold), (x1 - fold, y0 + fold)], fill=(203, 213, 245, 255))
    # lightning bolt (speed) - large
    bolt = [(-30, -120), (70, -120), (15, -25), (85, -25), (-45, 125), (-5, 15), (-75, 15)]
    bx, by = cx - int(60 * u), y0 + int(170 * u)
    d.polygon([(bx + px * 0.95 * u, by + py * 0.95 * u) for px, py in bolt], fill=BLUE)
    # PDF label bar (wide)
    bw, bh = int(440 * u), int(150 * u)
    bx0, by0 = cx - bw // 2, y0 + int(330 * u)
    d.rounded_rectangle((bx0, by0, bx0 + bw, by0 + bh), int(28 * u), fill=(225, 29, 72, 255))
    d.text((cx, by0 + bh // 2), 'PDF', font=font(int(124 * u)), fill='white', anchor='mm')
    # text lines
    for i, w in enumerate((440, 320)):
        ly = y0 + int((522 + i * 50) * u)
        d.rounded_rectangle((bx0, ly, bx0 + int(w * u), ly + int(24 * u)), int(12 * u), fill=(203, 213, 245, 255))
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
foreground(0.80).save('assets/icon/foreground.png')       # adaptive (corners inside the circular mask)
full = Image.alpha_composite(bg, foreground(1.3))
full.save('assets/icon/icon.png')                          # legacy square icon

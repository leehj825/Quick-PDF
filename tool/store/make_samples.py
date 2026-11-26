"""Generates fictional sample documents (no real data) used by the store screenshots.
Usage: python3 tool/store/make_samples.py build/store/samples"""
import sys, os, random, glob
from PIL import Image, ImageDraw, ImageFont, ImageFilter

out = sys.argv[1] if len(sys.argv) > 1 else 'build/store/samples'
os.makedirs(out, exist_ok=True)
random.seed(7)

def font(size, bold=False):
    names = ['Inter-Bold.otf', 'Inter-SemiBold.otf'] if bold else ['Inter-Regular.otf', 'Inter-Medium.otf']
    for n in names:
        for p in glob.glob(f'/usr/share/fonts/**/{n}', recursive=True):
            return ImageFont.truetype(p, size)
    return ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans%s.ttf' % ('-Bold' if bold else ''), size)

W, H = 1200, 1600

def paper(bg=(252, 252, 250)):
    im = Image.new('RGB', (W, H), bg)
    return im, ImageDraw.Draw(im)

def lines(d, x, y, n, w, gap=44, color=(70, 76, 90)):
    for i in range(n):
        ww = w if i % 4 != 3 else int(w * 0.6)
        d.rounded_rectangle((x, y + i * gap, x + ww, y + i * gap + 16), 8, fill=color)

def invoice():
    im, d = paper()
    d.text((90, 90), 'INVOICE', font=font(84, True), fill=(30, 41, 90))
    d.text((90, 200), 'No. 2026-0412   ·   Sample Studio Ltd.', font=font(34), fill=(90, 98, 120))
    d.rectangle((90, 290, W - 90, 296), fill=(37, 99, 235))
    d.text((90, 330), 'Bill to', font=font(30, True), fill=(30, 41, 90)); lines(d, 90, 385, 3, 420)
    d.text((700, 330), 'Date', font=font(30, True), fill=(30, 41, 90)); lines(d, 700, 385, 2, 300)
    y = 560
    d.rectangle((90, y, W - 90, y + 64), fill=(226, 232, 250))
    for x, t in ((110, 'Item'), (700, 'Qty'), (860, 'Price'), (1000, 'Total')):
        d.text((x, y + 14), t, font=font(30, True), fill=(30, 41, 90))
    for i in range(6):
        yy = y + 90 + i * 74
        lines(d, 110, yy + 12, 1, 460, color=(110, 118, 140))
        for x in (710, 870, 1010):
            d.rounded_rectangle((x, yy + 12, x + 70, yy + 28), 8, fill=(110, 118, 140))
        d.rectangle((90, yy + 56, W - 90, yy + 58), fill=(230, 233, 240))
    d.text((760, 1180), 'Total', font=font(44, True), fill=(30, 41, 90))
    d.text((930, 1180), '$ 1,284.00', font=font(44, True), fill=(225, 29, 72))
    lines(d, 90, 1340, 4, 700)
    return im

def letter():
    im, d = paper()
    d.text((90, 90), 'Sample Studio Ltd.', font=font(46, True), fill=(30, 41, 90))
    lines(d, 90, 170, 2, 380)
    d.text((90, 330), 'Dear Applicant,', font=font(36), fill=(60, 66, 84))
    lines(d, 90, 410, 18, 1020, gap=50)
    d.text((90, 1400), 'Sincerely,', font=font(36), fill=(60, 66, 84))
    return im

def receipt():
    im = Image.new('RGB', (W, H), (252, 251, 247))
    d = ImageDraw.Draw(im)
    d.text((600, 110), 'SAMPLE MARKET', font=font(70, True), fill=(40, 40, 46), anchor='mm')
    d.text((600, 190), '123 Example Street', font=font(34), fill=(100, 100, 110), anchor='mm')
    d.line((120, 250, W - 120, 250), fill=(150, 150, 160), width=3)
    for i in range(11):
        y = 300 + i * 90
        d.rounded_rectangle((130, y, 130 + random.choice((420, 520, 360, 470)), y + 22), 10, fill=(70, 70, 80))
        d.rounded_rectangle((900, y, 1060, y + 22), 10, fill=(70, 70, 80))
    d.line((120, 1320, W - 120, 1320), fill=(150, 150, 160), width=3)
    d.text((130, 1370), 'TOTAL', font=font(60, True), fill=(30, 30, 36))
    d.text((1070, 1370), '42.90', font=font(60, True), fill=(30, 30, 36), anchor='ra')
    return im

def idcard():
    im, d = paper((236, 240, 248))
    d.rounded_rectangle((110, 360, W - 110, 1210), 54, fill=(255, 255, 255), outline=(190, 200, 225), width=6)
    d.rounded_rectangle((110, 360, W - 110, 520), 54, fill=(37, 99, 235))
    d.rectangle((110, 460, W - 110, 520), fill=(37, 99, 235))
    d.text((170, 410), 'SAMPLE ID CARD', font=font(54, True), fill='white')
    d.rounded_rectangle((170, 600, 520, 1000), 28, fill=(203, 213, 245))
    d.ellipse((260, 650, 430, 820), fill=(150, 165, 215)); d.pieslice((215, 800, 475, 1060), 180, 360, fill=(150, 165, 215))
    for i in range(4):
        d.text((600, 610 + i * 100), ['Name', 'Birth', 'No.', 'Issued'][i], font=font(30, True), fill=(90, 98, 120))
        d.rounded_rectangle((600, 655 + i * 100, 600 + random.choice((330, 410, 280, 380)), 673 + i * 100), 9, fill=(70, 76, 90))
    d.text((170, 1090), 'FICTIONAL SAMPLE - NOT A REAL DOCUMENT', font=font(28), fill=(225, 29, 72))
    return im

def form():
    im, d = paper()
    d.text((90, 90), 'APPLICATION FORM', font=font(60, True), fill=(30, 41, 90))
    for i in range(8):
        y = 250 + i * 150
        d.text((90, y), f'Field {i + 1}', font=font(30, True), fill=(60, 66, 84))
        d.rounded_rectangle((90, y + 52, W - 90, y + 112), 14, outline=(170, 178, 200), width=4)
        lines(d, 120, y + 72, 1, random.choice((420, 560, 300)), color=(110, 118, 140))
    return im

def shaded(im, tint=(1.0, 0.96, 0.82), dark=0.55, blur=1.2):
    """A hazy, dim, yellowish phone-photo look so the document filters have something to fix."""
    px = im.load()
    out = Image.new('RGB', im.size)
    op = out.load()
    for y in range(im.size[1]):
        for x in range(im.size[0]):
            r, g, b = px[x, y]
            f = 1.0 - dark * ((x / im.size[0]) * 0.8 + (y / im.size[1]) * 0.45)
            op[x, y] = (int(r * tint[0] * f), int(g * tint[1] * f), int(b * tint[2] * f))
    return out.filter(ImageFilter.GaussianBlur(blur))

def notes():
    im, d = paper((253, 252, 246))
    d.text((90, 90), 'MEETING NOTES', font=font(62, True), fill=(30, 41, 90))
    d.text((90, 190), 'Project kickoff  ·  Sample Studio Ltd.', font=font(32), fill=(90, 98, 120))
    for i in range(7):
        y = 310 + i * 175
        d.ellipse((92, y + 6, 120, y + 34), fill=(37, 99, 235))
        lines(d, 150, y + 10, 2, random.choice((760, 880, 640)), gap=52)
    return im

pages = {'invoice': invoice(), 'letter': letter(), 'receipt': receipt(), 'idcard': idcard(), 'form': form(), 'notes': notes()}
for name, im in pages.items():
    im.save(f'{out}/{name}.jpg', quality=90)
# dim photo versions (used for the per-page editor / filter shot)
shaded(pages['receipt'], (1.0, 0.92, 0.72), 0.16, 1.0).save(f'{out}/receipt_photo.jpg', quality=90)
shaded(pages['invoice'], (1.0, 0.93, 0.74), 0.16, 1.0).save(f'{out}/invoice_photo.jpg', quality=90)
# phone-photo look for every page (used by the real-device screenshot run)
for name in ('letter', 'form', 'idcard', 'notes'):
    shaded(pages[name], (1.0, 0.93, 0.76), 0.16, 1.0).save(f'{out}/{name}_photo.jpg', quality=90)
print('samples ->', out, sorted(os.listdir(out)))

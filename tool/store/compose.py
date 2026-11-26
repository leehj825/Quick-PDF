"""Builds the Play Store graphics from the real-UI renders in build/store/raw.
Run:  python3 tool/store/compose.py      (after tool/store/render_screens_test.dart)
Out:  store/graphics/icon-512.png, store/graphics/feature-graphic-<lang>.png,
      store/screenshots/<lang>/NN-name.png (1080x1920)"""
import glob, os
from PIL import Image, ImageDraw, ImageFont

RAW, OUT = 'build/store/raw', 'store'
LANGS = ['ko', 'en', 'ja', 'es']
SHOTS = ['1_home', '2_editor', '3_filter', '4_page', '5_merge', '6_result']
NAMES = ['home', 'reorder', 'filter', 'adjust', 'merge', 'share']

CAPTIONS = {
 'ko': [("사진·스캔·PDF를\n한 곳에서", "갤러리 선택 · 카메라 스캔 · PDF 가져오기"),
        ("드래그로 순서 변경\n탭하면 바로 보정", "페이지 추가·삭제도 간단하게"),
        ("흐릿한 서류도\n또렷하게", "원본 · 문서 선명 · 문서 흑백 필터"),
        ("밝기·대비를\n직접 조절", "회전 · 자르기 · 초기화까지"),
        ("PDF끼리는\n원본 그대로 합치기", "글자와 화질은 그대로, 순서만 정리"),
        ("만들자마자\n바로 공유", "공유 시트로 어디든 보내기")],
 'en': [("Photos, scans and PDFs\nin one place", "Gallery · camera scan · import PDF"),
        ("Drag to reorder,\ntap to adjust", "Add or remove pages in a tap"),
        ("Make faded documents\ncrisp and clear", "Original · Vivid · B&W filters"),
        ("Fine-tune brightness\nand contrast", "Rotate · crop · reset"),
        ("Merge PDFs\nexactly as they are", "Text and quality stay untouched"),
        ("Share the moment\nit's done", "Send anywhere from the share sheet")],
 'ja': [("写真・スキャン・PDFを\nひとつの場所で", "ギャラリー・カメラスキャン・PDF取り込み"),
        ("ドラッグで並べ替え\nタップで補正", "ページの追加・削除も簡単"),
        ("かすれた書類も\nくっきり", "元の色・鮮明・白黒フィルター"),
        ("明るさとコントラストを\n自分で調整", "回転・トリミング・リセット"),
        ("PDF同士は\nそのまま結合", "文字も画質もそのまま"),
        ("作ったらすぐ\n共有", "共有シートからどこへでも")],
 'es': [("Fotos, escaneos y PDF\nen un solo lugar", "Galería · escáner · importar PDF"),
        ("Arrastra para ordenar,\ntoca para ajustar", "Añade o elimina páginas fácilmente"),
        ("Documentos borrosos,\nnítidos", "Filtros: original, nítido y B/N"),
        ("Ajusta brillo\ny contraste", "Girar · recortar · restablecer"),
        ("Une PDF\ntal cual", "El texto y la calidad no cambian"),
        ("Comparte al\ninstante", "Envía desde la hoja de compartir")],
}
FEATURE = {  # tagline, badges
 'ko': ("사진과 문서를\nPDF로 간편하게", ["워터마크 없음", "로그인 없음", "기기 안에서 변환"]),
 'en': ("Turn photos and\ndocuments into PDF", ["No watermark", "No login", "Converts on-device"]),
 'ja': ("写真や書類を\nかんたんPDF化", ["透かしなし", "ログイン不要", "端末内で変換"]),
 'es': ("Convierte fotos y\ndocumentos en PDF", ["Sin marca de agua", "Sin cuenta", "Se procesa en tu móvil"]),
}

def font(lang, size):
    if lang in ('ko', 'ja'):
        return ImageFont.truetype('/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc', size), 2   # faux-bold stroke
    p = glob.glob('/usr/share/fonts/**/Inter-Bold.otf', recursive=True)[0]
    return ImageFont.truetype(p, size), 0

def light_font(lang, size):
    if lang in ('ko', 'ja'):
        return ImageFont.truetype('/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc', size)
    return ImageFont.truetype(glob.glob('/usr/share/fonts/**/Inter-Medium.otf', recursive=True)[0], size)

def gradient(w, h, top=(30, 27, 75), bottom=(37, 99, 235)):
    im = Image.new('RGB', (w, h)); px = im.load()
    for y in range(h):
        t = y / (h - 1)
        c = tuple(int(top[i] * (1 - t) + bottom[i] * t) for i in range(3))
        for x in range(w): px[x, y] = c
    return im

def rounded(im, r):
    m = Image.new('L', im.size, 0); ImageDraw.Draw(m).rounded_rectangle((0, 0, im.size[0], im.size[1]), r, fill=255)
    out = im.convert('RGBA'); out.putalpha(m); return out

def phone(screen, width, bezel=None):
    """Raw screen inside a dark rounded bezel."""
    bezel = bezel or max(6, width // 50)
    h = int(width * screen.size[1] / screen.size[0])
    sc = rounded(screen.convert('RGB').resize((width, h), Image.LANCZOS), width // 14)
    fw, fh = width + 2 * bezel, h + 2 * bezel
    fr = Image.new('RGBA', (fw, fh), (0, 0, 0, 0))
    ImageDraw.Draw(fr).rounded_rectangle((0, 0, fw, fh), width // 14 + bezel, fill=(14, 16, 28, 255))
    fr.alpha_composite(sc, (bezel, bezel))
    return fr

def fit_text(d, text, lang, max_w, size, min_size=40):
    while size > min_size:
        f, stroke = font(lang, size)
        if max(d.textlength(line, font=f) for line in text.split('\n')) <= max_w: return f, stroke, size
        size -= 2
    f, stroke = font(lang, min_size); return f, stroke, min_size

def screenshot(lang, i):
    W, H = 1080, 1920
    canvas = gradient(W, H).convert('RGBA')
    d = ImageDraw.Draw(canvas)
    title, sub = CAPTIONS[lang][i]
    f, stroke, size = fit_text(d, title, lang, 940, 74)
    y = 96
    for line in title.split('\n'):
        d.text((W // 2, y), line, font=f, fill='white', anchor='mt', stroke_width=stroke, stroke_fill='white')
        y += int(size * 1.22)
    d.text((W // 2, y + 14), sub, font=light_font(lang, 36), fill=(199, 210, 254), anchor='mt')
    screen = Image.open(f'{RAW}/{lang}_{SHOTS[i]}.png')
    ph = phone(screen, 700)
    top = H - ph.size[1] - 28
    canvas.alpha_composite(ph, ((W - ph.size[0]) // 2, top))
    path = f'{OUT}/screenshots/{lang}/{i + 1:02d}-{NAMES[i]}.png'
    os.makedirs(os.path.dirname(path), exist_ok=True)
    canvas.convert('RGB').save(path, optimize=True)
    return path, top

def feature(lang):
    W, H = 1024, 500
    im = gradient(W, H, (30, 27, 75), (37, 99, 235)).convert('RGBA')
    d = ImageDraw.Draw(im)
    icon = rounded(Image.open('assets/icon/icon.png').convert('RGB').resize((132, 132), Image.LANCZOS), 30)
    im.alpha_composite(icon, (60, 56))
    f, stroke = font('en', 62)
    d.text((212, 78), 'QuickPDF', font=f, fill='white', anchor='lt')
    tag, badges = FEATURE[lang]
    tf, ts, tsz = fit_text(d, tag, lang, 440, 42, 28)
    y = 214
    for line in tag.split('\n'):
        d.text((60, y), line, font=tf, fill='white', stroke_width=ts, stroke_fill='white'); y += int(tsz * 1.3)
    bf = light_font(lang, 24)
    pills = Image.new('RGBA', (W, H), (0, 0, 0, 0))     # translucent shapes need their own layer
    pd = ImageDraw.Draw(pills)
    x, by = 60, 366
    placed = []
    for b in badges:
        tw = pd.textlength(b, font=bf)
        if x + tw + 36 > 520: x, by = 60, by + 54
        pd.rounded_rectangle((x, by, x + tw + 36, by + 44), 22, fill=(255, 255, 255, 38), outline=(255, 255, 255, 120), width=2)
        placed.append((x, by, b))
        x += tw + 36 + 12
    im.alpha_composite(pills)
    d = ImageDraw.Draw(im)
    for x, by, b in placed:
        d.text((x + 18, by + 22), b, font=bf, fill='white', anchor='lm')
    a = phone(Image.open(f'{RAW}/{lang}_2_editor.png'), 214)
    b = phone(Image.open(f'{RAW}/{lang}_3_filter.png'), 214)
    im.alpha_composite(a, (560, 52)); im.alpha_composite(b, (795, 122))
    path = f'{OUT}/graphics/feature-graphic-{lang}.png'
    os.makedirs(os.path.dirname(path), exist_ok=True)
    im.convert('RGB').save(path, optimize=True)
    return path

os.makedirs(f'{OUT}/graphics', exist_ok=True)
Image.open('assets/icon/icon.png').convert('RGBA').resize((512, 512), Image.LANCZOS).save(f'{OUT}/graphics/icon-512.png', optimize=True)
for lang in LANGS:
    feature(lang)
    for i in range(6):
        p, top = screenshot(lang, i)
print('done', sum(len(files) for _, _, files in os.walk(OUT)), 'files')

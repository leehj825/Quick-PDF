import { PDFDocument } from 'pdf-lib';

export const PRESETS = {
  high: { maxEdge: 2400, quality: 0.9 },
  std: { maxEdge: 1600, quality: 0.75 },
  low: { maxEdge: 1080, quality: 0.55 },
};
export const FREE_LIMIT = 20;
const A4 = [595.28, 841.89];
const MARGIN = 24;

function loadImage(url) {
  return new Promise((res, rej) => {
    const img = new Image();
    img.onload = () => res(img);
    img.onerror = rej;
    img.src = url;
  });
}

// Draw one photo to a canvas (resized + rotated) and return JPEG bytes. Memory is released immediately.
export async function renderJpeg(file, rotation, preset) {
  const url = URL.createObjectURL(file);
  try {
    const img = await loadImage(url);
    const scale = Math.min(1, preset.maxEdge / Math.max(img.naturalWidth, img.naturalHeight));
    const w = Math.round(img.naturalWidth * scale);
    const h = Math.round(img.naturalHeight * scale);
    const swap = rotation % 180 !== 0;
    const canvas = document.createElement('canvas');
    canvas.width = swap ? h : w;
    canvas.height = swap ? w : h;
    const ctx = canvas.getContext('2d');
    ctx.fillStyle = '#fff';
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    ctx.translate(canvas.width / 2, canvas.height / 2);
    ctx.rotate((rotation * Math.PI) / 180);
    ctx.drawImage(img, -w / 2, -h / 2, w, h);
    const blob = await new Promise((r) => canvas.toBlob(r, 'image/jpeg', preset.quality));
    const out = { bytes: new Uint8Array(await blob.arrayBuffer()), width: canvas.width, height: canvas.height };
    canvas.width = 0;
    canvas.height = 0;
    return out;
  } finally {
    URL.revokeObjectURL(url);
  }
}

// Sequential (one image at a time) to avoid WebView OOM.
export async function buildPdf(items, { quality, a4, margin }, onProgress) {
  const preset = PRESETS[quality];
  const pdf = await PDFDocument.create();
  let i = 0;
  for (const it of items) {
    onProgress?.(++i, items.length);
    const { bytes, width, height } = await renderJpeg(it.file, it.rotation, preset);
    const jpg = await pdf.embedJpg(bytes);
    const m = margin ? MARGIN : 0;
    let page;
    if (a4) {
      const landscape = width > height;
      const [pw, ph] = landscape ? [A4[1], A4[0]] : A4;
      page = pdf.addPage([pw, ph]);
      const s = Math.min((pw - m * 2) / width, (ph - m * 2) / height);
      page.drawImage(jpg, { x: (pw - width * s) / 2, y: (ph - height * s) / 2, width: width * s, height: height * s });
    } else {
      page = pdf.addPage([width + m * 2, height + m * 2]);
      page.drawImage(jpg, { x: m, y: m, width, height });
    }
    await new Promise((r) => setTimeout(r, 0)); // yield to UI / GC
  }
  return pdf.save();
}

// Rough size estimate from file sizes, no rendering.
export function estimateSize(items, quality) {
  const ratio = { high: 0.9, std: 0.45, low: 0.18 }[quality];
  const total = items.reduce((s, it) => s + it.file.size, 0);
  return Math.max(20_000, total * ratio);
}

export function fmtSize(b) {
  return b >= 1048576 ? `${(b / 1048576).toFixed(1)} MB` : `${Math.max(1, Math.round(b / 1024))} KB`;
}

export function defaultName() {
  const d = new Date();
  const p = (n) => String(n).padStart(2, '0');
  return `PDF_${d.getFullYear()}${p(d.getMonth() + 1)}${p(d.getDate())}_${p(d.getHours())}${p(d.getMinutes())}`;
}

// History: metadata in localStorage; PDF bytes in Filesystem (native) or IndexedDB (web).
import { Capacitor } from '@capacitor/core';
import { Filesystem, Directory } from '@capacitor/filesystem';
import { Share } from '@capacitor/share';

const KEY = 'quickpdf.history';
const native = Capacitor.isNativePlatform();

const idb = () =>
  new Promise((res, rej) => {
    const r = indexedDB.open('quickpdf', 1);
    r.onupgradeneeded = () => r.result.createObjectStore('pdfs');
    r.onsuccess = () => res(r.result);
    r.onerror = () => rej(r.error);
  });
const idbOp = async (mode, fn) => {
  const db = await idb();
  return new Promise((res, rej) => {
    const tx = db.transaction('pdfs', mode);
    const req = fn(tx.objectStore('pdfs'));
    tx.oncomplete = () => res(req.result);
    tx.onerror = () => rej(tx.error);
  });
};

const toBase64 = (bytes) => {
  let s = '';
  for (let i = 0; i < bytes.length; i += 0x8000) s += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
  return btoa(s);
};

export const listHistory = () => {
  try { return JSON.parse(localStorage.getItem(KEY) || '[]'); } catch { return []; }
};
const saveList = (l) => localStorage.setItem(KEY, JSON.stringify(l));

export async function savePdf(bytes, name, pages) {
  const id = Date.now().toString(36);
  const fileName = `${name.replace(/[\\/:*?"<>|]/g, '_')}.pdf`;
  const entry = { id, name: fileName, pages, size: bytes.length, createdAt: Date.now() };
  if (native) {
    await Filesystem.writeFile({ path: `pdfs/${id}.pdf`, data: toBase64(bytes), directory: Directory.Data, recursive: true });
  } else {
    await idbOp('readwrite', (s) => s.put(bytes, id));
  }
  saveList([entry, ...listHistory()]);
  return entry;
}

async function getBlob(entry) {
  if (native) {
    const r = await Filesystem.readFile({ path: `pdfs/${entry.id}.pdf`, directory: Directory.Data });
    return new Blob([Uint8Array.from(atob(r.data), (c) => c.charCodeAt(0))], { type: 'application/pdf' });
  }
  return new Blob([await idbOp('readonly', (s) => s.get(entry.id))], { type: 'application/pdf' });
}

export async function sharePdf(entry) {
  if (native) {
    const { uri } = await Filesystem.getUri({ path: `pdfs/${entry.id}.pdf`, directory: Directory.Data });
    await Share.share({ title: entry.name, url: uri, dialogTitle: entry.name });
    return;
  }
  const blob = await getBlob(entry);
  const file = new File([blob], entry.name, { type: 'application/pdf' });
  if (navigator.canShare?.({ files: [file] })) await navigator.share({ files: [file], title: entry.name });
  else downloadBlob(blob, entry.name);
}

export async function openPdf(entry) {
  const blob = await getBlob(entry);
  if (native) {
    // Open via share sheet (view with any installed PDF app).
    return sharePdf(entry);
  }
  window.open(URL.createObjectURL(blob), '_blank');
}

function downloadBlob(blob, name) {
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = name;
  a.click();
  setTimeout(() => URL.revokeObjectURL(a.href), 5000);
}

export async function deletePdf(entry) {
  if (native) await Filesystem.deleteFile({ path: `pdfs/${entry.id}.pdf`, directory: Directory.Data }).catch(() => {});
  else await idbOp('readwrite', (s) => s.delete(entry.id));
  saveList(listHistory().filter((e) => e.id !== entry.id));
}

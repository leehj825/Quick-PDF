import React, { useRef, useState } from 'react';
import { t } from '../lib/i18n.js';
import { fmtSize } from '../lib/pdf.js';
import { openPdf, sharePdf, deletePdf } from '../lib/storage.js';

export default function Home({ history, onPick, onChange }) {
  const input = useRef();
  const [menu, setMenu] = useState(null);
  return (
    <div className="h-full flex flex-col">
      <header className="bg-indigo-950 text-white px-4 h-14 flex items-center justify-between shrink-0">
        <h1 className="font-bold text-lg">{t.title}</h1>
        <span className="text-xs font-bold text-amber-300 border border-amber-300 rounded-full px-2 py-0.5">👑 {t.pro}</span>
      </header>
      <main className="flex-1 overflow-y-auto p-4 pb-28">
        {history.length === 0 ? (
          <div className="h-full flex flex-col items-center justify-center text-center gap-3 text-slate-500">
            <div className="text-7xl">🖼️➜📄</div>
            <p className="font-semibold text-slate-700 dark:text-slate-200">{t.emptyTitle}</p>
            <p className="text-sm">{t.emptySub}</p>
          </div>
        ) : (
          <>
            <h2 className="text-sm font-semibold text-slate-500 mb-2">{t.recent}</h2>
            <ul className="space-y-3">
              {history.map((h) => (
                <li key={h.id} className="bg-white dark:bg-slate-800 border border-line dark:border-slate-700 rounded-2xl p-3 flex items-center gap-3">
                  <button className="flex-1 min-w-0 text-left touch" onClick={() => openPdf(h)}>
                    <div className="font-semibold truncate">📄 {h.name}</div>
                    <div className="text-xs text-slate-500">
                      {new Date(h.createdAt).toLocaleDateString()} · {t.pages(h.pages)} · {fmtSize(h.size)}
                    </div>
                  </button>
                  <button className="touch text-xl" aria-label={t.share} onClick={() => sharePdf(h)}>📤</button>
                  <button className="touch text-xl" aria-label="more" onClick={() => setMenu(menu === h.id ? null : h.id)}>⋮</button>
                  {menu === h.id && (
                    <button
                      className="touch text-red-600 text-sm font-semibold"
                      onClick={async () => { if (confirm(t.confirmDel)) { await deletePdf(h); onChange(); } setMenu(null); }}
                    >{t.del}</button>
                  )}
                </li>
              ))}
            </ul>
          </>
        )}
      </main>
      <button
        onClick={() => input.current.click()}
        className="fixed right-4 bottom-20 bg-primary text-white font-semibold text-base rounded-full px-5 h-14 shadow-lg active:scale-95 transition"
      >＋ {t.fab}</button>
      <input ref={input} type="file" accept="image/*" multiple hidden
        onChange={(e) => { onPick([...e.target.files]); e.target.value = ''; }} />
      <footer className="h-14 shrink-0 bg-slate-100 dark:bg-slate-800 text-slate-500 text-sm flex items-center justify-center">{t.ad}</footer>
    </div>
  );
}

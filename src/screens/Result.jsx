import React from 'react';
import { t } from '../lib/i18n.js';
import { fmtSize } from '../lib/pdf.js';
import { openPdf, sharePdf } from '../lib/storage.js';

export default function Result({ entry, onHome }) {
  return (
    <div className="h-full flex flex-col items-center justify-center p-6 gap-6">
      <div className="w-full max-w-sm bg-white dark:bg-slate-800 border border-line dark:border-slate-700 rounded-3xl p-8 text-center shadow-sm">
        <div className="mx-auto w-20 h-20 rounded-full bg-emerald-500 text-white text-4xl flex items-center justify-center animate-bounce">✓</div>
        <h2 className="mt-4 font-bold text-xl">{t.done}</h2>
        <p className="mt-2 font-semibold break-all">{entry.name}</p>
        <p className="text-sm text-slate-500">{fmtSize(entry.size)} · {t.pages(entry.pages)}</p>
      </div>
      <div className="w-full max-w-sm space-y-3">
        <button onClick={() => sharePdf(entry)} className="w-full h-16 rounded-2xl bg-primary text-white text-lg font-semibold">📤 {t.share}</button>
        <button onClick={() => openPdf(entry)} className="w-full h-12 rounded-xl border border-line dark:border-slate-600 font-medium">{t.open}</button>
        <button onClick={onHome} className="w-full h-12 rounded-xl text-slate-500 font-medium">{t.home}</button>
      </div>
    </div>
  );
}

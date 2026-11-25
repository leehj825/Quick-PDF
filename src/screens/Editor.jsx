import React, { useEffect, useMemo, useRef, useState } from 'react';
import { DndContext, closestCenter, MouseSensor, TouchSensor, useSensor, useSensors } from '@dnd-kit/core';
import { SortableContext, useSortable, arrayMove, rectSortingStrategy } from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import { t } from '../lib/i18n.js';
import { buildPdf, defaultName, estimateSize, fmtSize, FREE_LIMIT } from '../lib/pdf.js';
import { savePdf } from '../lib/storage.js';

function Card({ item, index, onRotate, onDelete }) {
  const { attributes, listeners, setNodeRef, transform, transition, isDragging } = useSortable({ id: item.id });
  return (
    <div ref={setNodeRef} {...attributes} {...listeners}
      style={{ transform: CSS.Transform.toString(transform), transition, touchAction: 'manipulation', zIndex: isDragging ? 10 : 0 }}
      className={`relative aspect-square rounded-xl overflow-hidden border border-line dark:border-slate-700 bg-slate-200 ${isDragging ? 'shadow-xl ring-2 ring-primary' : ''}`}>
      <img src={item.url} alt="" draggable={false} className="w-full h-full object-cover transition-transform"
        style={{ transform: `rotate(${item.rotation}deg)` }} />
      <span className="absolute top-1 left-1 bg-primary text-white text-xs font-bold rounded-full w-6 h-6 flex items-center justify-center">{index + 1}</span>
      <div className="absolute bottom-0 inset-x-0 flex justify-between bg-black/45 text-white">
        <button className="w-12 h-10" aria-label={t.rotate} onPointerDown={(e) => e.stopPropagation()} onClick={() => onRotate(item.id)}>⟳</button>
        <button className="w-12 h-10" aria-label={t.del} onPointerDown={(e) => e.stopPropagation()} onClick={() => onDelete(item.id)}>🗑</button>
      </div>
    </div>
  );
}

const Seg = ({ value, options, onChange }) => (
  <div className="flex rounded-xl bg-slate-100 dark:bg-slate-800 p-1">
    {options.map(([v, label]) => (
      <button key={v} onClick={() => onChange(v)}
        className={`flex-1 h-10 rounded-lg text-sm font-medium ${value === v ? 'bg-white dark:bg-slate-600 shadow text-primary dark:text-white font-bold' : 'text-slate-500'}`}>
        {label}
      </button>
    ))}
  </div>
);

let seq = 0;
const toItems = (files) => files.map((file) => ({ id: `p${seq++}`, file, url: URL.createObjectURL(file), rotation: 0 }));

export default function Editor({ initialFiles, onBack, onDone, onSaved }) {
  const [items, setItems] = useState(() => toItems(initialFiles));
  const [name, setName] = useState(defaultName());
  const [quality, setQuality] = useState('std');
  const [a4, setA4] = useState(true);
  const [margin, setMargin] = useState(false);
  const [progress, setProgress] = useState(null);
  const input = useRef();
  const itemsRef = useRef(items);
  itemsRef.current = items;
  useEffect(() => () => itemsRef.current.forEach((i) => URL.revokeObjectURL(i.url)), []);

  const sensors = useSensors(
    useSensor(MouseSensor, { activationConstraint: { distance: 6 } }),
    useSensor(TouchSensor, { activationConstraint: { delay: 250, tolerance: 8 } }),
  );
  const est = useMemo(() => estimateSize(items, quality), [items, quality]);

  const add = (files) => {
    const room = FREE_LIMIT - items.length;
    if (files.length > room) alert(t.limit(FREE_LIMIT));
    setItems((cur) => [...cur, ...toItems(files.slice(0, Math.max(0, room)))]);
  };
  const remove = (id) => setItems((cur) => {
    const gone = cur.find((i) => i.id === id);
    if (gone) URL.revokeObjectURL(gone.url);
    const next = cur.filter((i) => i.id !== id);
    if (!next.length) setTimeout(onBack, 0);
    return next;
  });
  const rotate = (id) => setItems((cur) => cur.map((i) => (i.id === id ? { ...i, rotation: (i.rotation + 90) % 360 } : i)));

  const make = async () => {
    try {
      setProgress([0, items.length]);
      const bytes = await buildPdf(items, { quality, a4, margin }, (a, b) => setProgress([a, b]));
      const entry = await savePdf(bytes, name.trim() || defaultName(), items.length);
      onSaved();
      onDone(entry);
    } catch (e) {
      console.error(e);
      alert(t.error);
      setProgress(null);
    }
  };

  return (
    <div className="h-full flex flex-col">
      <header className="bg-indigo-950 text-white px-2 h-14 flex items-center shrink-0">
        <button className="touch text-xl" onClick={onBack} aria-label="back">←</button>
        <h1 className="flex-1 font-bold">{t.total(items.length)}</h1>
        <button className="touch px-3 font-semibold disabled:opacity-40" disabled={items.length >= FREE_LIMIT} onClick={() => input.current.click()}>＋ {t.add}</button>
        <input ref={input} type="file" accept="image/*" multiple hidden onChange={(e) => { add([...e.target.files]); e.target.value = ''; }} />
      </header>

      <main className="flex-1 overflow-y-auto p-3">
        <DndContext sensors={sensors} collisionDetection={closestCenter}
          onDragStart={() => navigator.vibrate?.(15)}
          onDragEnd={({ active, over }) => {
            if (over && active.id !== over.id) setItems((cur) => arrayMove(cur, cur.findIndex((i) => i.id === active.id), cur.findIndex((i) => i.id === over.id)));
          }}>
          <SortableContext items={items.map((i) => i.id)} strategy={rectSortingStrategy}>
            <div className="grid grid-cols-3 gap-2">
              {items.map((it, idx) => <Card key={it.id} item={it} index={idx} onRotate={rotate} onDelete={remove} />)}
            </div>
          </SortableContext>
        </DndContext>
      </main>

      <section className="shrink-0 bg-white dark:bg-slate-900 border-t border-line dark:border-slate-700 p-3 space-y-3 rounded-t-2xl shadow-[0_-4px_12px_rgba(0,0,0,.06)]">
        <label className="block">
          <span className="text-xs font-semibold text-slate-500">{t.filename}</span>
          <div className="flex items-center border border-line dark:border-slate-700 rounded-xl px-3 h-12">
            <input value={name} onChange={(e) => setName(e.target.value)} className="flex-1 bg-transparent outline-none" />
            <span className="text-slate-400">.pdf</span>
          </div>
        </label>
        <div>
          <div className="flex justify-between text-xs font-semibold text-slate-500 mb-1">
            <span>{t.quality}</span><span>{t.est}: ≈ {fmtSize(est)}</span>
          </div>
          <Seg value={quality} onChange={setQuality}
            options={[['high', `${t.high} ${t.highSub}`], ['std', t.std], ['low', `${t.low}`]]} />
        </div>
        <div className="flex gap-2">
          <div className="flex-1">
            <div className="text-xs font-semibold text-slate-500 mb-1">{t.pageSize}</div>
            <Seg value={a4} onChange={setA4} options={[[true, t.a4], [false, t.orig]]} />
          </div>
          <div className="w-28">
            <div className="text-xs font-semibold text-slate-500 mb-1">{t.margin}</div>
            <Seg value={margin} onChange={setMargin} options={[[false, 'OFF'], [true, 'ON']]} />
          </div>
        </div>
        <button onClick={make} disabled={!!progress}
          className="w-full h-14 rounded-xl bg-primary text-white text-base font-semibold active:scale-[.98] disabled:opacity-70">
          {progress ? t.progress(progress[0], progress[1]) : `${t.make} ➦`}
        </button>
        {progress && (
          <div className="h-1.5 rounded bg-slate-200 overflow-hidden">
            <div className="h-full bg-primary transition-all" style={{ width: `${(progress[0] / progress[1]) * 100}%` }} />
          </div>
        )}
      </section>
    </div>
  );
}

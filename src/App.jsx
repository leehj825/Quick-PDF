import React, { useState } from 'react';
import Home from './screens/Home.jsx';
import Editor from './screens/Editor.jsx';
import Result from './screens/Result.jsx';
import { listHistory } from './lib/storage.js';
import { FREE_LIMIT } from './lib/pdf.js';
import { t } from './lib/i18n.js';

export default function App() {
  const [history, setHistory] = useState(listHistory);
  const [files, setFiles] = useState(null);
  const [result, setResult] = useState(null);
  const refresh = () => setHistory(listHistory());

  if (result) return <Result entry={result} onHome={() => { setResult(null); setFiles(null); }} />;
  if (files) return <Editor initialFiles={files} onBack={() => setFiles(null)} onDone={setResult} onSaved={refresh} />;
  return (
    <Home history={history} onChange={refresh}
      onPick={(f) => {
        if (!f.length) return;
        if (f.length > FREE_LIMIT) alert(t.limit(FREE_LIMIT));
        setFiles(f.slice(0, FREE_LIMIT));
      }} />
  );
}

const frame = document.getElementById('preview');
const targetLink = document.getElementById('open-target');
const note = document.getElementById('target-note');
const targets = {
  native: {path: 'native/', title: 'Native DOM build preview', note: 'HTML + native search · Flutter counter loads on demand'},
  wasm: {path: 'wasm/', title: 'Flutter Wasm build preview', note: 'Dart Wasm + runtime renderer selection · no cross-origin isolation'},
  flutter: {path: 'flutter/', title: 'Flutter Web build preview', note: 'Dart JavaScript + CanvasKit · full Flutter UI'}
};
for (const button of document.querySelectorAll('[data-target]')) {
  button.addEventListener('click', () => {
    if (button.getAttribute('aria-pressed') === 'true') return;
    const target = targets[button.dataset.target];
    for (const other of document.querySelectorAll('[data-target]')) other.setAttribute('aria-pressed', String(other === button));
    frame.src = target.path;
    frame.title = target.title;
    targetLink.href = target.path;
    note.textContent = target.note;
  });
}
const format = bytes => bytes < 1024 * 1024 ? `${(bytes / 1024).toFixed(1)} KiB` : `${(bytes / 1024 / 1024).toFixed(2)} MiB`;
fetch('metrics.json').then(response => {
  if (!response.ok) throw new Error('Metrics unavailable');
  return response.text();
}).then(async metricsText => {
  const metrics = JSON.parse(metricsText);

  loadAudits(metricsText);
  for (const [id, value] of [['native-size', metrics.nativeInitial], ['complete-size', metrics.nativeComplete], ['flutter-size', metrics.flutterInitial]]) {
    const element = document.getElementById(id);
    element.textContent = format(value.bytes);
    element.title = `Gzip level 9: ${format(value.gzipBytes)}. Selected artifacts, not browser transfer.`;
  }
}).catch(() => {
  for (const id of ['native-size', 'complete-size', 'flutter-size']) document.getElementById(id).textContent = 'Unavailable';
});

async function loadAudits(metricsText) {
  try {
    const response = await fetch('audits.json');
    if (!response.ok) return;
    const audit = await response.json();
    const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(metricsText));
    const hash = [...new Uint8Array(digest)].map(n => n.toString(16).padStart(2,'0')).join('');
    if (hash !== audit.artifactHash) {
      document.getElementById('audit-status').textContent = 'Saved audit belongs to a different build. Run the benchmark command for current measurements.';
      return;
    }
    const native = audit.targets.native, flutter = audit.targets.flutter;
    const time = n => n == null ? 'Unavailable' : `${(n/1000).toFixed(2)} s`;
    const score = n => n == null ? 'Unavailable' : `${Math.round(n)} / 100`;

    document.getElementById('audit-status').textContent = `${audit.runs} runs per target · ${new Date(audit.date).toLocaleDateString()} · Lighthouse ${audit.lighthouseVersion}. Medians; see methodology below.`;
    const rows = [
      ['Performance score',score(native.median.performance),`${score(flutter.median.performance)} *`],
      ['SEO score',score(native.median.seo),score(flutter.median.seo)],
      ['First contentful paint',time(native.median.fcpMs),time(flutter.median.fcpMs)],
      ['Largest contentful paint',time(native.median.lcpMs),`${time(flutter.median.lcpMs)} *`],
      ['Total blocking time',time(native.median.tbtMs),time(flutter.median.tbtMs)],
      ['Observed page weight',native.median.transferredBytes == null ? 'Unavailable' : format(native.median.transferredBytes),flutter.median.transferredBytes == null ? 'Unavailable' : format(flutter.median.transferredBytes)],
      ['H1 headings in server HTML',native.serverHtml.h1Count,flutter.serverHtml.h1Count],
      ['Inputs in server HTML',native.serverHtml.searchInputCount,flutter.serverHtml.searchInputCount]
    ];
    const wasm = audit.targets.wasm;
    const wasmValues = wasm ? [score(wasm.median.performance)+' *', score(wasm.median.seo), time(wasm.median.fcpMs), time(wasm.median.lcpMs)+' *', time(wasm.median.tbtMs), wasm.median.transferredBytes == null ? 'Unavailable' : format(wasm.median.transferredBytes), wasm.serverHtml.h1Count, wasm.serverHtml.searchInputCount] : rows.map(() => 'Not audited');
    rows.forEach((row, i) => row.push(wasmValues[i]));
    const renderer = target => {
      const resources = target?.samples.flatMap(s => s.rendererResources || []) || [];
      return resources.some(r => r.includes('skwasm')) ? 'SkWasm' : resources.some(r => r.includes('canvaskit')) ? 'CanvasKit' : 'DOM';
    };
    rows.unshift(['Observed renderer', 'DOM', renderer(flutter), wasm ? renderer(wasm) : 'Not audited']);
    document.getElementById('audit-rows').replaceChildren(...rows.map(cells => {
      const row = document.createElement('tr');
      for (const text of cells) {const cell = document.createElement('td');cell.textContent = text;row.append(cell);}
      return row;
    }));
  } catch {
    document.getElementById('audit-status').textContent = 'Browser audit unavailable. Run the benchmark command below.';
  }
}

// Audit independent targets, never the comparison shell. Raw reports stay ignored.
import lighthouse from 'lighthouse';
import {launch} from 'chrome-launcher';
import {readFile, writeFile, mkdir} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
const root = fileURLToPath(new URL('../../', import.meta.url));
const base = process.argv[2] || 'http://127.0.0.1:8097/';
const runs = Number(process.argv[3] || 3);
if (!Number.isInteger(runs) || runs < 1 || runs > 20) throw Error('Runs must be 1–20');
const probe = await fetch(new URL('native/',base));
if (!probe.ok) throw Error('Start the showcase server before auditing.');
const metricsText = await readFile(path.join(root, 'build/showcase/metrics.json'), 'utf8');
const summary = {
  schemaVersion: 1, date: new Date().toISOString(), runs,
  chromeFlags: ['--headless', '--no-first-run'],
  methodology: 'Lighthouse desktop, simulated throttling, fresh Chrome per run; localhost; counter not activated. Scores are lab diagnostics, not search rankings. FCP measures paint, not interaction readiness.',
  artifactHash: createHash('sha256').update(metricsText).digest('hex'),
  targets: {}
};
const median = values => {
  const sorted = values.filter(v => typeof v === 'number').sort((a,b) => a-b);
  if (!sorted.length) return null;
  return (sorted[Math.floor((sorted.length-1)/2)] + sorted[Math.floor(sorted.length/2)]) / 2;
};
await mkdir(path.join(root, 'build/browser-audits'), {recursive:true});
for (const target of ['native', 'flutter', 'wasm']) {
  const samples = [];
  for (let i = 0; i < runs; i++) {
    const chrome = await launch({chromeFlags: ['--headless', '--no-first-run']});
    try {
      const {lhr} = await lighthouse(new URL(`${target}/`, base).href, {
        port: chrome.port, logLevel: 'error', onlyCategories: ['performance', 'seo'],
      }, {extends: 'lighthouse:default', settings: {formFactor:'desktop', emulatedUserAgent:false,
        screenEmulation:{mobile:false,width:1350,height:940,deviceScaleFactor:1,disabled:false},
        throttling: {rttMs:40,throughputKbps:10240,cpuSlowdownMultiplier:1,requestLatencyMs:0,downloadThroughputKbps:0,uploadThroughputKbps:0},
        throttlingMethod:'simulate'}});
      await writeFile(path.join(root, `build/browser-audits/${target}-${i+1}.json`), JSON.stringify(lhr,null,2));
      const sample = {
        performance: lhr.categories.performance.score === null ? null : lhr.categories.performance.score * 100,
        seo: lhr.categories.seo.score === null ? null : lhr.categories.seo.score * 100,
        fcpMs: lhr.audits['first-contentful-paint'].numericValue ?? null,
        lcpMs: lhr.audits['largest-contentful-paint'].numericValue ?? null,
        tbtMs: lhr.audits['total-blocking-time'].numericValue ?? null,
        transferredBytes: lhr.audits['total-byte-weight'].numericValue ?? null,
        warnings: lhr.runWarnings,
        runtimeError: lhr.runtimeError ? {code:lhr.runtimeError.code,message:lhr.runtimeError.message} : null,
        rendererResources: (lhr.audits['network-requests'].details?.items || [])
          .filter(item => /(?:skwasm|canvaskit|main\.dart\.wasm)/.test(item.url))
          .map(item => new URL(item.url).pathname),
        failedSeo: Object.values(lhr.categories.seo.auditRefs).map(ref => lhr.audits[ref.id])
          .filter(a => a.score !== null && a.score < 1).map(a => ({id:a.id,title:a.title}))
      };
      samples.push(sample);
      summary.lighthouseVersion = lhr.lighthouseVersion;
      summary.environment = lhr.environment;
      summary.settings = lhr.configSettings;
      console.log(`${target} ${i+1}/${runs}: performance=${sample.performance}, SEO=${sample.seo}, FCP=${sample.fcpMs}`);
    } finally { await chrome.kill(); }
  }
  const html = await readFile(path.join(root, `build/showcase/${target}/index.html`), 'utf8');
  summary.targets[target] = {
    samples,
    caveats: target !== 'native' ? ['Canvas rendering: Lighthouse may emit NO_LCP internally yet synthesize an LCP estimate. Its LCP and derived performance score are not equivalent to application readiness.'] : [],
    ranges: Object.fromEntries(['performance','seo','fcpMs','lcpMs','tbtMs','transferredBytes'].map(k => {
      const values = samples.map(s=>s[k]).filter(v=>typeof v === 'number');
      return [k, values.length ? {min:Math.min(...values),max:Math.max(...values)} : null];
    })),
    median: Object.fromEntries(['performance','seo','fcpMs','lcpMs','tbtMs','transferredBytes'].map(k=>[k,median(samples.map(s=>s[k]))])),
    serverHtml: {h1Count: (html.match(/<h1[\s>]/gi)||[]).length, searchInputCount:(html.match(/<input\b/gi)||[]).length}
  };
}
await writeFile(path.join(root, 'build/showcase/audits.json'), JSON.stringify(summary,null,2));
await writeFile(path.join(root, 'benchmarks/results/showcase-browser.json'), JSON.stringify(summary,null,2));
console.log('Saved sanitized summary; raw reports: build/browser-audits/');

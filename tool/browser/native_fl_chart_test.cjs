const assert = require('node:assert/strict');
const path = require('node:path');
const { Element, install, label, find, findAll, until, tick, style } = require('./dom_shim.cjs');
Element.measure = () => 400;
Element.measureHeight = () => 200;
const { host } = install();
const text = v => find(host, n => n.tag === 'p' && n.textContent === v);
const button = v => find(host, n => n.tag === 'button' && label(n) === v);
const status = () => find(host, n => n.tag === 'p' && n.textContent.startsWith('touched ')).textContent;
const sleep = ms => new Promise(r => setTimeout(r, ms));
const overlays = () => findAll(host, n => n.events.pointermove && style(n).includes('position:absolute'));
function tap(node, x, y) {
  node.events.pointermove({ offsetX: x, offsetY: y });
  node.events.pointerdown({ offsetX: x, offsetY: y });
  node.events.pointerup({ offsetX: x, offsetY: y });
}
(async () => {
  require(path.resolve(process.argv[2]));
  await tick();
  const canvases = findAll(host, n => n.tag === 'canvas');
  assert.equal(canvases.length, 3, 'one canvas per chart');
  const [line, bar, pie] = canvases.map(c => c.context.ops);
  // Line chart: curved stroke, gradient area, dashed extra line, grid.
  assert(line.some(o => o[0] === 'bezierCurveTo'), 'curved line');
  assert(line.some(o => o[0] === 'set:fillStyle' && typeof o[1] === 'object' && o[1].kind === 'linear'), 'gradient area');
  assert(line.some(o => o[0] === 'set:strokeStyle' && o[1] === 'rgba(255,0,0,1)'), 'extra line');
  assert(line.filter(o => o[0] === 'stroke').length > 10, 'dashes and grid strokes');
  // Titles are DOM text: default left titles plus custom bottom titles.
  for (const day of ['D0', 'D1', 'D2', 'D3']) assert(text(day), `bottom title ${day}`);
  assert(text('0') && text('10'), 'left axis titles with min and max');
  // Chart area excludes reserved title space (left 44, bottom 24).
  const lineOverlay = overlays()[0];
  assert.match(style(lineOverlay), /left:44px;top:0px;width:356px;height:176px/);
  // Bar chart: rounded rods; Pie chart: arcs, DOM titles and badge icon.
  assert(bar.filter(o => o[0] === 'ellipse').length >= 8, 'rounded rod corners');
  assert(pie.filter(o => o[0] === 'ellipse').length >= 4, 'ring sections');
  assert(text('Run') && text('Walk'));
  assert(find(host, n => n.tag === 'span' && style(n).includes('MaterialIcons')), 'badge icon');

  // Hover shows the built-in tooltip; tap reaches the touch callback.
  lineOverlay.events.pointermove({ offsetX: 356 / 3, offsetY: 50 });
  await until(() => find(host, n => n.attributes.role === 'tooltip'), 'line tooltip');
  assert(label(find(host, n => n.attributes.role === 'tooltip')).includes('5'));
  tap(lineOverlay, 356 / 3, 50);
  await until(() => status() === 'touched line 1');
  lineOverlay.events.pointerleave({});
  await until(() => !find(host, n => n.attributes.role === 'tooltip'), 'tooltip hides on exit');

  // Bar hit-testing: group 3 (value 8) under the pointer.
  const barOverlay = overlays()[1];
  const width = 356, gap = (width - 4 * 16) / 5;
  const x3 = gap * 4 + 16 * 3 + 8;
  tap(barOverlay, x3, 176 - 176 * 0.5);
  await until(() => status() === 'touched bar 3');
  // Pie hit-testing: the right side (angle 0) is the first section.
  const pieOverlay = overlays()[2];
  tap(pieOverlay, 200 + 60, 100 + 5);
  await until(() => status() === 'touched pie Run');

  // Data changes repaint (animated over the chart's duration).
  const before = canvases[0].context.ops.length;
  button('Update').events.click();
  await until(() => canvases[0].context.ops.length > before, 'repainted after data change');
  await sleep(300);
  assert(text('D3'), 'titles remain after update');
  console.log('Charts passed');
})().catch(e => { console.error(e); process.exitCode = 1; });

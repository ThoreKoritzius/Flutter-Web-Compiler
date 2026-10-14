// DOM contract checks for examples/records_panel compiled with dart2js.
const assert = require('node:assert/strict');
const path = require('node:path');
const { Element, install, label, find, findAll, style, until, tick, key } = require('./dom_shim.cjs');

let width = 1024;
Element.measure = () => width;
const { host, windowListeners } = install({ width: 1100, height: 900 });

const visibleText = n => n.attributes['aria-hidden'] === 'true' ? '' : n.textContent + n.children.map(visibleText).join('');
const text = value => find(host, n => n.tag === 'p' && n.textContent === value);
const button = value => find(host, n => n.tag === 'button' && visibleText(n).trim() === value);
const rows = () => findAll(host, n => n.tag === 'p' && /^Sample entry \d+$/.test(n.textContent));
const ancestor = (node, predicate) => { for (let n = node.parent; n; n = n.parent) if (predicate(n)) return n; };
const rowButton = name => ancestor(text(name), n => n.attributes.role === 'button');
const status = () => find(host, n => n.tag === 'p' && n.textContent.startsWith('Host rebuilds:')).textContent;
const badge = () => find(host, n => n.tag === 'p' && /^\d+$/.test(n.textContent) && style(n.parent).includes('border-radius:999px')).textContent;
const lineage = node => { const out = []; for (let n = node; n; n = n.parent) out.push(n); return out; };
const tilesInRow = () => {
  const others = new Set(lineage(text('Average')));
  const common = lineage(text('Total')).find(n => others.has(n));
  return style(common).includes('flex-direction:row');
};
async function click(node, expectation, message) { node.events.click(); await until(expectation, message); }

(async () => {
  const errors = [];
  const originalError = console.error;
  console.error = (...args) => { errors.push(args.join(' ')); originalError(...args); };
  require(path.resolve(process.argv[2]));

  // Initial collapsed state, header badge and document title.
  assert.equal(global.document.title, 'Records panel fixture');
  assert.equal(rows().length, 6);
  assert.equal(badge(), '9');
  assert(button('Show all'), 'expand toggle is a native button');

  // Icons render as font glyphs from the Material icon font, never emoji.
  const icons = findAll(host, n => n.tag === 'span' && style(n).includes('"MaterialIcons"'));
  assert(icons.length >= 6, 'icons are rendered');
  for (const icon of icons) {
    assert.equal(icon.attributes['aria-hidden'], 'true');
    const code = icon.textContent.codePointAt(0);
    assert(code >= 0xe000 && code <= 0xf8ff || code >= 0xf0000, `private-use glyph ${code}`);
  }

  // Theme-derived rounded surfaces and the left-aligned toggle.
  assert(find(host, n => style(n).includes('border-radius:16px') && style(n).includes('border:1px solid')));
  assert(ancestor(button('Show all'), n => style(n).includes('justify-content:flex-start')), 'Align.centerLeft');

  // Wide layout: summary tiles share a row; dates have their own column.
  assert(tilesInRow(), 'wide summary tiles share a row');
  assert(find(host, n => style(n).includes('width:120px') && label(n) === '2024-01-01'));

  // Expansion and retained DOM identity across the toggle.
  const toggle = button('Show all');
  await click(toggle, () => rows().length === 9, 'expanded rows');
  assert.equal(button('Show fewer'), toggle, 'toggle button node is retained (focus survives)');

  // Parent rebuilds keep child state and DOM nodes.
  const header = text('Synthetic records');
  const firstRow = text('Sample entry 1');
  await click(button('Rebuild host'), () => status().startsWith('Host rebuilds: 1'));
  assert.equal(rows().length, 9, 'expansion survives parent rebuild');
  assert.equal(text('Synthetic records'), header);
  assert.equal(text('Sample entry 1'), firstRow);

  // Updated input reaches the existing child state.
  await click(button('Add record'), () => rows().length === 10, 'new input record');
  assert.equal(badge(), '10');
  assert(button('Show fewer'), 'still expanded after input update');
  assert.equal(text('Sample entry 1'), firstRow, 'keyed rows are retained');

  // Clickable rows: callbacks, keyboard activation and null item IDs.
  const entry1 = rowButton('Sample entry 1');
  assert.equal(entry1.attributes.tabindex, '0');
  assert.equal(rowButton('Sample entry 3'), undefined, 'records without item IDs are not buttons');
  await click(entry1, () => status().endsWith('Selected: Sample entry 1'));
  assert.equal(key(rowButton('Sample entry 2'), 'Enter'), true, 'Enter is handled');
  await until(() => status().endsWith('Selected: Sample entry 2'));
  assert.equal(key(rowButton('Sample entry 4'), ' '), true, 'Space is handled without scrolling');
  await until(() => status().endsWith('Selected: Sample entry 4'));
  assert.equal(key(rowButton('Sample entry 5'), 'a'), false, 'other keys are ignored');

  // Null callbacks remove button semantics and make the row inert.
  await click(button('Disable selection'), () => button('Enable selection'));
  assert.equal(rowButton('Sample entry 1'), undefined);
  assert.equal(entry1.attributes.tabindex, undefined, 'retained row is no longer focusable');
  entry1.events.click();
  await tick();
  assert(status().endsWith('Selected: Sample entry 4'), 'disabled row ignores clicks');
  await click(button('Enable selection'), () => rowButton('Sample entry 1'));

  // Removal disposes the panel; stale callbacks stay inert; state resets.
  const staleRow = rowButton('Sample entry 1');
  const staleToggle = button('Show fewer');
  await click(button('Remove panel'), () => !text('Synthetic records'));
  staleRow.events.click();
  staleToggle.events.click();
  await tick();
  assert(status().endsWith('Selected: Sample entry 4'), 'stale row callback is inert');
  await click(button('Restore panel'), () => text('Synthetic records'));
  assert.equal(rows().length, 6, 'restored panel starts collapsed with fresh state');
  assert.notEqual(text('Synthetic records'), header, 'restored panel has new DOM');

  // Responsive breakpoint after a viewport resize; expansion survives.
  await click(button('Show all'), () => rows().length === 10);
  width = 360;
  global.window.innerWidth = 380;
  for (const listener of windowListeners.resize ?? []) listener();
  await until(() => !tilesInRow(), 'narrow layout stacks summary tiles');
  assert(!find(host, n => style(n).includes('width:120px')), 'compact rows drop the date column');
  assert(text('2024-01-01'), 'compact rows keep the date under the label');
  assert.equal(rows().length, 10, 'expansion survives resize');

  // Empty state.
  await click(button('Clear records'), () => text('No records yet'));
  assert.equal(badge(), '0');
  assert.equal(button('Show fewer'), undefined);
  assert.equal(button('Show all'), undefined);

  assert.deepEqual(errors, []);
  console.log('Records panel: state, input, disposal, stale callbacks, keyboard, layout and icons passed');
})().catch(error => { console.error(error); process.exitCode = 1; });

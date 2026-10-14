const assert = require('node:assert/strict');
const path = require('node:path');
const { install, label, find, findAll, until, style, key } = require('./dom_shim.cjs');
const { host } = install();
const plain = n => n.attributes['aria-hidden'] === 'true' ? '' : n.textContent + n.children.map(plain).join('');
const para = prefix => find(host, n => n.tag === 'p' && plain(n).startsWith(prefix));
const span = text => find(host, n => n.tag === 'span' && n.textContent === text);
(async () => {
  require(path.resolve(process.argv[2]));
  // Headings carry heading semantics and the merged style sheet.
  const h1 = para('Weekly summary');
  assert(h1, 'heading text');
  assert.equal(h1.parent.attributes.role, 'heading');
  assert.match(style(h1), /font-size:30px/);
  assert.match(style(h1), /rgba\(18,52,86,1\)/);
  // Inline styles.
  assert.match(style(span('bold')), /font-weight:700/);
  assert.match(style(span('italic')), /font-style:italic/);
  assert.match(style(span('old')), /text-decoration:line-through/);
  assert.match(style(span('inline code')), /monospace/);
  // Links are keyboard-accessible and report text, href and title.
  const link = span('guide link');
  assert.equal(link.attributes.role, 'link');
  assert.equal(link.attributes.tabindex, '0');
  link.events.click();
  await until(() => para('tapped guide link|https://example.com/guide|Guide'));
  // Lists: bullets, nested ordered items, task checkboxes as icons.
  assert(para('First item') && para('Second item with emphasis'));
  assert(find(host, n => n.tag === 'p' && n.textContent === '•'));
  assert(find(host, n => n.tag === 'p' && n.textContent === '2.'), 'ordered bullet');
  assert(para('Nested two'));
  const boxes = findAll(host, n => n.tag === 'span' && style(n).includes('MaterialIcons'));
  assert.equal(boxes.length, 2, 'task checkboxes');
  // Block quote, code block, table and image.
  assert(para('Quoted note'));
  assert(para('let total = 42;'));
  const table = find(host, n => n.attributes.role === 'table');
  assert(table, 'table');
  assert.match(style(table), /grid-template-columns:minmax\(0,1fr\) minmax\(0,1fr\)/);
  assert.equal(findAll(table, n => n.attributes.role === 'cell').length, 4);
  assert.match(style(find(table, n => n.tag === 'p' && n.textContent === '' && plain(n) === '8,000')), /text-align:right/);
  const image = find(host, n => n.tag === 'img');
  assert.equal(image.attributes.src, 'https://example.com/chart.png');
  assert.equal(image.attributes.alt, 'Chart');
  console.log('Markdown passed');
})().catch(e => { console.error(e); process.exitCode = 1; });

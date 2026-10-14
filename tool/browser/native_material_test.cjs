const assert = require('node:assert/strict');
const path = require('node:path');
const { install, label, find, findAll, until, style } = require('./dom_shim.cjs');
const { host } = install();
const visibleText = n => n.attributes['aria-hidden'] === 'true' ? '' : n.textContent + n.children.map(visibleText).join('');
const text = v => find(host, n => n.tag === 'p' && n.textContent === v);
const button = v => find(host, n => n.tag === 'button' && visibleText(n).trim() === v);
(async () => {
  const logs = [];
  const log = console.log;
  console.log = (...a) => logs.push(a.join(' '));
  try {
    require(path.resolve(process.argv[2]));
    // Same algorithm and version as Flutter: baseline seed → baseline roles.
    assert(logs.includes('seed ff65558f ffe6e0e9'), logs.join('\n'));
    // Tabs: roles, selection and arrow-key navigation.
    const tabs = findAll(host, n => n.attributes.role === 'tab');
    assert.equal(tabs.length, 2);
    assert.equal(tabs[0].attributes['aria-selected'], 'true');
    assert(text('first tab') && !text('second tab'));
    find(host, n => n.attributes.role === 'tablist').events.keydown({ key: 'ArrowRight', preventDefault() {} });
    await until(() => text('second tab'));
    assert.equal(tabs[1].attributes['aria-selected'], 'true');
    assert.equal(find(host, n => n.attributes.role === 'tabpanel').attributes['aria-labelledby'], tabs[1].attributes.id);
    // Navigation bar.
    assert.equal(button('Home').attributes['aria-current'], 'page');
    button('Settings').events.click();
    await until(() => text('page 1'));
    assert.equal(button('Settings').attributes['aria-current'], 'page');
    // Drawer opens from the implied menu button and closes on Escape.
    find(host, n => n.attributes['aria-label'] === 'Open navigation menu').events.click();
    await until(() => text('Menu item'));
    find(host, n => n.events.keydown && style(n).includes('position:fixed;inset:0')).events.keydown({ key: 'Escape' });
    await until(() => !text('Menu item'));
    // Expansion tile.
    const toggle = find(host, n => n.attributes['aria-expanded'] !== undefined);
    assert.equal(toggle.attributes['aria-expanded'], 'false');
    assert(!text('hidden detail'));
    toggle.events.click();
    await until(() => text('hidden detail'));
    assert.equal(toggle.attributes['aria-expanded'], 'true');
    console.log = log;
    console.log('Material structure passed');
  } finally { console.log = log; }
})().catch(e => { console.error(e); process.exitCode = 1; });

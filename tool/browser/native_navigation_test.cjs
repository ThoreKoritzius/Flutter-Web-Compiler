const assert = require('node:assert/strict');
const path = require('node:path');
const { install, label, find, until, tick, style } = require('./dom_shim.cjs');
const { host } = install({ history: true });
const visible = node => { for (let n = node; n; n = n.parent) if (style(n).includes('display:none')) return false; return true; };
const text = prefix => find(host, n => n.tag === 'p' && n.textContent.startsWith(prefix) && visible(n));
const button = value => find(host, n => n.tag === 'button' && label(n).replace(/[-]/g, '') === value && visible(n));
const history = global.window.history;
(async () => {
  const logs = [];
  const log = console.log;
  console.log = (...args) => { logs.push(args.join(' ')); };
  try {
    require(path.resolve(process.argv[2]));
    assert(text('home count 0'));
    assert.equal(global.window.location.hash, '#/');
    button('Increment').events.click(); await until(() => text('home count 1'));

    // Named push with arguments; the covered route keeps its state.
    button('Open details').events.click();
    await until(() => text('details from home'));
    assert.equal(global.window.location.hash, '#/details');
    assert.equal(history.length, 2);
    assert(!text('home count'), 'covered route is hidden');
    const back = find(host, n => n.tag === 'button' && n.attributes['aria-label'] === 'Back');
    assert(back, 'AppBar shows an implied back button');
    button('Pick').events.click();
    await until(() => text('home count 1 result picked'));
    await tick();
    assert.equal(history.index, 0, 'programmatic pop moves browser history back');

    // Browser back pops the route.
    button('Open details').events.click();
    await until(() => text('details from home'));
    history.back();
    await until(() => text('home count 1 result none'));

    // Dialog result and modal semantics.
    button('Ask').events.click();
    await until(() => find(host, n => n.attributes.role === 'dialog'));
    assert.equal(find(host, n => n.attributes.role === 'dialog').attributes['aria-modal'], 'true');
    button('Yes').events.click();
    await until(() => text('home count 1 result dialog true'));
    // Escape dismisses a dismissible dialog with a null result.
    button('Ask').events.click();
    await until(() => find(host, n => n.attributes.role === 'dialog'));
    const overlay = find(host, n => n.events.keydown && style(n).includes('position:fixed;inset:0'));
    overlay.events.keydown({ key: 'Escape', preventDefault() {} });
    await until(() => text('home count 1 result dialog null'));

    // Snack bar with action.
    button('Notify').events.click();
    await until(() => find(host, n => n.attributes.role === 'status'));
    button('Undo').events.click();
    await until(() => !find(host, n => n.attributes.role === 'status'));
    assert(logs.includes('undo'));

    // PopScope blocks browser back until allowed.
    button('Open guarded').events.click();
    await until(() => button('Allow'));
    history.back();
    await until(() => logs.includes('pop invoked false'));
    await tick();
    assert(button('Allow'), 'blocked pop keeps the page');
    button('Allow').events.click();
    await tick();
    find(host, n => n.tag === 'button' && n.attributes['aria-label'] === 'Back' && visible(n)).events.click();
    await until(() => text('home count 1'));
    assert(logs.includes('pop invoked true'));
    console.log = log;
    console.log('Navigation passed');
  } finally {
    console.log = log;
  }
})().catch(error => { console.error(error); process.exitCode = 1; });

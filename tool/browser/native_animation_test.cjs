const assert = require('node:assert/strict');
const path = require('node:path');
const { install, label, find, until, tick, style } = require('./dom_shim.cjs');
const { host } = install();
const text = v => find(host, n => n.tag === 'p' && n.textContent === v);
const button = v => find(host, n => n.tag === 'button' && label(n) === v);
const opacity = node => { for (let n = node; n; n = n.parent) { const m = /opacity:([\d.]+)/.exec(style(n)); if (m) return Number(m[1]); } return 1; };
const widthOf = name => { for (let n = text(name); n; n = n.parent) { const m = /width:([\d.]+)px/.exec(style(n)); if (m) return Number(m[1]); } };
const sleep = ms => new Promise(r => setTimeout(r, ms));
(async () => {
  const logs = [];
  const log = console.log;
  console.log = (...a) => logs.push(a.join(' '));
  try {
    require(path.resolve(process.argv[2]));
    assert(logs.includes('curve 0.50 0.094'), logs.join('|'));
    assert(logs.includes('tween Color(0xff808080) 12.5'), logs.join('|'));
    await until(() => logs.includes('post frame true'), 'post-frame callback after first build');
    assert.equal(opacity(text('Fading')), 0);
    assert(text('tween running') || text('tween done'));
    await until(() => text('tween done'), 'tween builder completes');

    // Explicit controller: intermediate frames, then completion.
    button('Forward').events.click();
    assert(logs.includes('status forward'));
    await until(() => opacity(text('Fading')) > 0 && opacity(text('Fading')) < 1, 'intermediate opacity');
    await until(() => logs.includes('status completed'), 'controller completes');
    assert.equal(opacity(text('Fading')), 1);

    // Implicit animation interpolates and can be retargeted mid-flight.
    assert.equal(widthOf('Box'), 100);
    button('Resize').events.click();
    await until(() => widthOf('Box') > 100 && widthOf('Box') < 200, 'intermediate width');
    await until(() => widthOf('Box') === 200, 'final width');
    await until(() => logs.includes('container end'));
    button('Resize').events.click();
    await sleep(40);
    const mid = widthOf('Box');
    assert(mid < 200 && mid > 100, `retargeted from ${mid}`);
    await until(() => widthOf('Box') === 100);

    // AnimatedSwitcher keeps the outgoing child until it has faded out.
    button('Switch').events.click();
    await until(() => text('Second'));
    assert(text('First'), 'outgoing child still mounted');
    await until(() => !text('First'), 'outgoing child removed');
    await until(() => opacity(text('Second')) === 1, 'incoming child fully faded in');

    // Repeat runs until stopped; disposal stops tickers.
    button('Repeat').events.click();
    await sleep(60);
    button('Stop').events.click();
    const stopped = opacity(text('Fading'));
    await sleep(60);
    assert.equal(opacity(text('Fading')), stopped, 'stopped controller holds its value');
    assert(style(find(host, n => style(n).includes('matrix3d'))).includes('transform-origin:calc(50% + 0px) calc(50% + 0px)'));
    button('Replace').events.click();
    await until(() => text('Replaced'));
    assert(logs.includes('demo disposed'));
    console.log = log;
    console.log('Animations passed');
  } finally { console.log = log; }
})().catch(e => { console.error(e); process.exitCode = 1; });

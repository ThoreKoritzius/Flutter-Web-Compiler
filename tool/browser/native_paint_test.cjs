const assert = require('node:assert/strict');
const path = require('node:path');
const { Element, install, label, find, findAll, until, tick } = require('./dom_shim.cjs');
let width = 300;
Element.measure = node => (node.tag === 'canvas' ? width : 1000);
Element.measureHeight = node => (node.tag === 'canvas' ? 120 : 0);
const { windowListeners } = install();
global.window.devicePixelRatio = 2;
const host = global.document.querySelector('#app');
const button = text => find(host, n => n.tag === 'button' && label(n) === text);
(async () => {
  const logs = [];
  const log = console.log;
  console.log = (...a) => logs.push(a.join(' '));
  const paints = () => logs.filter(l => l.startsWith('paint '));
  try {
    require(path.resolve(process.argv[2]));
    const canvases = findAll(host, n => n.tag === 'canvas');
    assert.equal(canvases.length, 2, 'background and foreground layers');
    const [background, foreground] = canvases;
    assert.equal(background.attributes['aria-hidden'], 'true');
    assert.match(foreground.attributes.style, /z-index:1/);
    // Backing store uses the device pixel ratio; drawing uses logical pixels.
    assert.equal(background.width, 600);
    assert.equal(background.height, 240);
    const ops = background.context.ops;
    assert.deepEqual(ops.find(o => o[0] === 'setTransform'), ['setTransform', 2, 0, 0, 2, 0, 0]);
    assert.deepEqual(paints(), ['paint 300x120 0.2,0.8,0.5 0']);
    const gradient = ops.find(o => o[0] === 'set:fillStyle' && typeof o[1] === 'object');
    assert.equal(gradient[1].kind, 'linear');
    assert.deepEqual(gradient[1].args, [0, 0, 0, 120]);
    assert.deepEqual(gradient[1].stops.map(s => s[1]), ['rgba(51,102,255,1)', 'rgba(153,204,255,1)']);
    assert(ops.some(o => o[0] === 'ellipse'), 'rounded corners and arcs use ellipse segments');
    assert(ops.some(o => o[0] === 'stroke'), 'stroked path');
    assert(ops.some(o => o[0] === 'set:lineWidth' && o[1] === 2));
    const text = ops.find(o => o[0] === 'fillText');
    assert.equal(text[1], 'Weekly total');
    assert.equal(text[2], 300 - 'Weekly total'.length * 6, 'right-aligned using measured width');
    assert(foreground.context.ops.some(o => o[0] === 'fill'));

    // Unrelated rebuilds keep the canvas when shouldRepaint is false.
    button('Rebuild 0').events.click();
    await until(() => button('Rebuild 1'));
    await tick();
    assert.equal(paints().length, 1);
    assert.equal(findAll(host, n => n.tag === 'canvas')[0], background, 'canvas retained');
    // New data repaints.
    button('Change data').events.click();
    await until(() => paints().length === 2);
    assert.equal(paints()[1], 'paint 300x120 0.4,0.4,0.9 0');
    // The repaint listenable repaints without rebuilding.
    button('Pulse').events.click();
    await until(() => paints().length === 3);
    assert.equal(paints()[2], 'paint 300x120 0.4,0.4,0.9 1');
    // Resizing repaints at the new size.
    width = 500;
    for (const fn of windowListeners.resize) fn();
    await until(() => paints().length === 4);
    assert.equal(paints()[3], 'paint 500x120 0.4,0.4,0.9 1');
    assert.equal(background.width, 1000);
    // Removal stops listening to the repaint source.
    button('Hide').events.click();
    await until(() => !find(host, n => n.tag === 'canvas'));
    button('Pulse').events.click();
    await tick(); await tick();
    assert.equal(paints().length, 4);
    console.log = log;
    console.log('Custom painting passed');
  } finally { console.log = log; }
})().catch(e => { console.error(e); process.exitCode = 1; });

const assert = require('node:assert/strict');
const path = require('node:path');
const { install, label, find, until, tick } = require('./dom_shim.cjs');
const { host } = install();
const text = value => find(host, n => n.tag === 'p' && n.textContent === value);
const button = value => find(host, n => n.tag === 'button' && label(n) === value);
const order = () => [...host.children[0] ? findButtons() : []];
function findButtons() {
  const out = [];
  const walk = n => { if (n.tag === 'button' && /^[abc]:\d+$/.test(label(n))) out.push(label(n)); n.children.forEach(walk); };
  walk(host);
  return out;
}
(async () => {
  const logs = [];
  const log = console.log;
  console.log = (...args) => { logs.push(args.join(' ')); };
  try {
    require(path.resolve(process.argv[2]));
    assert.deepEqual(order(), ['a:0', 'b:0', 'c:0']);
    const aNode = button('a:0');
    aNode.events.click(); await until(() => button('a:1'));
    button('c:0').events.click(); await until(() => button('c:1'));
    button('c:1').events.click(); await until(() => button('c:2'));

    // Reversal keeps each keyed state (and DOM node) with its item.
    button('Reverse').events.click(); await until(() => order()[0] === 'c:2');
    assert.deepEqual(order(), ['c:2', 'b:0', 'a:1']);
    assert.equal(button('a:1'), aNode, 'moved DOM node is reused');
    assert.equal(logs.filter(l => l.startsWith('dispose')).length, 0);

    // GlobalKey reaches the moved state.
    button('b:0').events.click(); await until(() => button('b:1'));
    button('Read global').events.click();
    assert(logs.includes('global:1'));

    // Removing a keyed item disposes exactly that state.
    button('Drop first').events.click(); await until(() => !button('c:2'));
    assert.deepEqual(order(), ['b:1', 'a:1']);
    assert.deepEqual(logs.filter(l => l.startsWith('dispose')), ['dispose c 2']);

    // InheritedNotifier and ValueListenableBuilder rebuild without the root.
    const builds = text('root builds 3') ? 3 : null;
    assert(builds, 'root rebuilt only for its own setState calls');
    button('Notify').events.click();
    await until(() => text('inherited 1') && text('listenable 1'));
    assert(text('root builds 3'), 'dependents rebuild without rebuilding the root');

    // Async builders.
    assert(text('stream initial'));
    await until(() => text('future done'));
    console.log = log;
    console.log('Keyed reconciliation passed');
  } finally {
    console.log = log;
  }
})().catch(error => { console.error(error); process.exitCode = 1; });

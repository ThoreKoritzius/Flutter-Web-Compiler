// Minimal DOM contract harness, not a substitute for real-browser coverage.
const assert = require('node:assert/strict');
const http = require('node:http');
const path = require('node:path');

class Element {
  constructor() { this.textContent = ''; this.children = []; this.attributes = {}; this.events = {}; }
  appendChild(child) { this.children.push(child); }
  replaceChildren() { this.children = []; }
  setAttribute(name, value) { this.attributes[name] = value; }
  addEventListener(name, fn) { this.events[name] = fn; }
}

async function main() {
  const elements = Object.fromEntries(['status', 'activities', 'total', 'panel', 'refresh', 'fail'].map(id => [id, new Element()]));
  global.self = global;
  global.document = {
    currentScript: null,
    querySelector: selector => elements[selector.slice(1)],
    createElement: () => new Element(),
  };
  let requests = 0;
  const server = http.createServer((req, res) => {
    requests++;
    setTimeout(() => {
      res.setHeader('Content-Type', 'application/json');
      res.statusCode = req.url.includes('fail=1') ? 503 : 200;
      res.end(JSON.stringify({data: {activities: [{name: '<b>Literal</b>', minutes: 42}, {name: 'Ride', minutes: 10.5}]}}));
    }, 30);
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const fetch = global.fetch;
  global.fetch = url => fetch(`http://127.0.0.1:${server.address().port}${url}`);
  async function until(expected) {
    const deadline = Date.now() + 5000;
    while (elements.status.textContent !== expected) {
      if (Date.now() > deadline) throw new Error('Status timeout: ' + elements.status.textContent);
      await new Promise(resolve => setTimeout(resolve, 5));
    }
  }
  try {
    require(path.resolve(process.argv[2]));
    assert.equal(elements.status.textContent, 'Loading…');
    assert.equal(elements.panel.attributes['aria-busy'], 'true');
    await until('Updated from local API');
    assert.equal(elements.total.textContent, '53 min');
    assert.equal(elements.activities.children[0].children[0].textContent, '<b>Literal</b>');
    assert.equal(elements.panel.attributes['aria-busy'], 'false');
    elements.fail.events.click();
    await until('Request failed. Retry to recover.');
    assert.equal(elements.total.textContent, '53 min');
    elements.refresh.events.click();
    await until('Updated from local API');
    assert.equal(requests, 3);
    console.log('Official compiled Dart: live HTTP, decoding, loading, failure and retry passed.');
  } finally {
    global.fetch = fetch;
    server.closeAllConnections();
    await new Promise(resolve => server.close(resolve));
  }
}
main().catch(error => { console.error(error); process.exitCode = 1; });

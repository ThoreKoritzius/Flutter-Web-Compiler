const assert = require('node:assert/strict');
const http = require('node:http');
const path = require('node:path');
const {install}=require('./dom_shim.cjs');
function text(node) { return node.textContent + node.children.map(text).join(' '); }
function find(node, label) {
  if(node.tag === 'button' && text(node) === label) return node;
  for(const child of node.children) { const found = find(child,label); if(found) return found; }
}
async function main() {
  const {host: app} = install();
  let requests = 0;
  const server = http.createServer((req,res) => {
    const id = ++requests;
    setTimeout(() => {
      res.setHeader('Content-Type','application/json');
      res.statusCode = req.url.includes('fail=1') ? 503 : 200;
      res.end(JSON.stringify({data:{activities:[{name:'Activity '+id,minutes:id}]}}));
    }, id === 2 ? 250 : 20);
  });
  await new Promise(resolve => server.listen(0,'127.0.0.1',resolve));
  const fetch = global.fetch;
  global.fetch = url => fetch(`http://127.0.0.1:${server.address().port}${url}`);
  async function until(value) {
    const deadline = Date.now()+5000;
    while(!text(app).includes(value)) {
      if(Date.now()>deadline) throw new Error('Timeout: '+text(app));
      await new Promise(resolve => setTimeout(resolve,5));
    }
  }
  try {
    require(path.resolve(process.argv[2]));
    assert(text(app).includes('Loading…'));
    await until('1 min total');
    const staleButton = find(app,'Refresh / retry');
    staleButton.events.click();
    await until('Loading…');
    find(app,'Refresh / retry').events.click();
    await until('3 min total');
    await new Promise(resolve => setTimeout(resolve,300));
    assert(text(app).includes('3 min total'));
    assert(!text(app).includes('Activity 2'));
    assert.equal(find(app,'Refresh / retry'),staleButton,'retained button node across rebuilds');
    find(app,'Test request failure').events.click();
    await until('Request failed. Retry to recover.');
    assert(text(app).includes('3 min total'));
    find(app,'Refresh / retry').events.click();
    await until('5 min total');
    console.log('Original Flutter source: lifecycle, request, factories, setState, stale responses and retry passed.');
  } finally {
    global.fetch = fetch;
    server.closeAllConnections();
    await new Promise(resolve => server.close(resolve));
  }
}
main().catch(error => { console.error(error); process.exitCode=1; });

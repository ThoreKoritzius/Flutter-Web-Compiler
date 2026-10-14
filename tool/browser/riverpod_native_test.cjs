const assert = require('node:assert/strict');
const path = require('node:path');
const {install}=require('./dom_shim.cjs');
function text(node) { return node.textContent + node.children.map(text).join(' '); }
function find(node,label) {
  if(node.tag==='button' && text(node)===label) return node;
  for(const child of node.children) { const result=find(child,label); if(result) return result; }
}
async function main() {
  const {host:app}=install();
  const logs=[];
  const log=console.log;
  console.log=(...args)=> {logs.push(args.join(' '));log(...args);};
  async function until(expected) {
    const deadline=Date.now()+5000;
    while(!text(app).includes(expected)) {
      if(Date.now()>deadline) throw new Error('Timeout: '+text(app));
      await new Promise(resolve=>setTimeout(resolve,5));
    }
  }
  try {
    require(path.resolve(process.argv[2]));
    assert(text(app).includes('Count: 8'));
    assert(text(app).includes('Pending'));
    await until('Result: 42');
    find(app,'Increment').events.click();
    await until('Count: 10');
    find(app,'Stop watching').events.click();
    await new Promise(resolve=>setTimeout(resolve,10));
    const builds=logs.filter(value=>value==='consumer build').length;
    find(app,'Increment').events.click();
    await new Promise(resolve=>setTimeout(resolve,30));
    assert.equal(logs.filter(value=>value==='consumer build').length,builds,'unused watch subscriptions must be closed');
    assert(text(app).includes('Count: 10'));
    const stale=find(app,'Increment');
    find(app,'Unmount').events.click();
    stale.events.click();
    assert.equal(text(app),'Unmounted');
    assert(logs.includes('initial:4'));
    assert(logs.includes('watch outside build rejected'));
    assert(logs.includes('async provider disposed'));
    assert(logs.includes('disposed ref rejected'));
    log('Official Riverpod: providers, async, overrides and disposal passed');
  } finally { console.log=log; }
}
main().catch(error=> {console.error(error);process.exitCode=1;});

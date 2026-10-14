const assert = require('node:assert/strict');
const path = require('node:path');
let width = 500;
const {Element,install,find}=require('./dom_shim.cjs');
Element.measure=()=>width;
const {host,windowListeners}=install({width:700,height:800});
const listeners={get size(){return windowListeners.resize?.size??0;},[Symbol.iterator](){return (windowListeners.resize??new Set())[Symbol.iterator]();}};
async function until(predicate){const deadline=Date.now()+5000;while(!predicate()){if(Date.now()>deadline)throw Error('Resize did not render');await new Promise(resolve=>setTimeout(resolve,5));}}
(async()=>{
 require(path.resolve(process.argv[2]));
 assert(find(host,n=>n.textContent==='Measured 500 / 700'));
 assert(find(host,n=>(n.attributes.style||'').includes('width:245')));
 assert.equal(listeners.size,1);
 find(host,n=>n.tag==='button'&&n.children.some(c=>c.textContent==='Deferred 0')).events.click();
 await until(()=>find(host,n=>n.textContent==='Deferred 1'));
 width=900;window.innerWidth=1100;for(const fn of listeners)fn();
 await until(()=>find(host,n=>n.textContent==='Measured 900 / 1100'));
 assert(find(host,n=>(n.attributes.style||'').includes('width:445')));
 assert.equal(listeners.size,1);
 assert(find(host,n=>n.textContent==='Deferred 1'));
 find(host,n=>n.tag==='button'&&n.children.some(c=>c.textContent==='Replace')).events.click();
 assert.equal(listeners.size,0);
 assert(find(host,n=>n.textContent==='Disposed'));
 console.log('Attached layout, resize and disposal passed');
})().catch(error=>{console.error(error);process.exitCode=1;});

const assert = require('node:assert/strict');
const path = require('node:path');
let width = 500;
class Element {
 constructor(tag) { this.tag=tag; this.children=[]; this.attributes={}; this.events={}; this.textContent=''; this.parent=null; }
 appendChild(node) { node.parent=this; this.children.push(node); }
 replaceChildren() { this.children=[]; }
 setAttribute(key,value) { this.attributes[key]=value; }
 addEventListener(event,fn) { this.events[event]=fn; }
 get clientWidth() { assert(this.parent, 'Must measure an attached container'); return width; }
}
const host=new Element('main');
const listeners=new Set();
global.self=global;
global.window={innerWidth:700,innerHeight:800,addEventListener:(event,fn)=>{assert.equal(event,'resize');listeners.add(fn);},removeEventListener:(event,fn)=>listeners.delete(fn)};
global.document={currentScript:null,querySelector:()=>host,createElement:tag=>new Element(tag)};
function find(node,predicate) { if(predicate(node))return node; for(const child of node.children){const result=find(child,predicate);if(result)return result;} }
async function until(predicate){const deadline=Date.now()+5000;while(!predicate()){if(Date.now()>deadline)throw Error('Resize did not render');await new Promise(resolve=>setTimeout(resolve,5));}}
(async()=>{
 require(path.resolve(process.argv[2]));
 assert(find(host,n=>n.textContent==='Measured 500 / 700'));
 assert(find(host,n=>(n.attributes.style||'').includes('width:245')));
 assert.equal(listeners.size,1);
 width=900;window.innerWidth=1100;for(const fn of listeners)fn();
 await until(()=>find(host,n=>n.textContent==='Measured 900 / 1100'));
 assert(find(host,n=>(n.attributes.style||'').includes('width:445')));
 assert.equal(listeners.size,1);
 find(host,n=>n.tag==='button').events.click();
 assert.equal(listeners.size,0);
 assert(find(host,n=>n.textContent==='Disposed'));
 console.log('Attached layout, resize and disposal passed');
})().catch(error=>{console.error(error);process.exitCode=1;});

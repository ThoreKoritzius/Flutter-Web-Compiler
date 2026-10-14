const assert=require('node:assert/strict');
const path=require('node:path');
const {install,label,find}=require('./dom_shim.cjs');
const {host}=install();
function button(text){return find(host,n=>n.tag==='button'&&label(n)===text);}
async function until(p){const deadline=Date.now()+5000;while(!p()){if(Date.now()>deadline)throw Error('Expected render missing: '+label(host));await new Promise(resolve=>setTimeout(resolve,5));}}
async function click(text,expected){assert(button(text),text);button(text).events.click();await until(()=>button(expected));}
(async()=>{
 const logs=[];const original=console.log;console.log=(...args)=>{logs.push(args.join(' '));};
 require(path.resolve(process.argv[2]));
 assert.equal(logs.filter(x=>x==='init A').length,1);assert.equal(logs.filter(x=>x==='init B').length,1);
 await click('A 0:0','A 0:1');await click('B 0:0','B 0:1');
 await click('Parent update','A 1:1');assert(button('B 0:1'));assert(logs.includes('update A 0->1'));
 const stale=button('A 1:1');button('Visibility').events.click();await until(()=>logs.includes('dispose A 1'));
 assert(!button('A 1:1'));stale.events.click();assert(button('B 0:1'));
 await click('Visibility','A 1:0');assert.equal(logs.filter(x=>x==='init A').length,2);
 await click('A 1:0','A 1:1');await click('Change ancestor','A 1:0');
 assert.equal(logs.filter(x=>x==='init A').length,3);assert.equal(logs.filter(x=>x==='dispose A 1').length,2);assert(button('B 0:1'));
 button('End app').events.click();assert.equal(label(host),'End');
 assert(logs.includes('dispose A 0'));assert(logs.includes('dispose B 1'));assert(logs.includes('parent disposed'));assert(logs.includes('broken disposed'));assert(logs.includes('dispose C 0'));assert.equal(logs.at(-1),'failure cleaned');
 original('Nested updates, conditional removal, ancestor identity and disposal passed');
})().catch(e=>{console.error(e);process.exitCode=1;});

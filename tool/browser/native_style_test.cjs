const assert=require('node:assert/strict');
const path=require('node:path');
const {install,label,find}=require('./dom_shim.cjs');
const {host:app}=install();
function text(value){return find(app,node=>node.tag==='p'&&node.textContent===value);}
function button(value){return find(app,node=>node.tag==='button'&&label(node)===value);}
function check(count){
 assert.match(text(`Ready ${count}`).attributes.style,/font-size:16px;.*font-weight:600/);
 assert.match(text(`Ready ${count}`).attributes.style,/rgba\(18,52,86,1\)/);
 assert.match(text('Scoped').attributes.style,/rgba\(171,205,239,1\)/);
 assert.match(text('Sibling').attributes.style,/rgba\(18,52,86,1\)/);
 assert(find(app,node=>(node.attributes.style||'').includes('border-radius:24')));
 assert(find(app,node=>(node.attributes.style||'').includes('padding:12.0px 16.0px')||(node.attributes.style||'').includes('padding:12px 16px')));
 assert(find(app,node=>(node.attributes.style||'').includes('flex:1 1 0')));
 assert(!find(app,node=>node.tag==='div'&&(node.attributes.style||'').includes('gap:')),'flex layouts add no implicit gaps');
}
async function until(predicate){
 const deadline=Date.now()+5000;
 while(!predicate()){
  if(Date.now()>deadline) throw new Error('Expected state did not render');
  await new Promise(resolve=>setTimeout(resolve,5));
 }
}
(async()=>{
 const logs=[];const original=console.log;
 console.log=(...args)=>{logs.push(args.join(' '));original(...args);};
 require(path.resolve(process.argv[2]));
 assert(logs.includes('init:18'));check(0);
 const retained=button('Update');const readyNode=text('Ready 0');
 retained.events.click();await until(()=>text('Ready 1'));check(1);
 assert.equal(button('Update'),retained,'button node is retained across rebuilds');assert.equal(text('Ready 1'),readyNode,'text node is patched in place');
 retained.events.click();await until(()=>text('Ready 2'));check(2);
 button('Check errors').events.click();
 assert(logs.includes('invalid flex rejected'));assert(logs.includes('invalid padding rejected'));assert(logs.includes('positioned outside stack rejected'));assert.equal(label(app),'Done');
 original('Scoped theme, card layout, updates and rejection checks passed');
})().catch(error=>{console.error(error);process.exitCode=1;});

const assert=require('node:assert/strict');
const path=require('node:path');
class Element {
 constructor(tag){this.tag=tag;this.textContent='';this.children=[];this.attributes={};this.events={};}
 appendChild(child){this.children.push(child);}
 replaceChildren(){this.children=[];}
 setAttribute(key,value){this.attributes[key]=value;}
 addEventListener(event,fn){this.events[event]=fn;}
}
const app=new Element('main');
global.self=global;
global.document={currentScript:null,querySelector:()=>app,createElement:tag=>new Element(tag)};
function find(node,predicate){if(predicate(node))return node;for(const child of node.children){const result=find(child,predicate);if(result)return result;}}
function label(node){return node.textContent+node.children.map(label).join('');}
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
 assert(!find(app,node=>(node.attributes.style||'').includes('gap:')));
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
 const stale=button('Update');stale.events.click();await until(()=>text('Ready 1'));check(1);
 stale.events.click();await until(()=>text('Ready 1'));check(1);
 button('Check errors').events.click();
 assert(logs.includes('invalid flex rejected'));assert(logs.includes('invalid padding rejected'));assert(logs.includes('icon painting rejected'));assert.equal(label(app),'Done');
 original('Scoped theme, card layout, updates and rejection checks passed');
})().catch(error=>{console.error(error);process.exitCode=1;});

// Minimal DOM stand-in for native runtime contract tests. It enforces real
// tree rules (one parent per node; removing or inserting relative to a
// non-child throws) so reconciliation bugs surface. It is not a browser.
'use strict';

class Element {
  constructor(tag) {
    this.tag = tag;
    this.children = [];
    this.attributes = {};
    this.events = {};
    this.listeners = {};
    this.parent = null;
    this._text = '';
  }
  // Own text only; helpers below concatenate descendants explicitly.
  get textContent() { return this._text; }
  set textContent(value) {
    for (const child of this.children) child.parent = null;
    this.children = [];
    this._text = String(value);
  }
  _detach(node) {
    if (!node.parent) return;
    const siblings = node.parent.children;
    siblings.splice(siblings.indexOf(node), 1);
    node.parent = null;
  }
  appendChild(node) {
    this._detach(node);
    node.parent = this;
    this.children.push(node);
    return node;
  }
  insertBefore(node, reference) {
    if (reference == null) return this.appendChild(node);
    if (reference.parent !== this) throw new Error('NotFoundError: reference is not a child');
    if (node === reference) return node;
    this._detach(node);
    node.parent = this;
    this.children.splice(this.children.indexOf(reference), 0, node);
    return node;
  }
  removeChild(node) {
    if (node.parent !== this) throw new Error('NotFoundError: node is not a child');
    this._detach(node);
    return node;
  }
  replaceChildren() {
    for (const child of this.children) child.parent = null;
    this.children = [];
    this._text = '';
  }
  setAttribute(key, value) { this.attributes[key] = String(value); }
  removeAttribute(key) { delete this.attributes[key]; }
  getAttribute(key) { return key in this.attributes ? this.attributes[key] : null; }
  addEventListener(type, fn) {
    (this.listeners[type] ??= []).push(fn);
    this.events[type] = event => { for (const listener of this.listeners[type]) listener(event); };
  }
  focus() {
    const active = global.document.activeElement;
    if (active === this || !connected(this) || this.attributes.disabled !== undefined) return;
    if (active) active.blur();
    global.document.activeElement = this;
    this.events.focus?.({});
  }
  blur() {
    if (global.document.activeElement !== this) return;
    global.document.activeElement = null;
    this.events.blur?.({});
  }
  get clientWidth() {
    if (!connected(this)) throw new Error('Measured a detached element');
    return Element.measure(this);
  }
}
Element.measure = () => 0;

let root = null;
function connected(node) {
  while (node.parent) node = node.parent;
  return node === root;
}

/// Installs `document` and `window` globals and returns the `#app` host.
function install({ width = 1024, height = 768, history = false } = {}) {
  const host = new Element('div');
  root = host;
  const windowListeners = {};
  global.self = global;
  global.document = {
    currentScript: null,
    title: '',
    activeElement: null,
    querySelector: selector => (selector === '#app' ? host : null),
    createElement: tag => new Element(tag),
  };
  global.window = {
    innerWidth: width,
    innerHeight: height,
    addEventListener(type, fn) { (windowListeners[type] ??= new Set()).add(fn); },
    removeEventListener(type, fn) { windowListeners[type]?.delete(fn); },
  };
  if (history) {
    const entries = [{ state: null, url: '' }];
    let index = 0;
    global.window.location = { get hash() { return entries[index].url || ''; } };
    global.window.history = {
      pushState(state, _title, url) { entries.splice(index + 1); entries.push({ state, url: url ?? entries[index].url }); index++; },
      replaceState(state, _title, url) { entries[index] = { state, url: url ?? entries[index].url }; },
      back() {
        if (index === 0) return;
        index--;
        setTimeout(() => { for (const fn of windowListeners.popstate ?? []) fn({ state: entries[index].state }); }, 0);
      },
      get state() { return entries[index].state; },
      get length() { return entries.length; },
      get index() { return index; },
    };
  }
  return { host, windowListeners };
}

const label = node => node.textContent + node.children.map(label).join('');
const find = (node, predicate) => {
  if (predicate(node)) return node;
  for (const child of node.children) {
    const found = find(child, predicate);
    if (found) return found;
  }
};
const findAll = (node, predicate, out = []) => {
  if (predicate(node)) out.push(node);
  for (const child of node.children) findAll(child, predicate, out);
  return out;
};
const style = node => node.attributes.style || '';
async function until(predicate, message = 'Expected render missing') {
  const deadline = Date.now() + 5000;
  while (!predicate()) {
    if (Date.now() > deadline) throw new Error(message);
    await new Promise(resolve => setTimeout(resolve, 5));
  }
}
const tick = () => new Promise(resolve => setTimeout(resolve, 0));
function key(node, name) {
  let prevented = false;
  node.events.keydown({ key: name, preventDefault() { prevented = true; } });
  return prevented;
}

module.exports = { Element, install, label, find, findAll, style, until, tick, key };

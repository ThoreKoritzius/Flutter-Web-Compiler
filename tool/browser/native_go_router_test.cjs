const assert = require('node:assert/strict');
const path = require('node:path');
const { install, label, find, until, tick, style } = require('./dom_shim.cjs');
const { host } = install({ history: true });
const visible = node => { for (let n = node; n; n = n.parent) if (style(n).includes('display:none')) return false; return true; };
const plain = n => n.attributes['aria-hidden'] === 'true' ? '' : n.textContent + n.children.map(plain).join('');
const text = prefix => find(host, n => n.tag === 'p' && n.textContent.startsWith(prefix) && visible(n));
const button = v => find(host, n => n.tag === 'button' && plain(n).trim() === v && visible(n));
const hash = () => global.window.location.hash;
(async () => {
  require(path.resolve(process.argv[2]));
  // Auth redirect sends the initial location to /login.
  await until(() => button('Sign in'), 'redirected to login');
  assert.equal(hash(), '#/login');
  // refreshListenable re-runs redirects after signing in.
  button('Sign in').events.click();
  await until(() => text('likes 0'), 'feed after sign-in');
  assert.equal(hash(), '#/feed');
  assert(text('likes 0').textContent.endsWith('at /feed'), 'GoRouterState.of(context)');

  // Branch state survives switching tabs.
  button('Like').events.click();
  await until(() => text('likes 1'));
  const feedNode = text('likes 1');
  assert.equal(button('Feed').attributes['aria-current'], 'page');
  button('Settings').events.click();
  await until(() => text('Settings page'), 'settings branch');
  assert.equal(hash(), '#/settings');
  assert(!text('likes 1'), 'inactive branch hidden');
  button('Feed').events.click();
  await until(() => text('likes 1'), 'feed branch restored');
  assert.equal(text('likes 1'), feedNode, 'branch keeps its state and DOM');

  // Named push with parameters, query and extra; typed pop result.
  button('Open').events.click();
  await until(() => text('query info extra payload'), 'pushed details');
  assert(find(host, n => n.tag === 'p' && n.textContent === 'Details 7' && visible(n)));
  assert(find(host, n => n.attributes['aria-label'] === 'Back' && visible(n)), 'implied back button');
  button('Pick').events.click();
  await until(() => text('likes 1 result picked 7'), 'push result');

  // Dialogs over router pages close with context.pop.
  button('Ask').events.click();
  await until(() => find(host, n => n.attributes.role === 'dialog'));
  button('Close').events.click();
  await until(() => !find(host, n => n.attributes.role === 'dialog'), 'dialog closed');
  assert(text('likes 1'), 'page stays after dialog pop');

  // Unknown locations replace the stack with the error page (disposing the
  // shell, as in go_router); browser back rebuilds the feed location.
  button('Broken link').events.click();
  await until(() => text('error /missing'));
  assert.equal(hash(), '#/missing');
  global.window.history.back();
  await until(() => text('likes 0'), 'browser back restores the feed location');
  assert.equal(hash(), '#/feed');

  // Signing out redirects to login again.
  button('Sign out').events.click();
  await until(() => button('Sign in'), 'redirect on sign-out');
  console.log('Router passed');
})().catch(e => { console.error(e); process.exitCode = 1; });

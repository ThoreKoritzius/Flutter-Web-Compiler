const assert = require('node:assert/strict');
const path = require('node:path');
const { install, label, find, findAll, until, tick, key } = require('./dom_shim.cjs');
const { host } = install();
const text = prefix => find(host, n => n.tag === 'p' && n.textContent.startsWith(prefix));
const state = () => text('state ').textContent;
const button = value => find(host, n => n.tag === 'button' && label(n) === value);
const inputs = () => findAll(host, n => n.tag === 'input' && (n.attributes.type === 'text' || !n.attributes.type));
const typeInto = (node, value) => {
  node.value = value;
  node.selectionStart = node.selectionEnd = value.length;
  node.events.input();
};
(async () => {
  const logs = [];
  const log = console.log;
  console.log = (...args) => { logs.push(args.join(' ')); };
  try {
    require(path.resolve(process.argv[2]));
    const [name, amount] = inputs();
    assert(name && amount, 'text inputs render');
    // Labels are associated with their inputs.
    const nameLabel = find(host, n => n.tag === 'label' && label(n) === 'Name');
    assert.equal(nameLabel.attributes.for, name.attributes.id);
    assert.equal(amount.attributes.inputmode, 'numeric');
    assert.equal(amount.value, '12');

    // Validation shows an error that is announced and linked to the input.
    button('Submit').events.click();
    await until(() => find(host, n => n.tag === 'p' && n.textContent === 'Enter a name'));
    assert(logs.includes('valid:false'));
    assert.equal(name.attributes['aria-invalid'], 'true');
    const message = find(host, n => n.attributes.id === name.attributes['aria-describedby']);
    assert.equal(message.attributes.role, 'alert');

    // Typing clears the error after resubmission; the node is retained.
    typeInto(name, 'Ada');
    await tick();
    button('Submit').events.click();
    await until(() => state().includes('saved=Ada'));
    assert(logs.includes('valid:true'));
    assert.equal(inputs()[0], name, 'input node retained across rebuilds');
    assert.equal(name.attributes['aria-invalid'], undefined);

    // Enter submits single-line fields.
    assert.equal(key(name, 'Enter'), true);
    await until(() => state().includes('submitted=Ada'));

    // Formatters filter input and write the corrected value back.
    typeInto(amount, '12a3');
    await tick();
    assert.equal(amount.value, '123');
    assert(logs.includes('amount:123'));
    typeInto(amount, '123456');
    await tick();
    assert.equal(amount.value, '1234', 'maxLength enforced');
    assert(find(host, n => n.tag === 'p' && n.textContent === '4/4'), 'counter shown');
    // Programmatic controller changes reach the DOM.
    button('Set amount').events.click();
    await until(() => amount.value === '777');

    // Controlled checkbox, switch, radio, slider and select.
    const boxes = findAll(host, n => n.tag === 'input' && n.attributes.type === 'checkbox' && !n.attributes.role);
    boxes[0].checked = true; boxes[0].events.change();
    await until(() => state().includes('agree=true'));
    assert.equal(boxes[0].checked, true);
    boxes[1].checked = true; boxes[1].events.change();
    assert.equal(boxes[1].checked, false, 'unchanged value is restored immediately');
    assert(logs.includes('ignored:true'));
    const toggle = find(host, n => n.attributes.role === 'switch');
    toggle.checked = false; toggle.events.change();
    await until(() => state().includes('alerts=false'));
    const radios = findAll(host, n => n.attributes.type === 'radio');
    assert.deepEqual(radios.map(r => r.checked), [false, true, false]);
    radios[2].checked = true; radios[2].events.click();
    await until(() => state().includes('size=l'));
    assert.deepEqual(radios.map(r => r.checked), [false, false, true]);
    const slider = find(host, n => n.attributes.type === 'range');
    assert.equal(slider.attributes.step, '0.25');
    slider.value = '0.75'; slider.events.input();
    await until(() => state().includes('level=0.75'));
    const select = find(host, n => n.tag === 'select');
    assert.deepEqual(select.children.map(label), ['Apple', 'Pear']);
    select.value = '1'; select.events.change();
    await until(() => state().includes('fruit=pear'));
    assert.equal(select.selectedIndex, 1);

    // Disabled controls.
    button('Lock').events.click();
    await until(() => toggle.attributes.disabled === '');

    // Reset restores initial form values.
    button('Reset').events.click();
    await until(() => name.value === '');
    console.log = log;
    console.log('Forms and controls passed');
  } finally {
    console.log = log;
  }
})().catch(error => { console.error(error); process.exitCode = 1; });

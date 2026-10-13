const assert = require('node:assert/strict');
const http = require('node:http');
const path = require('node:path');
async function main() {
  let abortedBody = false;
  let bodyClosed;
  const closed = new Promise(resolve => bodyClosed = resolve);
  let finished;
  const complete = new Promise(resolve => finished = resolve);
  global.finishGraphqlTest = finished;
  let successfulRequests = 0;
  let redirectFollowed = false;
  const server = http.createServer((req, res) => {
    const chunks = [];
    req.on('data', chunk => chunks.push(chunk));
    req.on('end', () => {
      assert.equal(req.method, 'POST');
      assert.equal(req.headers['content-type'], 'application/json');
      const request = JSON.parse(Buffer.concat(chunks));
      assert.equal(typeof request.query, 'string');
      if(req.url === '/graphql') {
        successfulRequests++;
        assert.deepEqual(request, {query:'query Items($limit: Int!) { items }',variables:{limit:2},operationName:'Items'});
        res.end(JSON.stringify({data:{items:[1,2]}}));
      } else if(req.url === '/http') {
        res.writeHead(503); res.end('service unavailable');
      } else if(req.url === '/errors') {
        res.end(JSON.stringify({data:{items:[]},errors:[{message:'private server detail'}]}));
      } else if(req.url === '/invalid') {
        res.end('not json');
      } else if(req.url === '/redirect') {
        res.writeHead(302, {Location:'/unexpected'}); res.end();
      } else if(req.url === '/slow') {
        res.writeHead(200, {'Content-Type':'application/json'});
        res.write('{"data":');
        res.on('close', () => { abortedBody = !res.writableEnded; bodyClosed(); });
      } else {
        redirectFollowed = true; res.end('{}');
      }
    });
  });
  await new Promise(resolve => server.listen(0,'127.0.0.1',resolve));
  const nativeFetch = global.fetch;
  global.self = global;
  global.fetch = (url, options) => {
    assert.equal(options.credentials,'same-origin');
    assert.equal(options.redirect,'error');
    assert(options.signal instanceof AbortSignal);
    return nativeFetch(`http://127.0.0.1:${server.address().port}${url}`, options);
  };
  let deadline;
  const timeout = new Promise((_,reject) => { deadline = setTimeout(() => reject(new Error('Compiled GraphQL test timed out')),5000); });
  try {
    require(path.resolve(process.argv[2]));
    await Promise.race([Promise.all([complete,closed]),timeout]);
    assert.equal(successfulRequests,1);
    assert.equal(abortedBody,true,'timeout must cancel response body consumption');
    assert.equal(redirectFollowed,false,'must not forward GraphQL payload through redirects');
  } finally {
    clearTimeout(deadline);
    delete global.finishGraphqlTest;
    global.fetch = nativeFetch;
    server.closeAllConnections();
    await new Promise(resolve => server.close(resolve));
  }
}
main().catch(error => { console.error(error); process.exitCode=1; });

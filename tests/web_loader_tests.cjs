const {test} = require('node:test');
const assert = require('node:assert/strict');
const vm = require('node:vm');
const {gzipSync} = require('node:zlib');
const {webcrypto, createHash} = require('node:crypto');
const fs = require('node:fs');
const code = fs.readFileSync('tools/web_loader.js','utf8');
function setup({store = new Map(), brokenStorage=false, response, version='one', includePack=false, brokenWrite=false, fastTimeout=false}={}) {
  const raw = Buffer.from('game-'+version), zipped = gzipSync(raw);
  const asset = {file:'index.wasm.gz',size:zipped.length,hash:createHash('sha256').update(zipped).digest('hex')};
  const elements = Object.fromEntries(['load-detail','status-progress','load-meter','load-hint','load-cache','load-retry'].map(id=>[id,{isConnected:true,hidden:true,textContent:''}]));
  const requests=[];
  const context = {console,URL,Response,DecompressionStream,Uint8Array,AbortController,crypto:webcrypto,performance,setTimeout:fastTimeout ? ((fn,ms)=>setTimeout(fn,ms===25000?5:ms)) : setTimeout,clearTimeout,setInterval:()=>0,clearInterval:()=>{},location:{href:'https://example.test/game/',reload(){}},document:{getElementById:id=>elements[id]},caches:{open:async()=>{
    if(brokenStorage) throw Error('denied');
    return {match:async key=>store.has(key)?new Response(store.get(key)):undefined,put:async(key,value)=>{if(brokenWrite)throw Error('quota');store.set(key,await value.arrayBuffer());}};
  }}};
  context.window={TANTU_ASSETS:{'index.wasm':asset,...(includePack?{'index.pck':{...asset,file:'index.pck.gz'}}:{})},fetch:async(url,init)=>{requests.push(url);return response?response(zipped,init):new Response(zipped);}};
  context.window.DecompressionStream=DecompressionStream;
  vm.runInNewContext(code,context);
  return {fetch:context.window.fetch,requests,elements,raw,store,asset};
}
test('cold download is byte-correct, cached, and reports transfer completion',async()=>{
  const env=setup(); const result=await env.fetch('index.wasm');
  assert.deepEqual(Buffer.from(await result.arrayBuffer()),env.raw);
  assert.equal(result.headers.get('content-type'),'application/wasm');
  assert.match(env.requests[0],/game\/index.wasm.gz\?v=/);
  assert.match(env.elements['load-meter'].textContent,/100%/);
  assert.match(env.elements['load-detail'].textContent,/启动游戏/);
  assert.equal(env.store.size,1);
});
test('second visit reuses verified cache without downloading',async()=>{
  const first=setup(); await (await first.fetch('index.wasm')).arrayBuffer();
  const second=setup({store:first.store}); await (await second.fetch('index.wasm')).arrayBuffer();
  assert.equal(second.requests.length,0); assert.match(second.elements['load-cache'].textContent,/已使用本地缓存/);
});
test('changed asset hash invalidates old cached version',async()=>{
  const first=setup(); await (await first.fetch('index.wasm')).arrayBuffer();
  const next=setup({store:first.store,version:'two'});
  assert.deepEqual(Buffer.from(await (await next.fetch('index.wasm')).arrayBuffer()),next.raw);
  assert.equal(next.requests.length,1);
});
test('corrupt cache falls back to a real download',async()=>{
  const first=setup();await (await first.fetch('index.wasm')).arrayBuffer();
  for(const key of first.store.keys()) first.store.set(key,Buffer.alloc(first.asset.size));
  const next=setup({store:first.store});await (await next.fetch('index.wasm')).arrayBuffer();
  assert.equal(next.requests.length,1);
});
test('storage denial does not prevent loading',async()=>{
  const env=setup({brokenStorage:true});assert.deepEqual(Buffer.from(await (await env.fetch('index.wasm')).arrayBuffer()),env.raw);
});
test('HTTP failure is visible and offers retry',async()=>{
  const env=setup({response:()=>new Response('not found',{status:404})});
  await assert.rejects(env.fetch('index.wasm'),/404/);
  assert.equal(env.elements['load-retry'].hidden,false);assert.match(env.elements['load-hint'].textContent,/404/);
});
test('truncated payload is rejected and never cached',async()=>{
  const env=setup({response:bytes=>new Response(bytes.subarray(0,5))});
  await assert.rejects(env.fetch('index.wasm'),/不完整/);assert.equal(env.store.size,0);
});
test('same-length corrupted payload is rejected by digest',async()=>{
  const env=setup({response:bytes=>new Response(Buffer.alloc(bytes.length))});
  await assert.rejects(env.fetch('index.wasm'),/不完整/);assert.equal(env.store.size,0);
});
test('unrelated origin and path bypass interception',async()=>{
  const env=setup();await env.fetch('https://other.test/game/index.wasm');await env.fetch('/other/index.wasm');
  assert.deepEqual(env.requests,['https://other.test/game/index.wasm','/other/index.wasm']);
});

test('one completed file cannot report overall completion',async()=>{
  const env=setup({includePack:true}); await (await env.fetch('index.wasm')).arrayBuffer();
  assert.match(env.elements['load-meter'].textContent,/50%/);
  await (await env.fetch('index.pck')).arrayBuffer();
  assert.match(env.elements['load-meter'].textContent,/100%/);
});
test('cache write quota failure does not prevent play',async()=>{
  const env=setup({brokenWrite:true});assert.deepEqual(Buffer.from(await (await env.fetch('index.wasm')).arrayBuffer()),env.raw);
});
test('stalled download aborts, explains the wait, and permits retry',async()=>{
  const env=setup({fastTimeout:true,response:(_,init)=>new Promise((resolve,reject)=>init.signal.addEventListener('abort',()=>{const e=Error('abort');e.name='AbortError';reject(e);} ))});
  await assert.rejects(env.fetch('index.wasm'),/abort/);
  assert.match(env.elements['load-hint'].textContent,/25 秒/);assert.equal(env.elements['load-retry'].hidden,false);
});

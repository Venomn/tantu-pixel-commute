/* Compressed, content-addressed game assets. No save data is stored here. */
(() => {
  const assets = window.TANTU_ASSETS;
  const nativeFetch = window.fetch.bind(window);
  const started = performance.now();
  const records = Object.fromEntries(Object.keys(assets).map(name => [name, {bytes: 0, done: false, cached: false}]));
  const total = Object.values(assets).reduce((sum, asset) => sum + asset.size, 0);
  const samples = [[started, 0]];
  let networkBytes = 0;
  let lastByteAt = started;
  let failed = false;
  const label = document.getElementById('load-detail');
  const progress = document.getElementById('status-progress');
  const meter = document.getElementById('load-meter');
  const hint = document.getElementById('load-hint');
  const mb = bytes => (bytes / 1048576).toFixed(1) + ' MB';
  function render() {
    const now = performance.now();
    if (failed || !label.isConnected) return;
    const values = Object.values(records);
    const bytes = values.reduce((sum, record) => sum + record.bytes, 0);
    const complete = values.every(record => record.done);
    samples.push([now, networkBytes]);
    while (samples.length > 2 && samples[1][0] < now - 4000) samples.shift();
    const rate = (networkBytes - samples[0][1]) / Math.max(.25, (now - samples[0][0]) / 1000);
    const percent = complete ? 100 : Math.min(99, Math.floor(bytes / total * 100));
    progress.max = total; progress.value = bytes;
    meter.textContent = `${percent}% · ${mb(bytes)} / ${mb(total)}`;
    if (complete) {
      label.textContent = '资源已就绪 · 正在启动游戏';
      hint.textContent = `已等待 ${Math.floor((now - started) / 1000)} 秒 · 正在编译引擎和准备画面，速度取决于设备`;
    } else {
      label.textContent = values.some(record => record.cached) ? '正在读取缓存 / 下载更新' : '正在下载游戏资源';
      const speed = rate >= 1048576 ? mb(rate) + '/s' : Math.round(rate / 1024) + ' KB/s';
      const remaining = rate > 1024 ? `预计还需约 ${Math.max(1, Math.ceil((total - bytes) / rate))} 秒下载` : '正在估算剩余时间';
      hint.textContent = now - lastByteAt > 5000 ? `网络暂时没有新数据 · 已等待 ${Math.floor((now - lastByteAt) / 1000)} 秒` : `${speed} · ${remaining}`;
    }
    document.getElementById('load-cache').textContent = values.filter(record => record.cached).length ? '已使用本地缓存，缓存部分无需重复下载' : '首次需要下载引擎；之后会缓存，更新只下载变化的资源';
  }
  const timer = setInterval(() => {
    if (!label.isConnected || failed) clearInterval(timer);
    else render();
  }, 250);
  const valid = async (bytes, asset) => {
    if (bytes.byteLength !== asset.size) return false;
    const hash = Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', bytes)), b => b.toString(16).padStart(2, '0')).join('');
    return hash === asset.hash;
  };
  async function load(name, init) {
    const asset = assets[name];
    const record = records[name];
    const url = new URL(asset.file, location.href);
    url.searchParams.set('v', asset.hash.slice(0, 16));
    let cache;
    try { cache = await caches.open('tantu-compressed-assets-v1'); } catch (_) { /* Storage is optional. */ }
    if (cache) {
      try {
        const hit = await cache.match(url.href);
        if (hit) {
          const bytes = await hit.arrayBuffer();
          if (await valid(bytes, asset)) {
            record.bytes = bytes.byteLength; record.cached = true; record.done = true; render();
            return bytes;
          }
        }
      } catch (_) { /* Bad/unavailable cache must fall back to network. */ }
    }
    const controller = new AbortController();
    let timeout;
    const armTimeout = () => { clearTimeout(timeout); timeout = setTimeout(() => controller.abort(), 25000); };
    armTimeout();
    try {
      const response = await nativeFetch(url.href, {...init, signal: controller.signal});
      if (!response.ok) throw new Error(`下载失败（HTTP ${response.status}）`);
      const reader = response.body.getReader();
      const chunks = [];
      let size = 0;
      while (true) {
        const {done, value} = await reader.read();
        if (done) break;
        chunks.push(value); size += value.byteLength; networkBytes += value.byteLength;
        record.bytes = size; lastByteAt = performance.now(); armTimeout(); render();
      }
      clearTimeout(timeout);
      const bytes = new Uint8Array(size);
      let offset = 0;
      for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.byteLength; }
      if (!await valid(bytes, asset)) throw new Error('下载不完整，请重试');
      record.done = true; render();
      if (cache) { try { await cache.put(url.href, new Response(bytes)); } catch (_) { /* Quota/private mode must not block play. */ } }
      return bytes;
    } finally { clearTimeout(timeout); }
  }
  window.fetch = async (input, init) => {
    const url = new URL(typeof input === 'string' ? input : input.url, location.href);
    const name = url.pathname.split('/').pop();
    const base = new URL('.', location.href);
    if (url.origin !== base.origin || url.pathname !== base.pathname + name || !assets[name]) return nativeFetch(input, init);
    try {
      if (!('DecompressionStream' in window)) throw new Error('浏览器版本较旧，请更新浏览器后再试');
      const bytes = await load(name, init);
      return new Response(new Response(bytes).body.pipeThrough(new DecompressionStream('gzip')), {headers: {'Content-Type': name.endsWith('.wasm') ? 'application/wasm' : 'application/octet-stream'}});
    } catch (error) {
      failed = true;
      label.textContent = '加载没有完成';
      hint.textContent = error.name === 'AbortError' ? '网络连续 25 秒没有新数据，请检查网络后重试' : error.message;
      document.getElementById('load-retry').hidden = false;
      throw error;
    }
  };
  document.getElementById('load-retry').onclick = () => location.reload();
  render();
})();

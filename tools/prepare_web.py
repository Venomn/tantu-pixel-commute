"""Prepare Godot export for static hosting without a >25 MiB asset.
The browser streams decompression; no server-specific response headers needed.
Run after every Godot Web export.
"""
from pathlib import Path
import gzip, hashlib
root=Path(__file__).resolve().parents[1]
dist=root/'dist'
raw=dist/'index.wasm'
if raw.exists():
    data=raw.read_bytes()
    compressed=gzip.compress(data,compresslevel=9,mtime=0)
    assert gzip.decompress(compressed)==data
    (dist/'index.wasm.gz').write_bytes(compressed)
    print(f'WebAssembly: {len(data):,} -> {len(compressed):,} bytes; SHA256 {hashlib.sha256(data).hexdigest()}')
    raw.unlink()
html=(dist/'index.html').read_text()
if 'tantu-compressed-loader' not in html:
    loader='''<script id="tantu-compressed-loader">
// Intercept only the exported engine binary; every other request is unchanged.
const originalFetch = window.fetch.bind(window);
window.fetch = async function(input, init) {
  const url = new URL(typeof input === 'string' ? input : input.url, location.href);
  if (url.origin === location.origin && url.pathname.endsWith('/index.wasm')) {
    if (!('DecompressionStream' in window)) throw new Error('请使用较新版本的 Chrome、Edge、Safari 或 Firefox。');
    url.pathname += '.gz';
    const response = await originalFetch(url.href, init);
    if (!response.ok) throw new Error('游戏引擎下载失败，请刷新重试 (' + response.status + ')');
    return new Response(response.body.pipeThrough(new DecompressionStream('gzip')), {
      status: 200, headers: {'Content-Type': 'application/wasm'}
    });
  }
  return originalFetch(input, init);
};
</script>
<style>
#status-splash{display:none!important}
#status:before{content:'痰途 · 全勤之路';color:#f6ce55;font:700 34px sans-serif;margin-bottom:20px}
#status:after{content:'正在装好车铃、擦亮衬衫… 首次加载请稍等';color:#f7efd5;font:15px sans-serif}
#status-progress{position:relative;bottom:auto;width:min(360px,75%);height:12px;margin:12px auto 25px;accent-color:#f6ce55}
#rotate-hint{display:none;position:fixed;bottom:10px;left:12px;right:12px;text-align:center;color:#f7efd5;font:14px sans-serif;pointer-events:none}
@media(orientation:portrait) and (max-width:700px){#rotate-hint{display:block}}
</style>
'''
    html=html.replace('<script src="index.js"></script>',loader+'<script src="index.js"></script>')
    html=html.replace('<html lang="en">','<html lang="zh-CN">')
    html=html.replace('</body>','<div id="rotate-hint">横过手机骑行，按钮会更好按 ↻</div></body>')
    html=html.replace('Your browser does not support the canvas tag.','当前浏览器不支持游戏画布。请使用较新版本的浏览器。')
    (dist/'index.html').write_text(html)
(dist/'licenses.txt').write_text('Godot Engine\n\n'+(root/'GODOT-LICENSE.txt').read_text()+'\n\nNoto Sans SC\n\n'+(root/'assets/FONT-LICENSE.txt').read_text())
for file in dist.glob('*.import'): file.unlink()
assert max(f.stat().st_size for f in dist.iterdir() if f.is_file())<25*1024*1024
print('Static build ready; all files <25 MiB')

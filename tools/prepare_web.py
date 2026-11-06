"""Compress Web assets, install measured loading UI and content-addressed caching."""
from pathlib import Path
import gzip, hashlib, json, re
root = Path(__file__).resolve().parents[1]
dist = root / 'dist'
text = ''.join(p.read_text() for p in sorted((root / 'scripts').glob('*.gd')))
characters = set(map(ord, text)) | set(range(32, 127))
manifest = json.loads((root / 'tools/font_manifest.json').read_text())
assert manifest['characters'] == hashlib.sha256(''.join(map(chr, sorted(characters))).encode()).hexdigest(), 'Game text changed: run tools/subset_font.py before exporting'
assert manifest['font'] == hashlib.sha256((root / 'assets/Chinese.otf').read_bytes()).hexdigest(), 'Font changed: regenerate before exporting'
assets = {}
for name in ('index.wasm', 'index.pck'):
    raw = dist / name
    zipped = dist / (name + '.gz')
    if raw.exists():
        data = raw.read_bytes()
        compressed = gzip.compress(data, compresslevel=9, mtime=0)
        assert gzip.decompress(compressed) == data
        zipped.write_bytes(compressed)
        print(f'{name}: {len(data):,} -> {len(compressed):,} bytes')
        if name.endswith('.wasm'): raw.unlink()
    compressed = zipped.read_bytes()
    assets[name] = {'file': zipped.name, 'size': len(compressed), 'hash': hashlib.sha256(compressed).hexdigest()}
html = (dist / 'index.html').read_text()
# Idempotently replace our own injection, including exports prepared by the old loader.
html = re.sub(r'<script id="tantu-compressed-loader">.*?</style>\s*', '', html, flags=re.S)
html = re.sub(r'<div id="rotate-hint">.*?</div>', '', html)
html = re.sub(r'<!-- tantu-mobile-shell -->.*?<!-- /tantu-mobile-shell -->\s*', '', html, flags=re.S)
html = re.sub(r'<!-- tantu-app-meta -->.*?<!-- /tantu-app-meta -->', '', html, flags=re.S)
html = re.sub(r'<!-- tantu-status -->.*?<!-- /tantu-status -->', '', html, flags=re.S)
status = '''<!-- tantu-status -->
<h1>痰途 · 全勤之路</h1>
<p id="load-detail" role="status">正在连接游戏资源</p>
<p id="load-meter">0%</p>
<p id="load-hint">正在测量下载速度…</p>
<p id="load-cache">首次加载后会缓存引擎</p>
<button id="load-retry" hidden>重新加载</button>
<!-- /tantu-status -->'''
html = html.replace('<progress id="status-progress">', status + '<progress id="status-progress">')
loader = '<script id="tantu-compressed-loader">\nwindow.TANTU_ASSETS=' + json.dumps(assets) + ';\n' + (root/'tools/web_loader.js').read_text() + '\n</script>\n'
loader += '''<style>
#status-splash{display:none!important}
#status{font-family:system-ui,sans-serif;padding:24px;box-sizing:border-box;text-align:center;gap:8px}
#status h1{font-size:clamp(24px,5vw,34px);color:#f6ce55;margin:0 0 20px}
#status p{margin:0;max-width:600px}
#load-detail{font-size:20px;color:#fff3d1}
#load-meter{font-size:26px;font-variant-numeric:tabular-nums;color:#f6ce55}
#load-hint{font-size:15px;min-height:42px;color:#fff3d1}
#load-cache{font-size:13px;color:#b9cec7}
#status-progress{position:relative;bottom:auto;width:min(420px,85%);height:14px;margin:10px auto 20px;accent-color:#f6ce55;order:1}
#status-notice{position:static;max-width:600px;font-size:13px}
#load-retry{padding:12px 28px;background:#f6ce55;color:#293b57;border:3px solid #fff3d1;font-size:16px;cursor:pointer}
</style>
'''
html = html.replace('<script src="index.js"></script>', loader + '<script src="index.js"></script>')
html = html.replace('<html lang="en">', '<html lang="zh-CN">')
html = html.replace('</body>', (root/'tools/mobile_shell.html').read_text()+'</body>')
html = html.replace('user-scalable=no', 'user-scalable=no, viewport-fit=cover') if 'viewport-fit=cover' not in html else html
html = html.replace('</head>', '<!-- tantu-app-meta --><link rel="manifest" href="manifest.webmanifest"><meta name="apple-mobile-web-app-capable" content="yes"><meta name="apple-mobile-web-app-status-bar-style" content="black-translucent"><meta name="theme-color" content="#24394c"><!-- /tantu-app-meta --></head>')
(dist/'manifest.webmanifest').write_text(json.dumps({'name':'痰途 · 全勤之路','short_name':'痰途','start_url':'./','scope':'./','display':'standalone','background_color':'#24394c','theme_color':'#24394c','icons':[{'src':'app-icon.svg','sizes':'any','type':'image/svg+xml'}]},ensure_ascii=False))
html = html.replace('Your browser does not support the canvas tag.', '当前浏览器不支持游戏画布。请使用较新版本的浏览器。')
# Godot reports uncompressed byte counts; our progress reports actual transfer bytes instead.
html = re.sub(r"'onProgress': function \(current, total\) \{.*?\n\t\t\t\},", "'onProgress': function () {},", html, flags=re.S)
# Also expose retry for failures that occur after downloads (e.g. WebGL initialization).
html = re.sub(r"function displayFailureNotice\(err\) \{(?:\n document.getElementById\('load-retry'\).hidden = false;)*", "function displayFailureNotice(err) {\n document.getElementById('load-retry').hidden = false;", html)
(dist/'app-icon.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><rect width="64" height="64" rx="12" fill="#293b57"/><path d="M12 12h40v10H37v30H27V22H12z" fill="#f2d27d"/></svg>')
(dist / 'index.html').write_text(html)
(dist / 'licenses.txt').write_text('Godot Engine\n\n' + (root/'GODOT-LICENSE.txt').read_text() + '\n\nNoto Sans SC\n\n' + (root/'assets/FONT-LICENSE.txt').read_text())
for file in dist.glob('*.import'): file.unlink()
assert max(f.stat().st_size for f in dist.iterdir() if f.is_file()) < 25*1024*1024
print(f'Initial compressed assets: {sum(asset["size"] for asset in assets.values()):,} bytes')

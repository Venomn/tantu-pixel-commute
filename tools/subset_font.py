"""Rebuild the shipping font from all game scripts, retaining every used glyph."""
from pathlib import Path
import hashlib, json
from fontTools import subset
from fontTools.ttLib import TTFont

root = Path(__file__).resolve().parents[1]
source = root / 'tools/fonts/Chinese-full.otf'
target = root / 'assets/Chinese.otf'
text = ''.join(p.read_text() for p in sorted((root / 'scripts').glob('*.gd')))
characters = set(map(ord, text)) | set(range(32, 127))
font = TTFont(source)
available = set(font.getBestCmap())
options = subset.Options()
options.recalc_timestamp = False
subsetter = subset.Subsetter(options=options)
subsetter.populate(unicodes=characters)
subsetter.subset(font)
font.save(target)
actual = set(TTFont(target).getBestCmap())
assert (characters & available) <= actual, 'A source glyph was lost'
(root / 'tools/font_manifest.json').write_text(json.dumps({
    'characters': hashlib.sha256(''.join(map(chr, sorted(characters))).encode()).hexdigest(),
    'font': hashlib.sha256(target.read_bytes()).hexdigest(),
}, indent=2) + '\n')
print(f'Font: {source.stat().st_size:,} -> {target.stat().st_size:,} bytes; {len(actual)} glyphs covered')

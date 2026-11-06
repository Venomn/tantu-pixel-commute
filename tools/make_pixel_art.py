"""Original small-grid handheld RPG art. Pure Python PNG writer, no external assets."""
from pathlib import Path
import zlib, struct, random
OUT=Path(__file__).resolve().parents[1]/'assets'/'pixel'
OUT.mkdir(exist_ok=True)
def rgba(c):
    if isinstance(c,tuple): return c
    c=c.lstrip('#');return tuple(int(c[i:i+2],16) for i in (0,2,4))+(255,)
class Art:
    def __init__(self,w,h,bg=(0,0,0,0)):
        self.w,self.h=w,h;self.data=[[rgba(bg) for _ in range(w)] for _ in range(h)]
    def p(self,x,y,c):
        if 0<=x<self.w and 0<=y<self.h:self.data[int(y)][int(x)]=rgba(c)
    def rect(self,x,y,w,h,c):
        for yy in range(int(y),int(y+h)):
            for xx in range(int(x),int(x+w)):self.p(xx,yy,c)
    def ellipse(self,x,y,w,h,c):
        for yy in range(int(y),int(y+h)):
            for xx in range(int(x),int(x+w)):
                if ((xx+.5-x-w/2)/(w/2))**2+((yy+.5-y-h/2)/(h/2))**2<=1:self.p(xx,yy,c)
    def line(self,x1,y1,x2,y2,c):
        n=max(abs(x2-x1),abs(y2-y1),1)
        for i in range(n+1):self.p(round(x1+(x2-x1)*i/n),round(y1+(y2-y1)*i/n),c)
    def save(self,name,flip=False):
        raw=b''.join(b'\0'+bytes(sum((list(px) for px in (row[::-1] if flip else row)),[])) for row in self.data)
        def chunk(t,d):return struct.pack('>I',len(d))+t+d+struct.pack('>I',zlib.crc32(t+d)&0xffffffff)
        png=b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',self.w,self.h,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(raw,9))+chunk(b'IEND',b'')
        (OUT/(name+'.png')).write_bytes(png)
O='35465b'; SH='678350'; SK='f5c49a'; SS='cf9477'; HI='fff2cf'; HA='70554a'
# 16x16 repeating ground tiles, built at their intended pixel resolution.
a=Art(16,16,'8fc96a')
for x,y in [(2,3),(10,8),(6,13)]:
    a.p(x,y,'73ad5b');a.p(x+1,y+1,'73ad5b');a.p(x+2,y,'73ad5b');a.p(x+1,y-1,'aada79')
a.save('grass')
a=Art(16,16,'e8d7a4')
for x,y in [(3,4),(11,10),(6,13),(13,2)]:a.rect(x,y,2,1,'ddca92');a.p(x,y-1,'f1e4bc')
a.save('road')
a=Art(16,16,'e9e2be');a.rect(0,0,16,1,'f9f1d4');a.rect(0,15,16,1,'c0bc9b');a.rect(15,0,1,16,'c0bc9b');a.rect(0,7,16,1,'cec8a6');a.rect(7,0,1,7,'cec8a6');a.rect(3,8,1,7,'cec8a6');a.save('paving')
a=Art(16,16)
for x in [2,11]:
    a.rect(x,4,3,11,'6b7558');a.rect(x,2,3,12,'faf0ce');a.p(x+1,1,'faf0ce');a.rect(x+2,4,1,10,'c4c5a1')
a.rect(0,6,16,3,'fbf0cb');a.rect(0,9,16,1,'adba94');a.save('fence')
a=Art(16,16)
for x,y,c in [(3,4,'ef8391'),(11,9,'f6df85'),(5,13,'f4eef1')]:
    a.rect(x,y,1,3,'478857');a.rect(x-1,y+1,3,1,'61a55c');a.p(x-1,y-1,c);a.p(x+1,y-1,c);a.p(x,y-2,c);a.p(x,y,'fff1c4')
a.save('flowers')
a=Art(16,32)
a.ellipse(3,27,12,4,(60,93,64,65));a.rect(7,8,3,21,'536578');a.rect(8,8,1,19,'97b0aa');a.rect(5,27,7,3,'536578');a.rect(4,4,9,7,'40566b');a.rect(5,5,7,5,'f6e6a0');a.rect(3,3,11,2,'718c92');a.rect(5,1,7,2,'40566b');a.save('lamp')
# Rounded leaf clusters with stepped contours, three values and sparse leaf highlights.
a=Art(32,40);a.ellipse(3,29,27,9,(49,94,65,70));a.rect(13,23,7,13,'655b47');a.rect(14,25,3,10,'b38b59');a.rect(18,27,2,10,'7e6b48')
for x,y,w,h in [(2,11,28,20),(5,3,23,24),(9,0,15,14)]:a.ellipse(x,y,w,h,'345f49')
for x,y,w,h in [(3,10,25,18),(6,3,20,20),(10,1,13,12)]:a.ellipse(x,y,w,h,'43875a')
for x,y,w,h in [(5,8,12,12),(12,5,12,11),(8,2,12,11),(12,14,13,9),(5,18,12,8)]:a.ellipse(x,y,w,h,'65ac62')
for x,y,w,h in [(8,4,10,6),(4,12,8,4),(17,9,7,4),(11,19,8,4)]:a.ellipse(x,y,w,h,'91ca73')
for x,y in [(5,19),(9,12),(18,16),(23,20),(13,25),(20,6)]:a.line(x,y,x+2,y-1,'b0d77f');a.p(x+3,y,'65ac62')
a.save('tree')
# Shaded tiled roofs, window glass, front-facing doors and flower boxes.
for variant,(roof,light,shade) in enumerate([('c66c60','e79572','914d56'),('6a91b0','a1c9cf','49667f'),('ae889e','d7adb0','775f83'),('b59c64','e7c582','887553')]):
    a=Art(52,56);a.rect(4,47,46,7,(56,79,72,55));a.rect(5,21,42,30,O);a.rect(7,23,38,26,'f4ebcb');a.rect(7,46,38,3,'bdba9a')
    for y in range(27,46,6):a.rect(8,y,36,1,'e0d8b6')
    for y in range(2,26):
        inset=max(0,9-y//2);a.rect(inset,y,52-2*inset,1,shade if y%4==1 else roof)
        if y%4==0:
            a.rect(inset,y,52-2*inset,1,light)
            for x in range(inset+3,52-inset,7):a.p(x,y+1,shade)
    a.rect(0,25,52,3,shade);a.rect(1,28,50,2,'786a60')
    a.rect(34,2,8,12,O);a.rect(35,1,7,11,'d2c5a2');a.rect(34,0,9,3,'f1dfba');a.rect(37,2,4,1,'847a6c')
    for x in [10,33]:
        a.rect(x,32,10,11,O);a.rect(x+1,33,8,8,'83b7be');a.line(x+2,39,x+7,34,'c9e4da');a.rect(x+4,33,1,9,'f9f0d0');a.rect(x,42,10,2,'d9cbae')
        a.rect(x-1,45,12,2,'886950');a.rect(x,44,10,1,'639c5c')
        for xx in [x+1,x+5,x+8]:a.p(xx,43,'ea8a8c')
    a.rect(23,34,7,17,O);a.rect(24,35,5,15,'b58b66');a.rect(25,36,1,13,'ddbb86');a.p(28,43,'fff0b8');a.rect(21,51,11,2,'d3d1b2');a.rect(20,53,13,2,'b4b69d')
    a.save('house'+str(variant))
# Pedestrians: oversized heads, outlined hair, shaded clothing, two-step walking.
for variant,(shirt,shade) in enumerate([('de7f81','a75268'),('e6c267','b59657'),('65a7a5','497b8e'),('a78db4','786d99'),('eee4bf','b8b7a7')]):
  for frame in range(2):
    a=Art(16,24);a.ellipse(2,20,13,4,(47,73,73,65));a.rect(4,16,8,5,O);a.rect(4+frame,20,3,2,O);a.rect(10-frame,21,3,2,O)
    a.rect(3,10,10,8,O);a.rect(4,10,8,8,shirt);a.rect(4,16,8,2,shade);a.rect(2,12,2,5,SS);a.rect(12,12,2,5,SS);a.p(2,12,SK);a.p(13,12,SK)
    a.ellipse(2,1,12,12,O);a.ellipse(3,2,10,11,SS);a.ellipse(3,2,10,9,SK);a.rect(4,2,8,4,HA);a.rect(3,4,3,3,HA);a.p(6,8,O);a.p(10,8,O);a.p(8,11,SS)
    if variant%2==0:a.rect(4,1,8,3,shade);a.rect(2,4,12,2,shirt);a.rect(5,1,6,1,HI)
    else:a.rect(4,2,7,2,'9f7651');a.p(4,6,HA);a.p(12,6,HA)
    a.save('person%d_%d'%(variant,frame))
# Bicycles: north-facing rider with visible handlebars, spokes and animated pedals.
for variant,(helmet,jacket,shade) in enumerate([('efd16b','5caaa8','427c8f'),('8e9bca','dca07e','ae7d72'),('d88b91','91b781','5e8c6c')]):
  for frame in range(2):
    a=Art(24,34);a.ellipse(3,28,18,5,(50,77,73,65))
    for y in [0,25]:a.rect(10,y,4,8,O);a.rect(11,y+1,2,6,'c1d5cc');a.p(11+frame,y+3,HI)
    a.line(11,12,11,28,'467b84');a.line(12,12,13,28,'80c3c0');a.rect(4,13,16,2,O);a.p(4,12,'aabcb1');a.p(19,12,'aabcb1')
    a.rect(6,21,5,7,O);a.rect(14,21,5,7,O);a.rect(5,27-frame*2,5,2,shade);a.rect(15,25+frame*2,5,2,shade)
    a.ellipse(5,11,14,13,O);a.rect(6,12,12,11,jacket);a.rect(6,20,12,3,shade);a.rect(4,14,3,4,SS);a.rect(17,14,3,4,SS);a.p(4,14,SK);a.p(19,14,SK)
    a.rect(8,14,8,8,'9a6c4f');a.rect(9,14,6,6,'dfaa66');a.rect(10,14,4,1,'f9d58a');a.rect(10,19,4,1,'b78351')
    a.ellipse(5,2,14,12,O);a.ellipse(6,3,12,10,SS);a.rect(7,10,10,3,HA);a.ellipse(5,2,14,9,helmet);a.rect(6,8,12,2,HI);a.rect(8,2,8,1,HI);a.rect(7,11,10,1,HA)
    a.save('bike%d_%d'%(variant,frame))
# Sideways riding pose for steering, separate mirrored left frames.
for frame in range(2):
    a=Art(28,32);a.ellipse(1,27,26,4,(50,77,73,65))
    for x in [1,18]:
        a.ellipse(x,21,9,10,O);a.ellipse(x+1,22,7,8,'b9d2cb');a.ellipse(x+2,23,5,6,'e6e4c0');a.line(x+4,23,x+4,28,O);a.line(x+2,26,x+6,26,O)
    for x1,y1,x2,y2 in [(5,26,11,19),(11,19,21,26),(5,26,15,26),(15,26,19,18),(19,18,22,18)]:a.line(x1,y1,x2,y2,'437b89')
    a.rect(9,17,5,2,O);a.rect(10,13,7,7,'5caaa8');a.rect(8,14,4,7,'dfaa66');a.line(15,16,20,18,SK);a.rect(11,20,4,3,O);a.line(13,22,11+frame*4,26,O)
    a.ellipse(9,3,13,12,O);a.ellipse(10,4,11,11,SK);a.rect(10,10,4,4,HA);a.p(19,10,O);a.ellipse(8,2,14,8,'efd16b');a.rect(9,8,15,2,HI);a.rect(12,2,7,1,HI)
    a.save('bike_right%d'%frame);a.save('bike_left%d'%frame,flip=True)
# Motorbike: wide tyres, mirrors, tank and chrome exhaust distinguish it from bicycles.
for frame in range(2):
    a=Art(24,36);a.ellipse(3,30,18,5,(50,77,73,65));a.rect(9,0,6,11,O);a.rect(9,27,6,8,O);a.rect(10,28,4,5,'859eaa')
    a.rect(6,6,12,25,O);a.rect(7,7,10,23,'9884ae');a.rect(8,8,8,4,'d0b5c4');a.rect(8,25,8,5,'716883')
    a.rect(20,24,3,10,'557180');a.rect(20,24,1,9,'dbe2cf');a.rect(3,11,18,2,O);a.rect(1,9,4,3,'9fc6cb');a.rect(19,9,4,3,'9fc6cb')
    a.rect(5,20,5,9,O);a.rect(14,20,5,9,O);a.ellipse(5,11,14,15,O);a.rect(6,12,12,12,'c28286');a.rect(7,13,10,8,'e1aaa1');a.rect(4,13,2,5,SK);a.rect(18,13,2,5,SK)
    a.ellipse(5,2,14,12,O);a.ellipse(6,3,12,10,'5b6d91');a.rect(6,8,12,3,'abd0ce');a.rect(8,3,7,2,'8a9fbc');a.rect(9,30,6,2,'ad655f');a.save('moto%d'%frame)
for variant,(body,shade,light) in enumerate([('7baab5','52788e','bdd3cc'),('de9390','a96779','f2c0a3'),('a9ba80','758f68','d5dea7'),('a1a5cb','707fa2','d1d4e0')]):
    a=Art(28,46);a.ellipse(0,35,28,10,(50,77,73,65))
    for x in [0,25]:
        for y in [9,31]:a.rect(x,y,3,9,O);a.rect(x+1,y+1,1,7,'516475')
    a.rect(3,3,22,39,O);a.rect(5,1,18,43,O);a.rect(4,4,20,36,body);a.rect(6,2,16,41,body);a.rect(5,4,2,35,light);a.rect(22,5,2,34,shade);a.rect(6,40,16,3,shade)
    a.rect(6,5,16,7,light);a.rect(7,7,14,4,body);a.rect(5,13,18,10,O);a.rect(6,14,16,8,'6e9fae');a.line(7,20,13,14,'c3d9d2');a.line(12,21,18,15,'a5cbcd')
    a.rect(8,24,12,10,shade);a.rect(8,24,12,7,body);a.rect(9,24,10,1,light);a.rect(6,35,16,5,O);a.rect(7,36,14,3,'8fb1b5')
    a.rect(3,17,2,13,shade);a.rect(23,17,2,13,shade);a.rect(1,16,3,3,body);a.rect(24,16,3,3,body)
    a.rect(5,3,5,3,HI);a.rect(18,3,5,3,HI);a.rect(5,41,5,2,'ba686b');a.rect(18,41,5,2,'ba686b');a.rect(11,42,6,2,'eee4c0')
    a.rect(5,18,4,5,SK);a.rect(5,17,4,2,HA);a.save('car'+str(variant))
print('Generated',len(list(OUT.glob('*.png'))),'original handheld-style pixel assets')

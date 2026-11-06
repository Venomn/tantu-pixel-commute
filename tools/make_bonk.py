"""Original short cartoon spring/falling-whistle sound for the failure animation."""
import math, struct, wave
from pathlib import Path
rate=22050
samples=[]
for i in range(int(rate*1.4)):
    t=i/rate
    spring=.26*math.sin(2*math.pi*(95*t+18*(1-math.exp(-t*14))))*math.exp(-t*4)
    whistle=.12*math.sin(2*math.pi*(950*t-300*t*t))*max(0,1-t/.9)
    samples.append(int(max(-.9,min(.9,spring+whistle))*32767))
with wave.open(str(Path(__file__).resolve().parents[1]/'assets/bonk.wav'),'w') as f:
    f.setparams((1,2,rate,0,'NONE','not compressed'))
    f.writeframes(struct.pack('<%dh'%len(samples),*samples))

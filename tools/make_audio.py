"""Original procedural chiptune and cartoon Foley. No external audio samples."""
import math, random, struct, wave
from pathlib import Path
random.seed(13)
OUT=Path(__file__).resolve().parents[1]/'assets'
SR=22050

def save(name, values):
    with wave.open(str(OUT/(name+'.wav')), 'w') as w:
        w.setparams((1,2,SR,0,'NONE','not compressed'))
        w.writeframes(b''.join(struct.pack('<h',int(max(-.95,min(.95,v))*32767)) for v in values))

def tone(f,t,shape='square'):
    p=(f*t)%1
    return (1 if p<.25 else -0.333) if shape=='square' else math.sin(2*math.pi*p)

def effect(name,dur,fn):
    save(name,[fn(i/SR)*min(1,i/100)*min(1,(dur-i/SR)*24) for i in range(int(SR*dur))])

effect('bell',.55,lambda t:.3*(math.sin(2*math.pi*1420*t)+.4*math.sin(2*math.pi*2130*t))*math.exp(-t*9))
effect('cough',.65,lambda t:(random.random()-.5)*.65*(1 if .05<t<.2 or .29<t<.47 else .06)+.07*tone(110,t))
effect('spit',.28,lambda t:(random.random()-.5)*.4*math.exp(-t*8)+.14*math.sin(2*math.pi*(650*t-700*t*t)))
effect('splat',.7,lambda t:.3*math.sin(2*math.pi*(140*t-80*t*t))*math.exp(-t*6)+(random.random()-.5)*.3*math.exp(-t*13))
effect('near',.3,lambda t:.14*math.sin(2*math.pi*(700*t+900*t*t)))
effect('click',.09,lambda t:.2*tone(700,t)*math.exp(-t*30))
effect('engine',.65,lambda t:.13*tone(65+180*t,t)*math.sin(math.pi*min(1,t/.65)))
effect('brake',.25,lambda t:.1*tone(1100+t*900,t)+(random.random()-.5)*.08)
effect('win',1.6,lambda t:.23*tone([523,659,784,1047][min(3,int(t/.23))],t)*math.exp(-(t%.23)*6))
effect('lose',1.1,lambda t:.23*tone(max(70,400-290*t),t)*math.exp(-t*2))
music_random_state = random.getstate()
effect('coin',.18,lambda t:.15*tone(1320 if t<.07 else 1760,t)*math.exp(-t*12))
effect('shield',.32,lambda t:.2*math.sin(2*math.pi*(500*t+1600*t*t))*math.exp(-t*7))
effect('shoot',.25,lambda t:.18*tone(max(90,900-2600*t),t)*math.exp(-t*8))
effect('return',.4,lambda t:.19*math.sin(2*math.pi*(350*t+1800*t*t))*math.exp(-t*5))
effect('trash',.35,lambda t:.15*tone(180,t)*math.exp(-t*8)+(random.random()-.5)*.12*math.exp(-t*9))
random.setstate(music_random_state)
# 16 bars, syncopated lead, bass and brushed noise percussion, 116 BPM.
step=60/116/4
notes=[76,0,79,0,81,79,76,72,74,0,76,0,79,76,74,71,72,0,76,79,83,0,81,79,76,74,72,71,69,71,72,0]
for day in range(5):
    n=256; buf=[]
    for i in range(int(n*step*SR)):
        t=i/SR; k=int(t/step); u=t%step
        note=notes[(k+(day%2)*8)%len(notes)]
        f=440*2**((note-69+([0,2,5,0,7][day]))/12)
        lead=.11*tone(f,t)*math.exp(-u*15) if note else 0
        root=[48,45,53,55][(k//16)%4]+[0,2,5,0,7][day]
        bass=.12*tone(440*2**((root-69)/12),t,'sine')*math.exp(-(t%(step*2))*6)
        kick=.16*math.sin(2*math.pi*(65*u+2*(1-math.exp(-u*70))))*math.exp(-u*35) if k%4==0 else 0
        hat=(random.random()-.5)*.07*math.exp(-u*65)
        snare=(random.random()-.5)*.16*math.exp(-u*24) if k%8==4 else 0
        buf.append(lead+bass+kick+hat+snare)
    save('music'+str(day),buf)
print('Generated 5 original music loops and 15 effects')

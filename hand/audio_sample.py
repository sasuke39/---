"""样片声音（纯 Python 合成）：火苗、呼吸、颜料喷出、AI 去噪的数据声、结尾的寂静"""
import math,random,struct,wave
SR=44100;N=SR*10;L=[0.]*N;R=[0.]*N;rnd=random.Random(1);TAU=2*math.pi
def put(i,v,p=0.):
    if 0<=i<N:L[i]+=v*(1-max(p,0));R[i]+=v*(1+min(p,0))
def seg(t,a,b):return min(1,max(0,(t-a)/(b-a)))
# 火苗：低通噪声 + 随机噼啪
y=0.
for i in range(N):
    t=i/SR;env=(1-seg(t,2.95,3.05))+seg(t,4.95,5.1)
    if env<=0:continue
    y+=.03*(rnd.uniform(-1,1)-y);put(i,y*.5*env*(.8+.2*math.sin(t*9)))
    if rnd.random()<.0009*env:
        for j in range(int(.006*SR)):put(i+j,rnd.uniform(-1,1)*math.exp(-j/(.0012*SR))*.35*env,rnd.uniform(-.6,.6))
def breath(t0,dur,amp):
    yy=0.
    for j in range(int(dur*SR)):
        tt=j/(dur*SR);yy+=.12*(rnd.uniform(-1,1)-yy);put(int(t0*SR)+j,yy*math.sin(math.pi*tt)**2*amp)
def spray(t0,dur,amp):
    yy=0.
    for j in range(int(dur*SR)):
        tt=j/(dur*SR);n=rnd.uniform(-1,1);yy+=.6*(n-yy);env=min(1,tt*12)*math.exp(-tt*1.5);put(int(t0*SR)+j,(n-yy)*env*amp)
breath(0.0,.5,.6);spray(.35,1.15,.45)
breath(5.1,.6,.6);spray(5.6,1.1,.45)
# AI：每一步一声短促的数字“滋”，音高逐步上升；最后一步一声清脆的提示音
for k in range(20):
    t0=3+1.75*k/20;f=300+k*60
    for j in range(int(.03*SR)):tt=j/SR;put(int(t0*SR)+j,(math.sin(TAU*f*tt)*.5+rnd.uniform(-1,1)*.3)*math.exp(-tt*120)*.4,.3*math.sin(k))
for j in range(int(.4*SR)):tt=j/SR;put(int(4.85*SR)+j,math.sin(TAU*1760*tt)*math.exp(-tt*9)*.25)
# 结尾：心跳
for t0 in (7.55,):
    for dd,aa in ((0,1.),(.19,.6)):
        for j in range(int(.4*SR)):tt=j/SR;f=45+35*math.exp(-tt*28);put(int((t0+dd)*SR)+j,math.sin(TAU*f*tt)*math.exp(-tt*13)*aa*.9)
pk=max(max(map(abs,L)),max(map(abs,R)));g=.89/pk
with wave.open('../out/handprint_sample.wav','wb') as w:
    w.setnchannels(2);w.setsampwidth(2);w.setframerate(SR)
    w.writeframes(b''.join(struct.pack('<hh',int(L[i]*g*32767),int(R[i]*g*32767)) for i in range(N)))
print('ok')

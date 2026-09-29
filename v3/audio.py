"""《递归》v3 声音：一切声音都跟随镜头尺度 log10(S)。输出 out/recursion_v3_audio.wav"""
import math, random, struct, wave, re, json
SR=44100; DUR=20.0; N=int(SR*DUR); L=[0.0]*N; R=[0.0]*N; rnd=random.Random(5); TAU=2*math.pi
src=open('timeline.js',encoding='utf8').read()
keys=json.loads(re.sub(r'(?<![0-9])\.(\d)',r'0.\1',re.sub(r'(\d)\.(?!\d)',r'\1.0',re.search(r'const KEYS=(\[.*?\]\]);',src,re.S).group(1).replace('\n',''))))
# 与 timeline.js 相同的 Fritsch–Carlson 单调三次插值
n=len(keys); d=[(keys[i+1][1]-keys[i][1])/(keys[i+1][0]-keys[i][0]) for i in range(n-1)]; m=[0.0]*n; m[0]=d[0]; m[-1]=d[-1]
for i in range(1,n-1):
    if d[i-1]*d[i]<=0: continue
    h0=keys[i][0]-keys[i-1][0]; h1=keys[i+1][0]-keys[i][0]; w1=2*h1+h0; w2=h1+2*h0; m[i]=(w1+w2)/(w1/d[i-1]+w2/d[i])
def logS(T):
    i=0
    while i<n-2 and T>keys[i+1][0]: i+=1
    t0,y0=keys[i]; t1,y1=keys[i+1]; h=t1-t0; s=min(1,max(0,(T-t0)/h))
    return (2*s**3-3*s**2+1)*y0+(s**3-2*s**2+s)*h*m[i]+(-2*s**3+3*s**2)*y1+(s**3-s**2)*h*m[i+1]
def put(i,v,p=0.):
    if 0<=i<N: L[i]+=v*(1-max(p,0)); R[i]+=v*(1+min(p,0))
def seg(t,a,b): return min(1,max(0,(t-a)/(b-a)))
# 1) 随尺度下降的低频 + 泛音层（1.8s 起）
ph=[0.0]*5; y=0.0
for i in range(N):
    t=i/SR; ls=logS(t); u=min(1,max(0,(ls+1.9)/22.8))
    f=110*(32/110)**u
    env=seg(t,1.6,3.0)*(0.55+0.45*seg(t,3,15.8))*(1-seg(t,16.2,16.5))
    if env<=0: continue
    v=0.0
    for k,(mul,a) in enumerate(((1,.5),(2,.22),(3,.1),(1.5,.12),(4.01,.05))):
        ph[k]+=TAU*f*mul*(1+0.002*k)/SR; v+=math.sin(ph[k])*a
    y+=0.01*(rnd.uniform(-1,1)-y)
    put(i,(v*0.5+y*0.9*(0.4+0.6*u))*env,0.25*math.sin(t*.7))
# 2) 每跨过一个数量级：极轻的泛音铃
prev=logS(0)
for i in range(0,N,64):
    t=i/SR; ls=logS(t)
    if math.floor(ls)>math.floor(prev) and 1.5<t<16.2:
        f=[1318.5,1568,1760,2093,2349,2637][int(math.floor(ls))%6]
        for j in range(int(1.6*SR)):
            tt=j/SR; put(i+j,(math.sin(TAU*f*tt)+.35*math.sin(TAU*f*2.01*tt))*math.exp(-tt*2.6)*0.035,0.5 if int(ls)%2 else -0.5)
    prev=ls
# 3) 标志性时刻
def whoosh(t0,dur,amp,pan=0.):
    yy=0.0; s0=int(t0*SR)
    for j in range(int(dur*SR)):
        tt=j/dur/SR; env=math.sin(math.pi*tt)**2; yy+=(0.02+0.25*tt)*(rnd.uniform(-1,1)-yy); put(s0+j,yy*env*amp,pan*(2*tt-1))
def boom(t0,amp):
    s0=int(t0*SR)
    for j in range(int(1.8*SR)):
        tt=j/SR; f=28+40*math.exp(-tt*7); put(s0+j,math.sin(TAU*f*tt)*math.exp(-tt*2.5)*amp)
whoosh(1.0,0.9,0.25,0.3)      # 泪滴滑落
boom(4.6,0.35)                # 看见整个屋顶
boom(6.3,0.45)                # 城市
whoosh(10.8,0.9,1.1,-1.)      # 月球掠过
# 太阳：温暖的和弦膨胀
for k,f in enumerate((220,277.18,329.63,440)):
    for i in range(int(12.0*SR),int(14.2*SR)):
        t=i/SR; env=math.sin(math.pi*seg(t,12.0,14.2))**2
        put(i,math.sin(TAU*f*t+k)*env*0.05,(k-1.5)*0.3)
# 星系：空灵合唱（14.6-16.3）
for k,f in enumerate((329.63,392,493.88,587.33,659.25)):
    for i in range(int(14.4*SR),int(16.4*SR)):
        t=i/SR; env=seg(t,14.4,15.4)*(1-seg(t,16.1,16.4)); vib=1+0.004*math.sin(TAU*5.5*t+k)
        put(i,math.sin(TAU*f*vib*t)*env*0.04*(0.7+0.3*math.sin(TAU*0.5*t+k)),(k-2)*0.25)
# 4) 黑洞变瞳孔：一切静止，一声心跳
def heart(t0,a):
    for dd,aa in ((0,1.),(0.19,0.6)):
        s0=int((t0+dd)*SR)
        for j in range(int(0.4*SR)):
            tt=j/SR; f=45+35*math.exp(-tt*28); put(s0+j,math.sin(TAU*f*tt)*math.exp(-tt*13)*a*aa)
heart(16.45,1.3); heart(17.5,0.7)
whoosh(16.6,1.6,0.35,0.)
# 5) 结尾：柔和的解决和弦（字幕时）
for k,f in enumerate((220,329.63,440,554.37)):
    for i in range(int(17.8*SR),N):
        t=i/SR; env=seg(t,17.8,18.6)*(1-seg(t,19.2,19.9))
        put(i,math.sin(TAU*f*t)*env*0.035,(k-1.5)*0.3)
# 6) 泪滴重新凝聚：一声清脆水滴（19.82s）
s0=int(19.82*SR)
for j in range(int(0.17*SR)):
    tt=j/SR; f=900+1400*(1-math.exp(-tt*40)); put(s0+j,math.sin(TAU*f*tt)*math.exp(-tt*28)*0.5)
# 7) 首尾相接的微弱高音
for i in range(N):
    t=i/SR; env=max(seg(t,18.8,19.9),1-seg(t,0,1.4))
    if env>0: put(i,(math.sin(TAU*1760*t)+0.5*math.sin(TAU*2637*t+1))*env*0.008)
pk=max(max(abs(x) for x in L),max(abs(x) for x in R)); g=0.89/pk
with wave.open('../out/recursion_v3_audio.wav','wb') as wf:
    wf.setnchannels(2);wf.setsampwidth(2);wf.setframerate(SR)
    wf.writeframes(b''.join(struct.pack('<hh',int(L[i]*g*32767),int(R[i]*g*32767)) for i in range(N)))
print('ok gain',round(g,3))

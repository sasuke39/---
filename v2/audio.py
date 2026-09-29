"""《递归》写实版声音设计（纯 Python 合成）。输出 out/recursion_v2_audio.wav
0-3.2 呼吸 + 冲进瞳孔的上升音 → 3.2 重击 → 城市/轨道/戴森球：逐渐升起的弦乐铺底与低频打击
→ 14.6 一切抽空，只剩星系尺度的低鸣 → 17.3/17.8 心跳 → 结尾近乎寂静（可循环）"""
import math, random, struct, wave, os
SR, DUR = 44100, 20.0
N = int(SR * DUR); L = [0.0]*N; Rr = [0.0]*N; rnd = random.Random(3); TAU = 2*math.pi
def put(i, v, pan=0.0):
    if 0 <= i < N: L[i] += v*(1-max(pan,0)); Rr[i] += v*(1+min(pan,0))
def seg(t,a,b): return min(1,max(0,(t-a)/(b-a)))
CUTS=[3.2,7.4,11.2,14.6]
# 1) 0-3.2：呼吸般的噪声 + 冲进瞳孔的上升滑音
y=0.0; ph=0.0
for i in range(int(3.25*SR)):
    t=i/SR; y+= (0.004+0.3*seg(t,1.,3.2)**3)*(rnd.uniform(-1,1)-y)
    env=0.15+0.85*seg(t,0.9,3.2)**2
    ph+=TAU*(80+900*seg(t,1.2,3.2)**3)/SR
    put(i,(y*1.6+math.sin(ph)*0.05*seg(t,1.2,3.1))*env*(1-seg(t,3.18,3.22)), math.sin(t*2)*0.3)
# 2) 弦乐铺底（大量失谐锯齿近似 → 用多个正弦泛音叠加），3.2 起逐渐变强，14.6 断开
chord=[55.0,110.0,164.81,220.0,261.63,329.63,392.0,493.88]
for k,f in enumerate(chord):
    for d in (-1,1):
        det=1+d*0.0025*(k%3+1); phs=[0.0]*4
        for i in range(int(3.2*SR),int(14.62*SR)):
            t=i/SR
            env=seg(t,3.2,5.0)*(0.3+0.7*seg(t,5,14.3)**1.5)*(1-seg(t,14.55,14.62))
            if k>=5: env*=seg(t,7.4,9.5)
            v=0.0
            for h in range(4):
                phs[h]+=TAU*f*det*(h+1)/SR; v+=math.sin(phs[h])/(h+1)**1.6
            put(i,v*env*0.022*(1+0.15*math.sin(TAU*0.3*t+k)),d*0.35*(k%2*2-1))
# 3) 低频打击：每个转场一记，外加越来越密的心跳式低鼓
def boom(t0,amp,dec=4.):
    s0=int(t0*SR)
    for j in range(int(1.6*SR)):
        tt=j/SR; f=30+45*math.exp(-tt*9)
        put(s0+j,(math.sin(TAU*f*tt)*math.exp(-tt*dec)+rnd.uniform(-1,1)*math.exp(-tt*30)*0.3)*amp)
for c in CUTS: boom(c,1.0 if c<14 else 1.2,3.)
t=4.0
while t<14.4:
    iv=0.9+(0.28-0.9)*seg(t,4,14.4); boom(t,0.35+0.25*seg(t,4,14.4),9.); t+=iv
# 4) 转场前的反向吸气（reverse swell）
for c in CUTS[1:]:
    s0=int((c-1.0)*SR); yy=0.0
    for j in range(int(1.0*SR)):
        tt=j/SR; yy+=0.05*(rnd.uniform(-1,1)-yy); put(s0+j,yy*(tt/1.0)**3*1.4)
# 5) 高音闪光（铃）
for n,c in enumerate(CUTS):
    bf=[1318.5,1568.0,1760.0,2093.0][n]
    for j in range(int(2.0*SR)):
        tt=j/SR; put(int(c*SR)+j,math.sin(TAU*bf*tt)*math.exp(-tt*2.2)*0.05+math.sin(TAU*bf*1.5*tt)*math.exp(-tt*3)*0.025,0.5 if n%2 else -0.5)
# 6) 14.6-17.3：星系尺度的低鸣 + “人声”般的空灵和声
ph=[0.0]*3; yy=0.0
for i in range(int(14.6*SR),int(17.4*SR)):
    t=i/SR; env=seg(t,14.6,15.2)*(1-seg(t,16.9,17.35))
    f=48*(0.75**seg(t,14.6,17.3))
    for k,m in enumerate((1,2,3.01)): ph[k]+=TAU*f*m/SR
    v=(math.sin(ph[0])*0.6+math.sin(ph[1])*0.25+math.sin(ph[2])*0.1)
    choir=sum(math.sin(TAU*ff*t+q)*0.2 for q,ff in enumerate((440,554.37,659.25)))*(0.6+0.4*math.sin(TAU*5*t))*0.12
    yy+=0.015*(rnd.uniform(-1,1)-yy)
    put(i,(v*0.45+choir+yy*1.2)*env,math.sin(t)*0.3)
# 7) 心跳：星系睁眼 / 回到人眼
def heart(t0,amp):
    for d,a in ((0,1.0),(0.19,0.6)):
        s0=int((t0+d)*SR)
        for j in range(int(0.4*SR)):
            tt=j/SR; f=45+35*math.exp(-tt*28); put(s0+j,math.sin(TAU*f*tt)*math.exp(-tt*13)*amp*a)
heart(17.25,1.2); heart(18.3,0.7); heart(19.35,0.3)
# 8) 首尾相接的微弱高音
for i in range(N):
    t=i/SR; env=max(seg(t,17.6,18.6),1-seg(t,0,1.2))
    if env>0: put(i,(math.sin(TAU*1760*t)+0.5*math.sin(TAU*2637*t+1))*env*0.01,0.3*math.sin(TAU*t/5))
pk=max(max(abs(x) for x in L),max(abs(x) for x in Rr)); g=0.89/pk
os.makedirs('../out',exist_ok=True)
with wave.open('../out/recursion_v2_audio.wav','wb') as wf:
    wf.setnchannels(2);wf.setsampwidth(2);wf.setframerate(SR)
    wf.writeframes(b''.join(struct.pack('<hh',int(L[i]*g*32767),int(Rr[i]*g*32767)) for i in range(N)))
print('ok gain',round(g,3))

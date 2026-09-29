"""《递归》声音设计：纯 Python 合成，无外部依赖。输出 out/recursion_audio.wav（20s, 44.1kHz, 立体声）
结构：0-1.3 吸入 → 1.3-9.6 加速的城市脉冲 → 9.6-16.4 宇宙尺度的低频嗡鸣 → 心跳 → 近乎寂静（首尾可循环）"""
import math, random, struct, wave, os

SR, DUR = 44100, 20.0
N = int(SR * DUR)
L = [0.0] * N
Rch = [0.0] * N
rnd = random.Random(7)
TAU = 2 * math.pi
CUTS = [1.3, 3.2, 5.1, 6.8, 8.3, 9.6]

def put(i, v, pan=0.0):
    if 0 <= i < N:
        L[i] += v * (1 - max(pan, 0))
        Rch[i] += v * (1 + min(pan, 0))

def seg(t, a, b): return min(1, max(0, (t - a) / (b - a)))

# 1) 开头吸入：低通噪声，截止频率上升
y = 0.0
for i in range(int(1.3 * SR)):
    t = i / SR
    a = 0.02 + 0.3 * seg(t, 0.2, 1.3) ** 2
    y += (0.01 + 0.25 * seg(t, 0, 1.3) ** 2) * (rnd.uniform(-1, 1) - y)
    put(i, y * a * 2.2, math.sin(t * 3) * 0.3)

# 2) 和声铺底（A 小调加九），渐强，在 9.6 秒突然切断
notes = [110.0, 164.81, 220.0, 261.63, 329.63, 493.88]
for k, f in enumerate(notes):
    det = 1 + (k % 2 * 2 - 1) * 0.002
    for i in range(int(1.3 * SR), int(9.6 * SR)):
        t = i / SR
        env = seg(t, 1.3, 2.3) * (0.35 + 0.65 * seg(t, 2, 9.4)) * (1 - seg(t, 9.52, 9.6))
        trem = 0.8 + 0.2 * math.sin(TAU * (2 + t * 0.8) * t)
        v = (math.sin(TAU * f * t) + 0.3 * math.sin(TAU * f * 2 * det * t)) * env * trem * 0.045
        put(i, v, (k / len(notes) - 0.5) * 0.8)

# 3) 加速的“滴答”节拍（城市的脉搏）
t = 1.3; side = 1
while t < 9.6:
    iv = 0.32 + (0.065 - 0.32) * ((t - 1.3) / 8.3)
    s0 = int(t * SR)
    for j in range(int(0.012 * SR)):
        e = math.exp(-j / (0.002 * SR))
        put(s0 + j, (math.sin(TAU * 3200 * j / SR) * 0.6 + rnd.uniform(-1, 1) * 0.4) * e * 0.22, 0.5 * side)
    side = -side; t += iv

# 4) 转场重击 + 高音铃声
bells = [880, 1046.5, 1318.5, 1568, 1760, 1318.5]
for n, c in enumerate(CUTS + [11.4, 13.3]):
    s0 = int(c * SR); amp = 0.75 if c <= 9.6 else 0.5
    for j in range(int(0.9 * SR)):
        tt = j / SR
        f = 35 + 25 * math.exp(-tt * 8)
        v = math.sin(TAU * f * tt) * math.exp(-tt * 5) * amp
        v += rnd.uniform(-1, 1) * math.exp(-tt * 40) * 0.25 * amp
        put(s0 + j, v)
    if c <= 9.6:
        bf = bells[n % len(bells)]
        for j in range(int(1.4 * SR)):
            tt = j / SR; e = math.exp(-tt * 3)
            v = (math.sin(TAU * bf * tt) + 0.4 * math.sin(TAU * bf * 2.76 * tt) * math.exp(-tt * 6)) * e * 0.07
            put(s0 + j, v, 0.6 if n % 2 else -0.6)

# 5) 宇宙尺度：下沉的低频嗡鸣 + 风声（9.6-16.4）
ph = [0.0, 0.0, 0.0]; y = 0.0
for i in range(int(9.6 * SR), int(16.45 * SR)):
    t = i / SR
    f = 70 * (36 / 70) ** seg(t, 9.6, 16.3)
    env = seg(t, 9.6, 10.3) * (1 - seg(t, 15.9, 16.4))
    for k, m in enumerate([1, 2, 3.01]):
        ph[k] += TAU * f * m / SR
    v = (math.sin(ph[0]) * 0.5 + math.sin(ph[1]) * 0.25 + math.sin(ph[2]) * 0.12) * env * 0.5
    y += 0.02 * (rnd.uniform(-1, 1) - y)
    w = y * env * (0.8 + 0.6 * math.sin(t * 1.7)) * 1.4
    put(i, v + w, math.sin(t * 0.9) * 0.4)

# 6) 心跳：宇宙之眼闭合时、睁开后、结尾
def heart(t0, amp):
    for d, a in [(0, 1.0), (0.2, 0.65)]:
        s0 = int((t0 + d) * SR)
        for j in range(int(0.35 * SR)):
            tt = j / SR
            f = 48 + 30 * math.exp(-tt * 30)
            put(s0 + j, math.sin(TAU * f * tt) * math.exp(-tt * 14) * amp * a)
heart(16.45, 1.1); heart(17.55, 0.8); heart(19.0, 0.35)

# 7) 首尾衔接的微弱高音（结尾渐入，开头渐出 → 循环无缝）
for i in range(N):
    t = i / SR
    env = max(seg(t, 17.4, 18.2) * 1.0, 1 - seg(t, 0, 1.0))
    if env > 0:
        v = (math.sin(TAU * 1760 * t) + 0.6 * math.sin(TAU * 2637 * t + 1)) * env * 0.012 * (0.7 + 0.3 * math.sin(TAU * t / 2))
        put(i, v, 0.3 * math.sin(TAU * t / 5))

peak = max(max(abs(x) for x in L), max(abs(x) for x in Rch))
g = 0.89 / peak
os.makedirs('out', exist_ok=True)
with wave.open('out/recursion_audio.wav', 'wb') as wf:
    wf.setnchannels(2); wf.setsampwidth(2); wf.setframerate(SR)
    wf.writeframes(b''.join(struct.pack('<hh', int(L[i] * g * 32767), int(Rch[i] * g * 32767)) for i in range(N)))
print('wrote out/recursion_audio.wav, peak gain', round(g, 3))

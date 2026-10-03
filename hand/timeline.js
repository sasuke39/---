// 样片时间线：第 1 镜（0–3s）→ 第 14 镜 AI 去噪（放慢展示，3–5s）→ 第 16 镜六指结尾（5–10s）
const DUR=10;const cl=(x,a=0,b=1)=>Math.min(b,Math.max(a,x));const sm=t=>{t=cl(t);return t*t*(3-2*t)};const seg=(t,a,b)=>cl((t-a)/(b-a));
const AI_STEPS=20;
const SHOTS=[
  {name:'cave',t0:0,t1:3,params:(T,lt)=>({A:sm(seg(lt,.35,1.5)),B:sm(seg(lt,1.75,2.55)),C:0,D:1-seg(lt,1.5,3),expo:1.0})},
  {name:'ai',t0:3,t1:5,params:(T,lt)=>({A:seg(lt,0,1.75),B:lt>1.84?1:0,C:AI_STEPS,expo:1.0})},
  {name:'cave',t0:5,t1:10,params:(T,lt)=>({A:sm(seg(lt,.6,1.7)),B:sm(seg(lt,1.95,2.75)),C:1,D:1-seg(lt,1.7,4),expo:1.0})},
];
function flashAt(T){return 0}
const SERIF='"Noto Serif SC","WenQuanYi Zen Hei",serif',MONO='"IBM Plex Mono","DejaVu Sans Mono",monospace';
function txt(c,s,x,y,font,alpha,sp,color,align='center'){if(alpha<=0)return;c.save();c.globalAlpha=alpha;c.font=font;c.textAlign=align;
  c.letterSpacing=sp+'px';c.shadowColor='rgba(0,0,0,.7)';c.shadowBlur=24;c.fillStyle=color;c.fillText(s,x,y);c.restore()}
// 年份计数器：小号前缀 + 大号等宽数字
function counter(c,pre,num,a){txt(c,pre,540,250,`600 30px ${SERIF}`,a*.75,12,'#efe6d8');txt(c,num,540,370,`600 120px ${MONO}`,a,2,'#f6efe4')}
function overlay(c,T){
  if(T<3){const a=sm(seg(T,.1,.5));counter(c,'公元前','40,000',a)}
  else if(T<5){const lt=T-3,st=Math.min(AI_STEPS,Math.floor(seg(lt,0,1.75)*AI_STEPS));counter(c,'公元','2026',1);
    txt(c,`denoising · step ${String(st).padStart(2,'0')}/${AI_STEPS}`,540,430,`500 26px ${MONO}`,.7,3,'#cfd8ff')}
  else{const lt=T-5;counter(c,'','?',sm(seg(lt,.1,.6))*(1-sm(seg(lt,4.5,4.95))));
    const a=sm(seg(lt,2.6,3.1))*(1-sm(seg(lt,4.5,4.95)));txt(c,'下一只手印，会是谁的？',540,520,`700 52px ${SERIF}`,a,6,'#f6f1e8')}
}

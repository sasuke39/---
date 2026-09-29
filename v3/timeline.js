// v3 时间线：一个连续的对数拉远镜头。
// KEYS = [时间(秒), log10(米 / 屏幕单位)]；屏幕单位 = 半个屏幕高度。
const DUR=20;
const cl=(x,a=0,b=1)=>Math.min(b,Math.max(a,x));
const sm=t=>{t=cl(t);return t*t*(3-2*t)};
const seg=(t,a,b)=>cl((t-a)/(b-a));
const KEYS=[[0,-1.92],[1.0,-1.87],[2.0,-1.2],[3.0,-.4],[4.0,.55],[5.0,1.45],[6.2,2.55],[7.2,3.55],[8.0,4.9],
  [8.8,6.3],[9.6,7.05],[10.4,7.6],[10.9,7.985],[11.6,8.12],[12.4,9.55],[13.3,10.4],[14.2,14.],[15.2,18.4],[16.2,20.8],[17.4,20.86],[20,20.86]];
// 单调三次 Hermite 插值（Fritsch–Carlson）：速度连续、不会回退
const TAN=(()=>{const n=KEYS.length,d=[],m=new Array(n).fill(0);
  for(let i=0;i<n-1;i++)d.push((KEYS[i+1][1]-KEYS[i][1])/(KEYS[i+1][0]-KEYS[i][0]));
  m[0]=d[0];m[n-1]=d[n-2];
  for(let i=1;i<n-1;i++){if(d[i-1]*d[i]<=0){m[i]=0;continue}const h0=KEYS[i][0]-KEYS[i-1][0],h1=KEYS[i+1][0]-KEYS[i][0];
    const w1=2*h1+h0,w2=h1+2*h0;m[i]=(w1+w2)/(w1/d[i-1]+w2/d[i])}
  return m})();
function logScaleAt(T){let i=0;while(i<KEYS.length-2&&T>KEYS[i+1][0])i++;
  const [t0,y0]=KEYS[i],[t1,y1]=KEYS[i+1],h=t1-t0,s=cl((T-t0)/h);
  const h00=2*s*s*s-3*s*s+1,h10=s*s*s-2*s*s+s,h01=-2*s*s*s+3*s*s,h11=s*s*s-s*s;
  return h00*y0+h10*h*TAN[i]+h01*y1+h11*h*TAN[i+1]}
function scaleAt(T){return Math.pow(10,logScaleAt(T))}
const S0=Math.pow(10,KEYS[0][1]);

// 结尾：星系 → 眼睛的径向溶解（第二路画面用 S0 渲染）
function morphAt(T){return{m:sm(seg(T,16.4,18.2)),S2:S0}}
function expoAt(T){return 1.1}

// 各尺度图层（按作用范围 E 从小到大）。E = 该图层负责建模的半径（米）。
const LAYERS=[
  {name:'face',E:.25,params:(T,S)=>{
    const slide=seg(T,1.0,1.9),reform=sm(seg(T,19.0,19.95));
    return{A:T<1.9?1:reform,B:T<1.9?Math.pow(slide,1.6)*2.2:0,C:.9*sm(seg(T,16.4,17.6))*(1-sm(seg(T,17.8,19.5))),D:0}}},
  {name:'roof',E:30,params:(T,S)=>({})},
  {name:'city',E:9000,fade:S=>1-sm(seg(Math.log10(S),3.9,4.5)),params:(T,S)=>({})},
  {name:'earth',E:3e9,fade:S=>1-sm(seg(Math.log10(S),8.9,9.4)),params:(T,S)=>({B:.05+.95*seg(T,10.4,11.5)})},
  {name:'solar',E:2e12,fade:S=>1-sm(seg(Math.log10(S),11.4,12.1)),params:(T,S)=>({})},
  {name:'galaxy',E:1e30,params:(T,S)=>({B:sm(seg(T,15.4,16.6))})},
];

// 字幕：只有结尾一行
const SERIF='"Noto Serif SC","WenQuanYi Zen Hei",serif';
function txt(c,s,x,y,size,weight,alpha,sp,color){if(alpha<=0)return;c.save();c.globalAlpha=alpha;c.font=`${weight} ${size}px ${SERIF}`;c.textAlign='center';
  c.letterSpacing=sp+'px';c.shadowColor='rgba(0,0,0,.85)';c.shadowBlur=30;c.fillStyle=color;c.fillText(s,x,y);c.restore()}
function overlay(c,T,S){
  const a=sm(seg(T,18.3,18.8))*(1-sm(seg(T,19.45,19.85)));
  txt(c,'是我们创造了它，还是它梦见了我们？',540,300,46,700,a,4,'#f6f1e8');
  txt(c,'DID WE BUILD IT — OR DID IT DREAM US?',540,352,18,500,a*.7,6,'#d8e6ea');
}

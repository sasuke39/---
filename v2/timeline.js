// 时间线：每个镜头 {name, t0, t1, xout(与下一个镜头的交叠秒数), params(T,lt,p)}
const DUR=20;
const cl=(x,a=0,b=1)=>Math.min(b,Math.max(a,x));
const sm=t=>{t=cl(t);return t*t*(3-2*t)};
const eIn=t=>{t=cl(t);return t*t*t};
const eIO=t=>{t=cl(t);return t<.5?4*t*t*t:1-Math.pow(-2*t+2,3)/2};
const seg=(t,a,b)=>cl((t-a)/(b-a));
const SHOTS=[
  {name:'eye',t0:0,t1:3.2,xout:0,params:(T,lt,p)=>({A:1+Math.exp(eIn(seg(lt,.9,3.2))*Math.log(40))-1+.04*seg(lt,0,.9),B:seg(lt,1.6,3.),C:0,D:.08*seg(lt,.2,1.2),expo:1.15})},
  {name:'city',t0:3.2,t1:7.4,xout:.4,params:(T,lt,p)=>({A:eIO(p)*.9+.05,B:.15+.85*seg(lt,0,3.6),C:sm(seg(lt,0,.5)),expo:.85})},
  {name:'orbit',t0:7.4,t1:11.2,xout:.4,params:(T,lt,p)=>({A:eIO(p),B:seg(lt,.3,3.4),C:1,expo:1.0})},
  {name:'dyson',t0:11.2,t1:14.6,xout:.4,params:(T,lt,p)=>({A:eIO(p),B:.1+.9*seg(lt,0,2.8),C:1,expo:.9})},
  {name:'galaxy',t0:14.6,t1:17.8,xout:.45,params:(T,lt,p)=>({A:eIO(p),B:sm(seg(lt,2.2,3.1)),C:1,expo:1.0})},
  {name:'eye',t0:17.8,t1:20,xout:0,params:(T,lt,p)=>({A:1,B:0,C:.9*(1-sm(seg(lt,.2,1.9))),D:0,expo:1.15})},
];
function flashAt(T){return 0}
// 字幕：每个镜头一行中英标题；结尾两行问句
const SERIF='"Noto Serif SC","WenQuanYi Zen Hei",serif';
const TITLES=[
  {t0:3.6,t1:7.0,zh:'城市，在自己生长',en:'THE CITY GROWS ITSELF'},
  {t0:7.9,t1:10.9,zh:'月球，成了一台计算机',en:'THE MOON BECOMES A COMPUTER'},
  {t0:11.7,t1:14.3,zh:'太阳，被完全包裹',en:'THE SUN, ENCLOSED'},
  {t0:15.3,t1:17.4,zh:'整个星系，成了一颗大脑',en:'THE GALAXY BECOMES A MIND'},
];
function txt(c,s,x,y,size,weight,alpha,sp,color){if(alpha<=0)return;c.save();c.globalAlpha=alpha;c.font=`${weight} ${size}px ${SERIF}`;c.textAlign='center';
  c.letterSpacing=sp+'px';c.shadowColor='rgba(0,0,0,.85)';c.shadowBlur=30;c.fillStyle=color;c.fillText(s,x,y);c.restore()}
function overlay(c,T){
  for(const t of TITLES){const a=sm(seg(T,t.t0,t.t0+.5))*(1-sm(seg(T,t.t1-.5,t.t1)));if(a<=0)continue;const dy=(1-a)*10;
    txt(c,t.zh,540,330+dy,50,600,a*.95,10,'#f4efe6');txt(c,t.en,540,388+dy,19,500,a*.7,7,'#d8e6ea')}
  const out=1-sm(seg(T,19.5,19.9));
  txt(c,'是我们创造了它，',540,330,60,700,sm(seg(T,18.0,18.45))*out,10,'#f6f1e8');
  txt(c,'还是它梦见了我们？',540,425,60,700,sm(seg(T,18.5,18.95))*out,10,'#f6f1e8');
  txt(c,'DID WE BUILD IT — OR DID IT DREAM US?',540,485,20,500,sm(seg(T,18.9,19.2))*out*.75,7,'#d8e6ea');
}

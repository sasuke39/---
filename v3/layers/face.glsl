// ===== 图层 A：仰面躺着的人的脸（俯视），单位：米。锚点 = 右眼瞳孔中心 =====
// uA = 泪滴大小 0..1；uB = 泪滴下滑距离（眼单位）；uC = 虹膜 AI 电路发光；uD = 瞳孔深处灯光
uniform float uA,uB,uC,uD;
const float EU=.01;                  // 1 眼单位 = 1cm
const float RI=.60;                  // 虹膜半径（眼单位）= 6mm
const vec2 EYE2=vec2(-.063,0.);      // 另一只眼（米）
const vec2 FC=vec2(-.0315,-.02);     // 脸中心（米）
vec3 LS=normalize(vec3(.62,.16,.56)); // 太阳方向（x 东=屏幕右, y 朝向镜头, z 北=屏幕上）

float g2(vec2 p,vec2 c,vec2 s){vec2 d=(p-c)/s;return exp(-dot(d,d));}
float faceH(vec2 p){
  vec2 d=(p-FC)/vec2(.074,.108);float h=sqrt(max(0.,1.-dot(d,d)))*.045;
  h-=.011*g2(p,vec2(0.,.004),vec2(.02,.016));h-=.011*g2(p,EYE2+vec2(0,.004),vec2(.02,.016));   // 眼窝
  h+=.007*g2(p,vec2(.0,.024),vec2(.026,.008));h+=.007*g2(p,EYE2+vec2(0,.024),vec2(.026,.008)); // 眉骨
  h+=.004*g2(p,vec2(-.0315,.02),vec2(.012,.012));
  h+=.016*g2(p,vec2(-.0315,-.022),vec2(.0065,.028))*smoothstep(.01,-.01,p.y+.0);             // 鼻梁
  h+=.009*g2(p,vec2(-.0315,-.047),vec2(.012,.009));                                           // 鼻头
  h+=.004*g2(p,vec2(-.02,-.05),vec2(.006,.006));h+=.004*g2(p,vec2(-.043,-.05),vec2(.006,.006)); // 鼻翼
  h-=.004*g2(p,vec2(-.024,-.056),vec2(.004,.0025));h-=.004*g2(p,vec2(-.039,-.056),vec2(.004,.0025));
  h+=.007*g2(p,vec2(.016,-.028),vec2(.016,.014));h+=.007*g2(p,vec2(-.079,-.028),vec2(.016,.014)); // 颧骨
  h-=.004*g2(p,vec2(.005,-.06),vec2(.012,.02));h-=.004*g2(p,vec2(-.068,-.06),vec2(.012,.02));   // 面颊凹陷
  h-=.0015*g2(p,vec2(-.0315,-.064),vec2(.004,.005));                                          // 人中
  float ux=(p.x+.0315)/.022;float upY=-.071+.0025*exp(-pow((abs(ux)-.25)/.18,2.));
  h+=.0035*exp(-pow(ux,6.))*exp(-pow((p.y-upY)/.0035,2.));                                     // 上唇（唇峰）
  h+=.0045*exp(-pow(ux*.95,6.))*exp(-pow((p.y+.082)/.0052,2.));                               // 下唇
  h-=.0025*exp(-pow(ux*.9,8.))*exp(-pow((p.y+.0765)/.0012,2.));                               // 唇缝
  h+=.006*g2(p,vec2(-.0315,-.107),vec2(.018,.011));                                           // 下巴
  return h;}
float faceShadow(vec2 p,float h){vec2 sd=normalize(vec2(LS.x,LS.z));float te=LS.y/length(LS.xz);float sh=1.;
  for(int i=1;i<=18;i++){float t=float(i)*.0045;float hh=faceH(p+sd*t);float rh=h+t*te;sh=min(sh,sat((rh-hh)*350.+.5));}
  return sh;}
float irisH(vec2 q,out float crypt,out float rn,out float coll){
  float r=length(q)/RI;vec2 dir=q/max(length(q),1e-4);float a=atan(q.y,q.x);
  float tw=.18*(fbm3(vec3(dir*2.,r*2.))-.5);
  vec2 d2=rot(tw+.06*(noise(vec3(dir*10.,r*4.))-.5))*dir;
  float t1=noise(vec3(d2*26.,r*1.6));float clump=noise(vec3(dir*7.,r*9.));
  float fib=t1*t1*.75+noise(vec3(d2*90.,r*3.5))*.25+noise(vec3(d2*260.,r*8.))*.12+clump*.3;
  float rc=.46+.035*(noise(vec3(dir*5.,1.))-.5)+.02*sin(a*14.);
  coll=exp(-pow((r-rc)/.035,2.));
  crypt=smoothstep(.56,.74,fbm3(vec3(dir*5.5,r*4.5+3.)))*smoothstep(.3,.45,r)*smoothstep(.95,.7,r);
  float fur=smoothstep(.68,.95,r)*(.5+.5*sin(r*70.+noise(vec3(dir*6.,0.))*6.))*.35;
  rn=r;return fib*.55+coll*.5-crypt*.7+fur*.25;}

vec3 skyRefl(vec2 s){ // 眼角膜/泪滴里倒映的黄昏天空：天顶深蓝，靠太阳一侧的地平线橙金
  float r=length(s);vec2 sd=normalize(vec2(LS.x,LS.z));float toward=dot(normalize(s+1e-4),sd);
  vec3 c=mix(vec3(.02,.04,.1),vec3(.25,.3,.45),smoothstep(.2,1.,r));
  c=mix(c,vec3(1.,.5,.2)*1.4,smoothstep(.55,1.,r)*smoothstep(.2,1.,toward));
  // 远处塔楼的剪影沿着天空边缘
  float ang=atan(s.y,s.x);float tw=smoothstep(.8,.95,r+.08*noise(vec3(ang*6.,0.,0.)));
  c=mix(c,vec3(.01,.01,.015),tw*.5);
  return c;}

// 一只眼睛（眼单位坐标 q），返回颜色，w = 在眼睑内的程度
vec3 eyeShade(vec2 q,float anchor,out float inLid){
  vec3 L=normalize(vec3(LS.x,LS.z,LS.y*2.+.3));
  float xs=q.x/1.42;float cap=max(0.,1.-xs*xs);
  float lidTop=.46*pow(cap,.75)+.03*q.x, lidBot=-.50*pow(cap,.65);
  inLid=smoothstep(0.,.012,lidTop-q.y)*smoothstep(0.,.012,q.y-lidBot)*step(abs(xs),1.);
  float lidDist=min(lidTop-q.y,q.y-lidBot);
  float rq=length(q)/RI;vec3 col=vec3(0);
  float rp=.29;
  if(rq<1.08){
    float cr,rn,co;float h=irisH(q,cr,rn,co);float e=.0015;float c2,r2,o2;
    float hx=irisH(q+vec2(e,0),c2,r2,o2),hy=irisH(q+vec2(0,e),c2,r2,o2);
    vec3 n=normalize(vec3(-(hx-h)/e*.004,-(hy-h)/e*.004,1.));
    float fibc=sat(h*1.1+.05);
    vec3 inner=mix(vec3(.16,.06,.012),vec3(.72,.38,.1),fibc*fibc);
    vec3 outer=mix(vec3(.012,.05,.07),vec3(.22,.42,.46),pow(fibc,2.2));
    vec3 alb=mix(inner,outer,smoothstep(.40,.56,rn));
    alb=mix(alb,vec3(.55,.33,.12),co*.25);alb*=1.-cr*.75;
    alb*=mix(1.,.25,smoothstep(.82,1.02,rn));alb=mix(alb,vec3(.18,.08,.03),smoothstep(rp+.06,rp,rn));
    float dif=.18+1.1*pow(max(dot(n,L),0.),1.5);
    float kf=smoothstep(1.7,.1,length(q/RI-vec2(.35,.45)));
    vec3 ic=alb*dif*(.6+.4*smoothstep(-.2,.6,h))*(.35+.9*kf);
    if(uC>0.){vec3 v=voronoi(vec3(normalize(q)*9.,rn*6.));float line=smoothstep(.028,.0,v.y)*smoothstep(.3,.5,rn)*smoothstep(.75,.55,rn);
      ic+=vec3(1.,.65,.25)*line*uC*(1.2+2.*(.5+.5*sin(rn*40.-uT*6.)));}
    float pm=smoothstep(rp,rp-.012,rn);
    vec3 pupil=vec3(.002);
    if(anchor>.5&&uD>0.){vec2 ps=q/(rp*RI);float lights=0.;
      for(int i=0;i<3;i++){float s=12.+float(i)*17.;vec2 g=ps*s;vec2 id=floor(g);vec2 f=fract(g)-.5;vec2 o=(hash33(vec3(id,float(i))).xy-.5)*.6;
        lights+=step(.75,hash12(id+float(i)*7.))*smoothstep(.12,.0,length(f-o))*(.4+.6*hash12(id*1.3));}
      pupil+=vec3(1.,.62,.3)*lights*uD;}
    ic=mix(ic,pupil,pm);col=ic;
    vec3 scl=vec3(.5,.48,.46)*(.3+.4*max(dot(normalize(vec3(-q*1.5,1.)),L),0.));
    col=mix(col,scl*.8,smoothstep(.98,1.08,rq));
  }
  if(rq>=1.){vec3 nS=normalize(vec3(-q*1.2,1.));float shade=smoothstep(2.6,.9,rq);
    vec3 scl=vec3(.4,.38,.37)*(.15+.6*max(dot(nS,L),0.))*shade;
    float vein=smoothstep(.82,.95,ridged(vec3(q*9.,1.3)))*smoothstep(1.3,2.,rq);scl=mix(scl,vec3(.55,.08,.06)*shade,vein*.55);
    col=mix(scl,col,smoothstep(1.06,.98,rq));}
  col*=smoothstep(-.01,.16,lidDist)*.85+.15;
  // 角膜反射：天空 + 太阳高光
  vec2 dome=q/RI;float dr=length(dome);
  if(dr<1.15){float fres=.04+.5*pow(sat(dr/1.1),4.);vec2 s=dome*(1.+.55*dr*dr)*.8;
    col+=skyRefl(s)*fres*.9;
    col+=vec3(1.,.93,.8)*9.*smoothstep(.07,.0,length(s-vec2(.52,.5))-.03);
    col+=vec3(1.)*4.*smoothstep(.02,.0,length(s-vec2(-.3,-.36)));}
  // 眼睑缘
  float m=exp(-pow((-lidDist-.012)/.012,2.));col=mix(col,vec3(.22,.07,.06)*.6,m*.9*step(lidDist,0.));
  return col;}

vec3 lashes(vec2 q,vec3 col){
  float xs=q.x/1.42;float cap=max(0.,1.-xs*xs);float lidTop=.46*pow(cap,.75)+.03*q.x,lidBot=-.50*pow(cap,.65);
  float x=q.x;float lash=0.;float yy=q.y-lidTop;
  if(yy>-.01&&yy<.3&&abs(xs)<1.){
    for(int i=0;i<3;i++){float fi=float(i);float dens=24.+fi*9.;float k0=x*dens+fi*.37;float id=floor(k0);
      float h1=hash11(id*1.7+fi*13.),h2=hash11(id*3.1+fi*5.);float len=(.08+.16*h1)*smoothstep(1.,.3,abs(xs));
      float t=sat(yy/max(len,1e-3));float bend=t*t*len*(.8+.9*h2)*(x>0.?1.:-1.)*(.4+abs(x)*.6);
      float kk=(x-bend)*dens+fi*.37;float f=fract(kk)-.5;float w=.22*pow(1.-t,.6)+.02;
      lash=max(lash,smoothstep(w,w*.35,abs(f))*step(yy,len)*step(-.005,yy)*(.75+.25*h2));}}
  float y2=lidBot-q.y;
  if(y2>-.005&&y2<.08&&abs(xs)<1.){float dens=22.;float id=floor(x*dens);float len=(.02+.05*hash11(id*2.3))*smoothstep(1.,.3,abs(xs));
    float t=sat(y2/max(len,1e-3));float f=fract((x-t*t*len*.6*sign(x))*dens)-.5;float w=.16*(1.-t)+.02;
    lash=max(lash,smoothstep(w,w*.35,abs(f))*step(y2,len)*step(0.,y2)*.8);}
  col=mix(col,vec3(.006,.004,.004),lash);
  col*=1.-.55*smoothstep(.14,0.,lidTop-q.y)*step(0.,lidTop-q.y)*step(abs(xs),1.);
  return col;}

vec3 skin(vec2 p,float px){
  float e=max(px,.0003);float h=faceH(p);
  vec3 n=normalize(vec3(-(faceH(p+vec2(e,0))-h)/e,1.,-(faceH(p+vec2(0,e))-h)/e));
  float d=dot(n,LS);float wrap=sat((d+.08)/1.08);float shd=faceShadow(p,h);
  vec3 alb=vec3(.52,.32,.26);
  float pores=(fbm(vec3(p*900.,2.))-.5)*smoothstep(.0012,.0003,px);
  alb*=1.+pores*.25;alb=mix(alb,vec3(.55,.25,.22),.25*g2(p,vec2(.012,-.035),vec2(.02,.018))+.25*g2(p,vec2(-.075,-.035),vec2(.02,.018)));
  alb=mix(alb,vec3(.45,.15,.14),.6*(g2(p,vec2(-.0315,-.073),vec2(.022,.004))+g2(p,vec2(-.0315,-.084),vec2(.02,.005))));
  vec3 c=alb*(vec3(1.,.6,.34)*2.3*wrap*wrap*shd+vec3(.9,.22,.1)*.5*sat(1.-abs(d)*4.)*step(-.2,d)*shd)+alb*vec3(.1,.14,.26)*.28*n.y;
  float sp=pow(max(dot(reflect(-LS,n),vec3(0,1,0)),0.),30.)*.5*shd;c+=vec3(1.,.8,.6)*sp;
  return c;}

vec3 hairAndGround(vec2 p,float px){
  vec2 hc=vec2(-.0315,.0);vec2 d=p-hc;float r=length(d);float ang=atan(d.y,d.x);
  float edge=.17+.03*noise(vec3(ang*4.,0.,0.))+.02*noise(vec3(ang*13.,1.,0.));
  // 屋顶地面：石板 + 苔藓
  vec3 v=voronoi(vec3(p*3.,0.));vec3 g=mix(vec3(.12,.11,.1),vec3(.2,.19,.17),v.z)*(.7+.3*fbm3(vec3(p*20.,1.)));
  g*=1.-.6*smoothstep(.03,.0,v.y);
  g=mix(g,vec3(.05,.09,.03),smoothstep(.55,.75,fbm3(vec3(p*6.,4.))));
  vec3 gc=g*(vec3(1.,.6,.35)*.9*.28+vec3(.1,.13,.22)*.25);
  // 头部投下的长影（朝向太阳的反方向）
  vec2 sd=normalize(vec2(LS.x,LS.z));float along=dot(d,-sd);float across=abs(d.x*sd.y-d.y*sd.x);
  float sh=step(0.,along)*smoothstep(.16,.12,across)*smoothstep(.9,.0,along);gc*=1.-.75*sh*step(edge,r);
  // 头发：从头部向外铺开的发丝
  float wv=ang+.25*sin(r*40.+ang*3.)+.1*noise(vec3(p*60.,0.));float strand=noise(vec3(wv*120.,r*14.,0.))*.6+noise(vec3(wv*330.,r*30.,1.))*.4;
  vec3 hair=vec3(.012,.009,.007)*(.4+strand)+vec3(1.,.6,.35)*.12*pow(strand,8.)*max(dot(normalize(d),sd),0.);
  float inHair=smoothstep(edge,edge-.012,r);
  return mix(gc,hair,inHair);}

void main(){
  vec2 uv=suv();vec2 p=uv*uS;float px=uS/960.;
  vec2 dFace=(p-FC)/vec2(.078,.11);float fr=length(dFace)+.06*(noise(vec3(p*80.,0.))-.5);
  float inFace=smoothstep(1.0,.86,fr)*smoothstep(.062,.045,p.y+.012*noise(vec3(p.x*90.,3.,0.)));
  // 下巴以下：深色外套
  vec3 col=hairAndGround(p,px);
  float coat=smoothstep(.02,.0,max(abs(p.x-FC.x)-.2,p.y+.12))*smoothstep(-.9,-.2,p.y+.12+0.)*step(-.9,p.y);
  col=mix(col,vec3(.02,.022,.03)*(.6+.4*fbm3(vec3(p*60.,2.))),coat*step(p.y,-.1));
  vec3 sk=skin(p,px)*mix(.35,1.,smoothstep(1.,.75,fr));col=mix(col,sk,inFace);
  // 两只眼睛
  for(int k=0;k<2;k++){vec2 c=k==0?vec2(0.):EYE2;vec2 q=(p-c)/EU;if(k==1)q.x=-q.x;
    if(abs(q.x)<1.6&&abs(q.y)<1.){float il;vec3 ec=eyeShade(q,k==0?1.:0.,il);float es=faceShadow(p,faceH(p)+.004);ec*=.25+.75*es;col=mix(col,ec,il);col=lashes(q,col);}}
  // 泪滴：挂在右眼下眼睑外侧，折射放大其下的画面，并倒映天空
  if(uA>0.){
    vec2 q=p/EU;vec2 tc=vec2(.42,-.56-uB);float tr=.17*uA*(1.+.25*sat(uB));
    vec2 dq=(q-tc)/vec2(tr,tr*(1.+.6*sat(uB)));float d=length(dq);
    if(d<1.){vec3 n=normalize(vec3(dq,sqrt(1.-d*d)*.9));
      vec2 qq=tc+dq*tr*.45;float il;vec3 under=eyeShade(qq,1.,il);under=mix(skin(qq*EU,px),under,il);
      vec3 tcol=under*.85+skyRefl(dq*.9)*(.08+.6*pow(d,3.));
      tcol+=vec3(1.,.9,.75)*12.*smoothstep(.2,.0,length(dq-vec2(.38,.42)));
      tcol*=mix(1.,.35,smoothstep(.75,1.,d));
      col=mix(col,tcol,smoothstep(1.,.93,d));}
    // 下滑时留下的湿痕
    if(uB>0.){float trail=smoothstep(.05,.0,abs(q.x-tc.x-.02*sin(q.y*4.)))*step(tc.y,q.y)*step(q.y,-.56);col+=vec3(1.,.8,.6)*trail*.15;}
  }
  fragColor=vec4(col,1.);
}

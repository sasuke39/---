// ===== 镜头：虹膜微距（首尾同一只眼睛）=====
// uA = 变焦倍数（1 = 正常，越大越冲进瞳孔）
// uB = 瞳孔深处城市灯光的亮度
// uC = 虹膜里 AI 电路纹理的发光强度（结尾的暗示）
// uD = 瞳孔缩放
uniform float uA,uB,uC,uD;

const float RI=.60;               // 虹膜半径（屏幕单位）
const vec2 EC=vec2(0.,.0);       // 眼睛中心

float irisH(vec2 q,out float crypt,out float rn,out float coll){
  float r=length(q)/RI; vec2 dir=q/max(length(q),1e-4); float a=atan(q.y,q.x);
  // 纤维方向带一点缓慢的扭曲
  float tw=.18*(fbm3(vec3(dir*2.,r*2.))-.5);
  vec2 d2=rot(tw+.06*(noise(vec3(dir*10.,r*4.))-.5))*dir;
  float t1=noise(vec3(d2*26.,r*1.6));
  float clump=noise(vec3(dir*7.,r*9.));
  float fib=t1*t1*.75+noise(vec3(d2*90.,r*3.5))*.25+noise(vec3(d2*260.,r*8.))*.12+clump*.3;
  float rc=.46+.035*(noise(vec3(dir*5.,1.))-.5)+.02*sin(a*14.);
  coll=exp(-pow((r-rc)/.035,2.));
  crypt=smoothstep(.56,.74,fbm3(vec3(dir*5.5,r*4.5+3.)))*smoothstep(.3,.45,r)*smoothstep(.95,.7,r);
  float fur=smoothstep(.68,.95,r)*(.5+.5*sin(r*70.+noise(vec3(dir*6.,0.))*6.))*.35;
  rn=r;
  return fib*.55+coll*.5-crypt*.7+fur*.25;
}

vec3 cityEnv(vec2 s,float glow){
  // 眼角膜里倒映的未来城市天际线（鱼眼）
  float sky=smoothstep(-.6,.6,s.y);
  vec3 c=mix(vec3(.9,.45,.25),vec3(.05,.08,.18),sky)*.6;
  float bx=floor(s.x*26.);float hgt=-.1+.12*noise2(vec2(s.x*4.,0.))+.1*noise2(vec2(s.x*11.,3.));
  float edge=smoothstep(hgt+.12,hgt-.12,s.y)*.6;c=mix(c,vec3(.01,.012,.02),edge);
  vec2 g=s*vec2(18.,14.);vec2 id=floor(g);vec2 f=fract(g)-.5;float on=step(.7,hash12(id));
  c+=on*edge*vec3(1.,.65,.35)*smoothstep(.35,.0,length(f))*(.3+glow);
  return c;
}

void main(){
  vec2 uv=suv();
  float z=uA;
  vec2 pc=EC+vec2(0.,-.005);
  vec2 p=pc+uv/z; // 以瞳孔为中心缩放（屏幕中心对准瞳孔）
  vec2 q=p-EC;
  float rq=length(q)/RI;

  // 眼睑形状（屏幕坐标）
  float lidTop=.44+.03*q.x-.55*q.x*q.x+.05*noise(vec3(q.x*3.,0.,0.)), lidBot=-.50+.38*q.x*q.x;
  float inLid=smoothstep(0.,.012,lidTop-q.y)*smoothstep(0.,.012,q.y-lidBot);
  float lidDist=min(lidTop-q.y,q.y-lidBot);

  vec3 col=vec3(0);
  vec3 L=normalize(vec3(-.55,.7,.6));
  float rp=.29*(1.+uD);

  // ---- 虹膜 ----
  if(rq<1.08){
    float cr,rn,co;float h=irisH(q,cr,rn,co);
    float e=.0015/max(1.,z*.15);
    float cr2,rn2,co2;
    float hx=irisH(q+vec2(e,0),cr2,rn2,co2),hy=irisH(q+vec2(0,e),cr2,rn2,co2);
    vec3 n=normalize(vec3(-(hx-h)/e*.004,-(hy-h)/e*.004,1.));
    float fibc=sat(h*1.1+.05);
    vec3 inner=mix(vec3(.16,.06,.012),vec3(.72,.38,.1),fibc*fibc);
    vec3 outer=mix(vec3(.012,.05,.07),vec3(.22,.42,.46),pow(fibc,2.2));
    float zone=smoothstep(.40,.56,rn);
    vec3 alb=mix(inner,outer,zone);
    alb=mix(alb,vec3(.55,.33,.12),co*.25);
    alb*=1.-cr*.75;
    alb*=mix(1.,.25,smoothstep(.82,1.02,rn));            // 角膜缘暗环
    alb=mix(alb,vec3(.18,.08,.03),smoothstep(rp+.06,rp,rn)); // 瞳孔边缘
    float dif=.18+1.1*pow(max(dot(n,L),0.),1.5);
    float ao=.6+.4*smoothstep(-.2,.6,h);
    float kf=smoothstep(1.7,.1,length(q/RI-vec2(-.35,.45)));vec3 ic=alb*dif*ao*(.35+.9*kf);
    // AI 电路：虹膜内圈的金色细线
    if(uC>0.){vec3 v=voronoi(vec3(normalize(q)*9.,rn*6.));float line=smoothstep(.028,.0,v.y)*smoothstep(.3,.5,rn)*smoothstep(.75,.55,rn);
      float pulse=.5+.5*sin(rn*40.-uT*6.);ic+=vec3(1.,.65,.25)*line*uC*(1.2+2.*pulse);}
    // 瞳孔
    float pm=smoothstep(rp,rp-.012,rn);
    vec3 pupil=vec3(.002);
    // 瞳孔深处：远方城市的灯光（冲进瞳孔时出现）
    vec2 ps=q/(rp*RI);
    float lights=0.;
    for(int i=0;i<3;i++){float s=12.+float(i)*17.;vec2 g=ps*s;vec2 id=floor(g);vec2 f=fract(g)-.5;
      float hsh=hash12(id+float(i)*7.);vec2 o=(hash33(vec3(id,float(i))).xy-.5)*.6;
      lights+=step(.72,hsh)*smoothstep(.12,.0,length(f-o))*(.4+.6*hash12(id*1.3))*step(ps.y,.25+.2*sin(id.x*.7));}
    pupil+=vec3(1.,.62,.3)*lights*uB*.9+vec3(.05,.2,.35)*uB*.25*smoothstep(1.,.0,length(ps-vec2(0,.5)));
    ic=mix(ic,pupil,pm);
    col=ic;
    // 角膜缘向巩膜过渡
    float lim=smoothstep(.98,1.08,rq);
    vec3 scl=vec3(.5,.48,.46)*(.3+.4*max(dot(normalize(vec3(-q*1.5,1.)),L),0.));
    col=mix(col,scl*.8,lim);
  }
  // ---- 巩膜 ----
  if(rq>=1.0){
    vec3 nS=normalize(vec3(-q*1.2,1.));
    float shade=smoothstep(2.6,.9,rq);
    vec3 scl=vec3(.62,.58,.56)*(.15+.6*max(dot(nS,L),0.))*shade;
    float vein=smoothstep(.82,.95,ridged(vec3(q*9.,1.3)))*smoothstep(1.3,2.,rq);
    scl=mix(scl,vec3(.55,.08,.06)*shade,vein*.55);
    scl*=mix(vec3(1),vec3(1.,.8,.78),smoothstep(1.4,2.4,rq));
    col=mix(scl,col,smoothstep(1.06,.98,rq));
  }
  // 眼睑接触处的阴影 + 泪膜
  col*=smoothstep(-.01,.16,lidDist)*.85+.15;
  col+=vec3(1.,.95,.9)*.12*exp(-pow((q.y-lidBot-.012)/.006,2.))*step(0.,lidDist+.03)*(.6+.4*noise(vec3(q*80.,0.)));

  // ---- 角膜反射（湿润感的关键）----
  vec2 dome=q/RI;float dr=length(dome);
  if(dr<1.15){
    float fres=.04+.5*pow(sat(dr/1.1),4.);
    vec2 s=dome*(1.+.55*dr*dr);
    col+=cityEnv(vec2(s.x,-s.y*1.1+.1),uB)*fres*.45*inLid;
    // 柔光箱高光（主光）
    vec2 hp=s-vec2(-.42,.52);
    float box=smoothstep(.02,0.,max(abs(hp.x)-.16,abs(hp.y)-.09)-.02);
    col+=vec3(1.,.97,.92)*box*7.*inLid;
    // 辅光：一条弧形的轮廓光
    float ring=exp(-pow((dr-.93)/.012,2.))*smoothstep(-.2,.6,dome.x)*smoothstep(-.6,.2,-dome.y);
    col+=vec3(.6,.8,1.)*ring*.25*inLid;
    // 小的点状高光
    col+=vec3(1.)*6.*smoothstep(.022,.0,length(s-vec2(.30,-.36)))*inLid;
  }

  // 眼睑缘：湿润的粉色边
  {float m=exp(-pow((-lidDist-.012)/.012,2.));col=mix(col,vec3(.22,.07,.06)*(.4+.6*smoothstep(1.2,0.,length(q-vec2(-.3,.3)))),m*.9*step(lidDist,.0));
   col+=vec3(1.)*.6*exp(-pow((-lidDist-.004)/.003,2.))*step(0.,q.y)*smoothstep(.5,-.1,q.x);}
  // ---- 皮肤 + 睫毛 ----
  if(inLid<1.){
    float sd=-lidDist;
    vec3 nsk=normalize(vec3(-q.x*.8,(q.y>0.?.6:-.6),1.));
    float pores=fbm(vec3(q*55.,2.))*.6+fbm(vec3(q*180.,5.))*.4;
    vec3 skin=vec3(.26,.13,.10)*(.05+.45*pow(max(dot(nsk,L),0.),1.6)+.14*max(dot(nsk,normalize(vec3(.5,-.6,.6))),0.))*(.6+.6*pores)*smoothstep(1.4,.2,length(q-vec2(-.25,.35)));
    skin*=smoothstep(-.02,.18,sd)*.7+.3;
    skin*=smoothstep(1.3,.4,length(q));
    // 上眼睑的褶皱
    skin*=1.-.5*exp(-pow((q.y-lidTop-.16+.3*q.x*q.x)/.03,2.));
    col=mix(skin,col,inLid);
  }
  // 睫毛：上眼睑 3 排、下眼睑 1 排，粗细从根部到尖端渐细
  {
    float x=q.x;float lash=0.;
    float yy=q.y-lidTop;
    if(yy>-.01&&yy<.26){
      for(int i=0;i<3;i++){float fi=float(i);float dens=24.+fi*9.;
        float k0=x*dens+fi*.37;float id=floor(k0);float h1=hash11(id*1.7+fi*13.),h2=hash11(id*3.1+fi*5.);
        float len=(.06+.15*h1)*smoothstep(.75,.15,abs(x));
        float t=sat(yy/max(len,1e-3));
        float bend=t*t*len*(.8+.9*h2)*(x>0.?1.:-1.)*(.4+abs(x));
        float kk=(x-bend)*dens+fi*.37;float f=fract(kk)-.5;
        float w=.22*pow(1.-t,.6)+.02;
        lash=max(lash,smoothstep(w,w*.35,abs(f))*step(yy,len)*step(-.005,yy)*(.75+.25*h2));}
    }
    float y2=lidBot-q.y;
    if(y2>-.005&&y2<.07){
      float dens=22.;float k0=x*dens;float id=floor(k0);float len=(.02+.045*hash11(id*2.3))*smoothstep(.7,.1,abs(x));
      float t=sat(y2/max(len,1e-3));float kk=(x-t*t*len*.6*sign(x))*dens;float f=fract(kk)-.5;float w=.16*(1.-t)+.02;
      lash=max(lash,smoothstep(w,w*.35,abs(f))*step(y2,len)*step(0.,y2)*.8);}
    col=mix(col,vec3(.006,.004,.004),lash);
    // 上眼睑与睫毛在眼球上的投影
    col*=1.-.55*smoothstep(.14,0.,lidTop-q.y)*step(0.,lidTop-q.y)*(.7+.3*noise(vec3(x*50.,0.,0.)));
  }
  fragColor=vec4(col,1.);
}

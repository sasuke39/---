// ===== 图层 B：塔顶花园上仰躺的人 + 悬停送茶的机器人（3D 光线步进，单位：米）=====
// 世界坐标：x 东(屏幕右)，z 北(屏幕上)，y 向上(朝向镜头)。屋顶平面 y=0，锚点(右眼)在 (0, 0.2, 0)。
uniform float uA,uB,uC,uD;
vec3 LS=normalize(vec3(.62,.16,.56));
const float ROOF=22.;

float sdCap(vec3 p,vec3 a,vec3 b,float r){vec3 pa=p-a,ba=b-a;float h=sat(dot(pa,ba)/dot(ba,ba));return length(pa-ba*h)-r;}
float sdEll(vec3 p,vec3 r){float k0=length(p/r),k1=length(p/(r*r));return k0*(k0-1.)/k1;}
float sdRBox(vec3 p,vec3 b,float r){vec3 q=abs(p)-b;return length(max(q,0.))+min(max(q.x,max(q.y,q.z)),0.)-r;}
float smin(float a,float b,float k){float h=sat(.5+.5*(b-a)/k);return mix(b,a,h)-k*h*(1.-h);}

vec3 DRONE(){return vec3(.62,.75+.03*sin(uT*2.),-.42);}
// 返回距离，mat: 1 皮肤 2 外套 3 头发 4 屋顶 5 机器人 6 发光环 7 杯子 8 树 9 水池
float map(vec3 p,out float mat){
  float d=p.y;mat=4.;
  // 屋顶外缘（下落到雾海）
  float rr=length(p.xz);float edge=rr-ROOF;d=max(d,edge);
  float par=max(abs(rr-ROOF+.25)-.18,abs(p.y-.45)-.45);if(par<d){d=par;mat=4.5;}
  // 人
  vec3 hc=vec3(-.0315,.1,-.02);
  float head=sdEll(p-hc,vec3(.08,.1,.11));
  float hair=sdEll(p-hc-vec3(0,-.07,.03),vec3(.16,.04,.17));
  float neck=sdCap(p,vec3(-.0315,.07,-.1),vec3(-.0315,.07,-.2),.055);
  float chest=sdEll(p-vec3(-.0315,.1,-.36),vec3(.2,.1,.16));
  float belly=sdEll(p-vec3(-.0315,.09,-.58),vec3(.16,.085,.15));
  float hips=sdEll(p-vec3(-.0315,.08,-.78),vec3(.18,.08,.12));
  float shL=sdEll(p-vec3(-.22,.08,-.28),vec3(.08,.07,.09)),shR=sdEll(p-vec3(.16,.08,-.28),vec3(.08,.07,.09));
  // 上臂沿身体两侧，前臂折回交叠在胸前
  float uaL=sdCap(p,vec3(-.24,.08,-.3),vec3(-.25,.08,-.55),.05),uaR=sdCap(p,vec3(.18,.08,-.3),vec3(.19,.08,-.55),.05);
  float faL=sdCap(p,vec3(-.25,.1,-.55),vec3(-.06,.19,-.42),.045),faR=sdCap(p,vec3(.19,.1,-.55),vec3(-.01,.2,-.44),.045);
  float legL=sdCap(p,vec3(-.11,.08,-.82),vec3(-.14,.06,-1.25),.075),legR=sdCap(p,vec3(.05,.08,-.82),vec3(.1,.06,-1.25),.075);
  float shinL=sdCap(p,vec3(-.14,.06,-1.25),vec3(-.16,.05,-1.66),.06),shinR=sdCap(p,vec3(.1,.06,-1.25),vec3(.14,.05,-1.66),.06);
  float shoes=min(sdEll(p-vec3(-.17,.07,-1.72),vec3(.05,.06,.08)),sdEll(p-vec3(.15,.07,-1.72),vec3(.05,.06,.08)));
  float coat=smin(smin(chest,belly,.08),hips,.08);coat=smin(coat,min(shL,shR),.06);
  coat=smin(coat,min(uaL,uaR),.03);coat=min(coat,min(faL,faR));coat=smin(coat,min(min(legL,legR),min(shinL,shinR)),.04);
  coat=smin(coat,neck,.03);coat+=.0015*(noise(p*60.)-.5)+.003*sin(p.z*45.+p.x*12.+noise(p*7.)*5.)*smoothstep(-.3,-.9,p.z);
  float hands=min(sdEll(p-vec3(-.04,.22,-.4),vec3(.045,.03,.06)),sdEll(p-vec3(.0,.225,-.42),vec3(.045,.03,.06)));
  if(shoes<d){d=shoes;mat=2.5;}
  if(coat<d){d=coat;mat=2.;}
  if(hair<d){d=hair;mat=3.;}
  if(head<d){d=head;mat=1.;}
  if(hands<d){d=hands;mat=2.5;}
  // 机器人：扁平的圆盘，下方托着一只杯子
  vec3 q=p-DRONE();
  float body=sdEll(q,vec3(.16,.045,.16));
  float ring=length(vec2(length(q.xz)-.17,q.y))-.012;
  float cup=max(length(q.xz-vec2(0,0))-.035,abs(q.y+.08)-.04);
  if(body<d){d=body;mat=5.;}if(ring<d){d=ring;mat=6.;}if(cup<d){d=cup;mat=7.;}
  // 几棵小树和一个反光水池
  for(int i=0;i<4;i++){float fi=float(i);vec2 tp=vec2(cos(fi*1.7+1.)*(9.+fi*2.5),sin(fi*1.7+1.)*(9.+fi*2.5));
    float tr=length(p-vec3(tp.x,1.4+fi*.2,tp.y))-(1.3+fi*.25)+.25*fbm3(p*1.5);if(tr<d){d=tr;mat=8.;}}
  return d;}
float mapD(vec3 p){float m;return map(p,m);}
vec3 nrm(vec3 p){vec2 e=vec2(.002,0);return normalize(vec3(mapD(p+e.xyy)-mapD(p-e.xyy),mapD(p+e.yxy)-mapD(p-e.yxy),mapD(p+e.yyx)-mapD(p-e.yyx)));}
float shadow(vec3 ro,vec3 rd){float res=1.,t=.01;for(int i=0;i<48;i++){float h=mapD(ro+rd*t);res=min(res,12.*h/t);t+=clamp(h,.01,.8);if(res<.01||t>30.)break;}return sat(res);}

vec3 sky(vec3 rd){float s=max(dot(rd,LS),0.);return mix(vec3(.02,.04,.1),vec3(.9,.45,.2),pow(1.-max(rd.y,0.),4.))+vec3(1.,.6,.3)*pow(s,40.)*4.;}

vec3 fogSea(vec3 ro,vec3 rd){ // 屋顶边缘之外：几百米下方的金色雾海
  float t=(-160.-ro.y)/rd.y;vec3 p=ro+rd*t;float f=fbm(vec3(p.xz*.006,uT*.02));
  return mix(vec3(.5,.24,.1),vec3(.9,.55,.28),f)*.55;}

void main(){
  vec2 uv=suv();float F=4.;
  vec3 ro=vec3(0.,.2+F*uS,0.);vec3 rd=normalize(vec3(uv.x,-F,uv.y));
  float t=0.,m=0.;bool hit=false;
  for(int i=0;i<160;i++){vec3 p=ro+rd*t;float d=map(p,m);if(d<.0004*t+.0005){hit=true;break;}t+=d;if(t>ro.y+200.)break;}
  vec3 col;
  if(!hit||(m==4.&&length((ro+rd*t).xz)>ROOF)){col=fogSea(ro,rd);}
  else{
    vec3 p=ro+rd*t;vec3 n=nrm(p);
    float sh=shadow(p+n*.003,LS);float dif=max(dot(n,LS),0.)*sh;
    float amb=.5+.5*n.y;
    vec3 alb=vec3(.2);float spec=0.;vec3 emi=vec3(0);
    if(m==1.){alb=vec3(.5,.31,.25);}
    else if(m==2.){alb=vec3(.045,.042,.05)*(.7+.6*fbm3(p*90.));spec=.05;}
    else if(m==2.5){alb=vec3(.02);spec=.5;}
    else if(m==3.){alb=vec3(.015,.011,.009)*(.6+.8*noise(vec3(atan(p.z+.02,p.x+.0315)*120.,length(p.xz)*30.,0.)));spec=.2;}
    else if(m==4.||m==4.5){
      vec3 v=voronoi(vec3(p.xz*2.6,0.));alb=mix(vec3(.12,.11,.1),vec3(.2,.185,.165),v.z)*(.7+.4*fbm3(vec3(p.xz*14.,1.)));
      float gap=smoothstep(.06,.0,v.y);alb=mix(alb,vec3(.03,.05,.02),gap*.8);
      float moss=smoothstep(.5,.72,fbm3(vec3(p.xz*.8,4.)));alb=mix(alb,vec3(.04,.08,.03),moss);
      if(m==4.5){alb=vec3(.08,.08,.09);emi=vec3(1.,.7,.4)*1.2*smoothstep(.03,0.,abs(p.y-.88));}
      // 反光水池
      float pool=length(p.xz-vec2(-6.,5.))-2.6;if(pool<0.&&m==4.){vec3 wn=normalize(vec3(noise(vec3(p.xz*6.,uT))-.5,6.,noise(vec3(p.xz*6.+3.,uT))-.5));vec3 r=reflect(rd,wn);alb=vec3(.004);emi=sky(r)*.25*(.3+.7*smoothstep(-.3,-.05,pool))+vec3(1.,.6,.3)*pow(max(dot(r,LS),0.),200.)*20.;}
      // 散落的地灯
      vec2 g=p.xz*.5;vec2 id=floor(g);vec2 f=fract(g)-.5;emi+=vec3(1.,.72,.4)*step(.9,hash12(id))*smoothstep(.06,.0,length(f))*2.*step(m,4.);
    }
    else if(m==5.){alb=vec3(.7,.72,.75);spec=.8;}
    else if(m==6.){alb=vec3(0);emi=vec3(.3,.85,1.)*4.;}
    else if(m==7.){alb=vec3(.85,.83,.8);spec=.4;emi=vec3(.3,.12,.03)*.3;}
    else if(m==8.){alb=vec3(.05,.09,.035)*(.6+.8*fbm3(p*4.));}
    vec3 L=vec3(1.,.6,.34)*2.3;
    col=alb*(L*dif+vec3(.1,.14,.26)*.28*amb);
    if(m==1.)col+=alb*vec3(.9,.22,.1)*.4*sat(1.-abs(dot(n,LS))*4.)*sh;
    vec3 h=normalize(LS-rd);col+=spec*pow(max(dot(n,h),0.),60.)*L*sh;
    if(m==5.)col+=sky(reflect(rd,n))*.35;
    col+=emi;
    // 机器人底部的青色灯光打在人和地面上
    vec3 dl=DRONE()-p;float dd=length(dl);col+=alb*vec3(.3,.85,1.)*.25*max(dot(n,dl/dd),0.)/(1.+dd*dd*6.);
    col=mix(col,fogSea(ro,rd)*.6,sat((t-ro.y)*.002));
  }
  fragColor=vec4(col,1.);
}

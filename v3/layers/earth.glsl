// ===== 图层 D：地球（黄昏线上的锚点）+ 轨道环 + 月球掠过（单位：米）=====
// uB = 月球电路覆盖进度
uniform float uA,uB,uC,uD;
vec3 LS=normalize(vec3(.62,.16,.56));
const float RE=6.371e6;
const vec3 EC=vec3(0.,-6.371e6,0.);
const vec3 MC=vec3(4.2e6,3.84e8,2.9e6);const float MR=1.737e6;

float svoro(vec2 x,float k){vec2 p=floor(x),f=fract(x);float res=0.;
  for(int j=-1;j<=1;j++)for(int i=-1;i<=1;i++){vec2 b=vec2(i,j);vec2 o=vec2(hash12(p+b),hash12(p+b+17.3));res+=exp(-k*length(b+o-f));}return -log(res)/k;}
float gFine=1.;
float fogH(vec2 x){float d1=svoro(x*.0055+uT*.01,7.),d2=svoro(x*.02+3.,7.);
  return 38.*fbm3(vec3(x*.0011,uT*.02))+(32.*smoothstep(.9,.0,d1)+0.*d2)*gFine+1600.*fbm3(vec3(x*.00016,1.7));}
vec3 seaCol(vec2 lp,float px){ // 与城市层同一套云海着色（远看时的平均亮度）
  gFine=smoothstep(10.,3.,px);float e=max(2.,px*2.5);float h=fogH(lp);vec3 n=normalize(vec3(-(fogH(lp+vec2(e,0))-h)/e,1.,-(fogH(lp+vec2(0,e))-h)/e));
  float dif=max(dot(n,LS),0.);float big=fbm3(vec3(lp*.00008,2.));
  vec3 lit=vec3(1.,.5,.2)*1.35*(.3+.7*dif)*.72;vec3 amb=vec3(.12,.12,.2)*.55;
  vec3 c=vec3(.42,.38,.36)*(lit+amb);
  c*=.75+.5*big;
  return c;}
vec3 stars(vec3 rd){vec3 c=vec3(0);for(int i=0;i<3;i++){float s=260.+float(i)*200.;vec3 g=rd*s;vec3 id=floor(g);vec3 f=fract(g)-.5;
  float h=hash13(id+float(i)*17.);if(h>.986){vec3 o=(hash33(id)-.5)*.6;c+=vec3(.8,.85,1.)*smoothstep(.12,0.,length(f-o))*(h-.986)*50.;}}return c;}

// 地表颜色。n=单位法向，lp=锚点附近的局部坐标(米)，px=像素对应米数
vec3 surface(vec3 n,vec2 lp,float px,out float cityGlow){
  float sd=dot(n,LS);
  vec3 P=n*6.;
  float cont=fbm(P*.9+vec3(3.1))+.12*fbm(P*6.);
  float land=smoothstep(.47,.5,cont);
  // 锚点所在的巨型城市盆地：金色云海
  float dA=length(lp);float basin=smoothstep(26000.,14000.,dA+7000.*fbm3(vec3(lp*.00008,1.)));
  land=max(land,basin);
  vec3 day=mix(vec3(.004,.012,.03),mix(vec3(.09,.075,.05),vec3(.04,.06,.03),fbm3(P*14.)),land);
  float lit=smoothstep(-.06,.12,sd);
  vec3 col=day*max(sd,0.)*2.2;
  // 黄昏的金色云海（盆地）
  float cloudSea=basin;
  vec3 sea=seaCol(lp,px)*1.25+vec3(1.,.5,.2)*.12*smoothstep(.4,.8,fbm3(vec3(lp*.0004,7.)));
  col=mix(col,sea*smoothstep(-.1,.1,sd),cloudSea);
  // 城市灯光：网络状，按尺度分层
  float night=smoothstep(.1,-.12,sd);
  float c1=pow(smoothstep(.35,.8,fbm(P*3.)),2.);
  float web=smoothstep(.02,.0,abs(fbm(P*2.2+vec3(7.))-.5))*.7;
  float fine=smoothstep(.5,.85,fbm3(P*150.))*(.5+.5*noise(P*40.));
  cityGlow=land*(c1*fine*3.+web*c1*1.5)*(1.-basin);
  float near=smoothstep(250000.,30000.,dA);
  float rw=max(.004,px*.00003);float roads=smoothstep(rw*1.5,.0,abs(fbm3(vec3(lp*.00003,2.))-.5))*.8+smoothstep(rw,.0,abs(fbm3(vec3(lp*.00011,5.))-.5))*.5;
  float sprawl=smoothstep(.4,.8,fbm3(vec3(lp*.00006,9.)))*smoothstep(.45,.75,fbm3(vec3(lp*.0004,3.)));
  cityGlow+=near*(1.-basin)*(roads*.9+sprawl*1.6)*smoothstep(-.6,.2,-dA/250000.);
  col+=cityGlow*vec3(1.,.6,.26)*mix(.25,1.4,night);
  // 天气云
  float cl=smoothstep(.48,.75,fbm(P*2.4+vec3(uT*.004,0,0)))*smoothstep(150000.,400000.,dA);
  vec3 cc=mix(vec3(1.,.5,.3),vec3(.85,.85,.9),smoothstep(.1,.4,sd))*max(sd+.06,0.)*2.+vec3(.012,.012,.02);col=mix(col,cc,cl*.8);
  return col;}

vec3 moon(vec3 p){
  vec3 n=normalize(p-MC);float h=fbm(n*4.)*.6+fbm(n*16.)*.4;
  vec3 v=voronoi(n*5.);float crater=smoothstep(.35,.15,v.x)*(.6+.4*hash11(v.z*9.));float rim=smoothstep(.12,.0,abs(v.x-.36))*.5;
  vec3 bn=normalize(n+(vec3(noise(n*30.),noise(n*30.+5.),noise(n*30.+9.))-.5)*.25);
  vec3 alb=vec3(.42,.41,.4)*(.55+.45*h)*(1.-crater*.35+rim*.3);
  vec3 col=alb*max(dot(bn,LS),0.)*2.2+alb*.01;
  vec3 seed=normalize(vec3(-.5,-.3,-.8));float ang=acos(clamp(dot(n,seed),-1.,1.));float front=uB*3.3;float act=smoothstep(front,front-.35,ang);
  if(act>0.){float lon=atan(n.z,n.x),lat=asin(n.y);vec2 g=vec2(lon*14.,lat*14.);vec2 id=floor(g),f=fract(g);float hr=hash12(id),hv=hash12(id+3.1);
    float tr=max(smoothstep(.06,.0,abs(f.y-.5))*step(.35,hr)*step(f.x,.5+.5*step(.6,hv)),smoothstep(.06,.0,abs(f.x-.5))*step(hr,.55)*step(.5-.5*step(.4,hv),f.y));
    vec2 g2=g*3.;vec2 i2=floor(g2),f2=fract(g2);tr=max(tr,.6*smoothstep(.08,.0,abs(f2.y-.5))*step(.7,hash12(i2)));tr=max(tr,.6*smoothstep(.08,.0,abs(f2.x-.5))*step(.82,hash12(i2+1.)));
    float pad=smoothstep(.16,.08,length(f-.5))*step(.7,hash12(id+9.));float pulse=.55+.45*sin(ang*30.-uT*8.+hr*6.);
    vec3 ec=mix(vec3(.25,.85,1.),vec3(1.,.7,.3),step(.85,hash12(id+4.)));col=mix(col,col*.25,act*.8);col+=ec*(tr*pulse*2.2+pad*3.)*act;
    col+=vec3(.6,.9,1.)*smoothstep(.1,.0,abs(ang-front+.12))*step(.01,uB)*2.5;}
  return col;}

void main(){
  vec2 uv=suv();float F=4.;
  float h=F*uS;vec3 ro=vec3(0.,h,0.);vec3 rd=normalize(vec3(uv.x,-F,uv.y));
  float px=uS/960.;
  vec3 col=stars(normalize(vec3(uv.x,.6,uv.y)))*smoothstep(1e6,1e7,uS);
  float tmin=1e30;
  // 地球 + 大气
  vec2 he=sphere(ro,rd,EC,RE);vec2 ha=sphere(ro,rd,EC,RE*1.012);
  if(ha.y>0.){
    float t0=max(ha.x,0.),t1=he.x>0.?he.x:ha.y;float len=max(t1-t0,0.)/(RE*.012);
    vec3 pm=ro+rd*(t0+t1)*.5;vec3 nm=normalize(pm-EC);float sd=dot(nm,LS);
    vec3 scat=vec3(.25,.5,1.)*sat(sd+.15)*1.1+vec3(1.,.42,.12)*exp(-pow((sd-.01)/.05,2.))*.8;
    vec3 atm=scat*(1.-exp(-len*.35));
    if(he.x>0.){vec3 p=ro+rd*he.x;vec3 n=normalize(p-EC);float cg;col=surface(n,p.xz,px,cg);tmin=he.x;}
    col=col*exp(-len*.08)+atm*mix(.08,1.,smoothstep(1e5,3e6,uS));
  }
  // 轨道环
  {vec3 nr=normalize(vec3(.35,.88,.3));float tt=dot(EC-ro,nr)/dot(rd,nr);
    if(tt>0.&&tt<tmin){vec3 pr=ro+rd*tt;float r=length(pr-EC);
      if(r>RE*1.1&&r<RE*1.118){vec3 dd=normalize(pr-EC);float a=atan(dd.z,dd.x);
        vec3 rc=vec3(.07,.07,.08)*(.3+max(dot(dd,LS),0.)*1.6);rc+=vec3(.5,.9,1.)*step(.8,fract(a*400.))*step(.5,hash11(floor(a*400.)))*1.3;
        vec2 sh=sphere(pr,LS,EC,RE);if(sh.x>0.)rc*=.25;col=rc;tmin=tt;}}}
  // 月球
  vec2 hm=sphere(ro,rd,MC,MR);
  if(hm.x>0.&&hm.x<tmin){col=moon(ro+rd*hm.x);tmin=hm.x;}
  else if(hm.y>0.&&ro.y<MC.y+MR&&ro.y>MC.y-MR){}
  fragColor=vec4(col,1.);
}

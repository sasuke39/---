// ===== 镜头：近地轨道 —— 夜晚的地球 + 被电路覆盖的月球 =====
// uA = 镜头运动进度；uB = 月球电路覆盖进度；uC = 淡入
uniform float uA,uB,uC,uD;
vec3 SUN=normalize(vec3(.8,-.05,1.));
const vec3 EC=vec3(0.,-6.95,5.5);const float ER=6.4;
const vec3 MC=vec3(1.1,3.9,15.);const float MR=1.9;

vec3 stars(vec3 rd){vec3 c=vec3(0);for(int i=0;i<3;i++){float s=200.+float(i)*180.;vec3 g=rd*s;vec3 id=floor(g);vec3 f=fract(g)-.5;
  float h=hash13(id+float(i)*17.);if(h>.985){vec3 o=(hash33(id)-.5)*.6;float d=length(f-o);c+=vec3(.8,.85,1.)*smoothstep(.12,0.,d)*(h-.985)*60.;}}
  // 银河带
  float mw=exp(-pow(dot(rd,normalize(vec3(.3,1.,-.4)))/.25,2.));c+=vec3(.2,.19,.24)*mw*pow(fbm3(rd*6.),2.)*.25;
  return c;}

vec3 earth(vec3 p,vec3 rd,float t){
  vec3 n=normalize(p-EC);float sd=dot(n,SUN);
  float land=smoothstep(.5,.54,fbm(n*2.6+vec3(3.)));
  vec3 day=mix(vec3(.01,.03,.07),mix(vec3(.12,.1,.05),vec3(.05,.08,.03),fbm3(n*9.)),land);
  float cloud=smoothstep(.45,.75,fbm(n*5.+vec3(uT*.01,0,0)));
  day=mix(day,vec3(.8),cloud*.8);
  vec3 col=day*max(sd,0.)*2.;
  // 夜面城市灯光
  float night=smoothstep(.12,-.15,sd);
  float cl=pow(smoothstep(.35,.8,fbm(n*9.)),2.)*pow(fbm(n*30.),2.)*6.;float fine=step(.55,noise(n*420.))*noise(n*120.);
  float lights=land*sat(cl*fine*3.)*(1.-cloud*.7);
  // 巨型城市带：沿大陆海岸线的发光网络
  float web=smoothstep(.015,.0,abs(fbm(n*2.6+vec3(3.))-.52))*.35;
  col+=night*(lights*vec3(1.,.62,.28)*2.2+web*vec3(1.,.7,.35)*.8+cloud*vec3(.02,.025,.04));
  return col;}

vec3 moon(vec3 p,vec3 rd){
  vec3 n=normalize(p-MC);vec3 ln=n;
  float h=fbm(n*4.)*.6+fbm(n*16.)*.4;
  vec3 v=voronoi(n*5.);float crater=smoothstep(.35,.15,v.x)*(.6+.4*hash11(v.z*9.));float rim=smoothstep(.12,.0,abs(v.x-.36))*.5;
  vec3 v2=voronoi(n*13.+7.);crater+=smoothstep(.3,.1,v2.x)*.5;rim+=smoothstep(.1,.0,abs(v2.x-.3))*.3;
  vec3 bn=normalize(n+(vec3(noise(n*30.),noise(n*30.+5.),noise(n*30.+9.))-.5)*.25);
  float dif=max(dot(bn,SUN),0.);
  vec3 alb=vec3(.42,.41,.4)*(.55+.45*h)*(1.-crater*.35+rim*.3);
  float mare=smoothstep(.55,.6,fbm3(n*1.8+vec3(8.)));alb*=1.-mare*.4;
  vec3 col=alb*dif*2.2+alb*.015+alb*vec3(.2,.35,.6)*.14*max(dot(bn,normalize(vec3(0,-1,-.4))),0.);
  // 电路：从一点向外蔓延的经纬网格走线
  vec3 seed=normalize(vec3(-.4,-.2,-1.));float ang=acos(clamp(dot(n,seed),-1.,1.));
  float front=uB*3.3;float act=smoothstep(front,front-.35,ang);
  if(act>0.){
    float lon=atan(n.z,n.x),lat=asin(n.y);vec2 g=vec2(lon*14.,lat*14.);vec2 id=floor(g),f=fract(g);
    float hr=hash12(id),hv=hash12(id+3.1);
    float tr=0.;
    tr=max(tr,smoothstep(.06,.0,abs(f.y-.5))*step(.35,hr)*step(f.x,.5+.5*step(.6,hv)));
    tr=max(tr,smoothstep(.06,.0,abs(f.x-.5))*step(hr,.55)*step(.5-.5*step(.4,hv),f.y));
    vec2 g2=g*3.;vec2 i2=floor(g2),f2=fract(g2);
    tr=max(tr,.6*smoothstep(.08,.0,abs(f2.y-.5))*step(.7,hash12(i2)));
    tr=max(tr,.6*smoothstep(.08,.0,abs(f2.x-.5))*step(.82,hash12(i2+1.)));
    float pad=smoothstep(.16,.08,length(f-.5))*step(.7,hash12(id+9.));
    float pulse=.55+.45*sin(ang*30.-uT*8.+hr*6.);
    vec3 ec=mix(vec3(.25,.85,1.),vec3(1.,.7,.3),step(.85,hash12(id+4.)));
    col=mix(col,col*.25,act*.8);
    col+=ec*(tr*pulse*2.2+pad*3.)*act;
    col+=vec3(.6,.9,1.)*smoothstep(.1,.0,abs(ang-front+.12))*step(.01,uB)*2.5; // 蔓延的前沿
  }
  return col;}

void main(){
  vec2 uv=suv();
  float k=uA;
  vec3 ro=vec3(0.,.2+k*.9,-1.5-k*6.);
  float pitch=-.05+k*.22;
  vec3 fw=normalize(vec3(.02,sin(pitch),cos(pitch)));vec3 rt=normalize(cross(vec3(0,1,0),fw));vec3 up=cross(fw,rt);
  vec3 rd=normalize(fw*1.5+uv.x*rt+uv.y*up);
  vec3 col=stars(rd);
  float tmin=1e9;
  // 太阳光晕（在画面右侧外）
  col+=vec3(1.,.7,.4)*pow(max(dot(rd,SUN),0.),60.)*2.;
  // 月球
  vec2 hm=sphere(ro,rd,MC,MR);
  if(hm.x>0.){col=moon(ro+rd*hm.x,rd);tmin=hm.x;}
  // 地球 + 大气
  vec2 he=sphere(ro,rd,EC,ER);vec2 ha=sphere(ro,rd,EC,ER*1.03);
  if(ha.x>0.&&ha.x<tmin){
    float t0=ha.x,t1=he.x>0.?he.x:ha.y;float len=t1-t0;
    vec3 pm=ro+rd*(t0+t1)*.5;vec3 nm=normalize(pm-EC);float sd=dot(nm,SUN);
    float mu=dot(rd,SUN);
    vec3 scat=vec3(.25,.5,1.)*sat(sd+.2)*1.2+vec3(1.,.42,.12)*exp(-pow((sd-.05)/.1,2.))*1.3*(1.+2.*pow(max(mu,0.),6.));
    vec3 atm=scat*pow(1.-exp(-len*.9),1.6);
    if(he.x>0.){col=earth(ro+rd*he.x,rd,he.x);tmin=he.x;}
    col=col*exp(-len*.25)+atm;
  }
  // 轨道环：赤道面上的一圈巨构，上面有灯
  {float tt=(EC.y+.0-ro.y)/rd.y;vec3 n=vec3(0,1,0);
    vec3 pr=ro+rd*tt;float r=length(pr.xz-EC.xz);
    if(tt>0.&&tt<tmin&&r>ER*1.1&&r<ER*1.118){
      float a=atan(pr.z-EC.z,pr.x-EC.x);
      vec3 rc=vec3(.08,.08,.09)*(.3+max(dot(normalize(pr-EC),SUN),0.)*1.5);
      float lamp=step(.8,fract(a*300.))*step(.5,hash11(floor(a*300.)));
      float stripe=smoothstep(.2,0.,abs(fract((r-ER*1.1)/(ER*.018)*3.)-.5)-.3);
      rc+=vec3(.5,.9,1.)*lamp*1.5+vec3(1.,.7,.4)*stripe*.25;
      // 被地球遮挡的阴影
      vec2 sh=sphere(pr,SUN,EC,ER);if(sh.x>0.)rc*=.25;
      col=rc;}}
  col*=uC;
  fragColor=vec4(col,1.);
}

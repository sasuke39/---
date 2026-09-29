// ===== 镜头：星系（体积光线步进）→ 中心黑洞变成瞳孔 =====
// uA = 镜头拉远/转正进度；uB = 黑洞（瞳孔）出现；uC = 淡入
uniform float uA,uB,uC,uD;

float armF(vec2 xz){float r=length(xz);float th=atan(xz.y,xz.x)+uT*.04;
  float warp=fbm3(vec3(xz*3.,1.));float ph=th-log(max(r,.05))*2.6+warp*1.2;
  return pow(.5+.5*cos(2.*ph),6.)+.35*pow(.5+.5*cos(4.*ph+1.),8.);}
vec4 galaxy(vec3 p){ // 返回 (发光颜色, 密度)
  float r=length(p.xz);
  float arm=armF(p.xz);
  float disk=exp(-r/.85)*exp(-abs(p.y)/(.035+.025*r));
  float bulge=exp(-length(p*vec3(1.,1.7,1.))/.14);
  float knots=smoothstep(.45,.85,fbm(vec3(p.xz*9.,p.y*6.)));
  float dustN=fbm(vec3(p.xz*7.,p.y*12.)+vec3(0,0,1.));
  float dust=smoothstep(.42,.62,dustN)*smoothstep(.02,.5,arm)*disk*(1.-smoothstep(.1,.3,armF(p.xz*1.08)));
  vec3 armCol=mix(vec3(.3,.55,1.),vec3(.35,.95,1.),fbm3(p*4.));
  vec3 hot=vec3(1.,.45,.75)*smoothstep(.6,.9,knots)*arm*disk*3.;
  vec3 em=armCol*arm*disk*(.6+1.6*knots)+vec3(1.,.72,.38)*bulge*6.+vec3(1.,.8,.55)*disk*.25+hot;
  float dens=dust*28.+disk*.4;
  return vec4(em,dens);
}
// 星系盘面上清晰的恒星点（2D，两层）
vec3 diskStars(vec3 ro,vec3 rd){
  float tt=-ro.y/rd.y;if(tt<0.)return vec3(0);vec2 xz=(ro+rd*tt).xz;float r=length(xz);vec3 c=vec3(0);
  float w=exp(-r/.9)*(.04+armF(xz));
  for(int i=0;i<2;i++){float sc=i==0?60.:160.;vec2 g=xz*sc;vec2 id=floor(g);vec2 f=fract(g)-.5;float h=hash12(id+float(i)*31.);
    vec2 o=(vec2(hash12(id+1.3),hash12(id+7.7))-.5)*.7;float d=length(f-o);
    float px=.02+.9/sc*tt*.0;
    vec3 sc3=mix(vec3(.7,.85,1.),vec3(1.,.8,.55),hash12(id+4.));
    c+=sc3*smoothstep(.18,.0,d)*step(1.-w*.55,h)*(i==0?2.5:1.3);}
  return c;}
void main(){
  vec2 uv=suv();
  float k=uA;
  float elev=mix(.12,1.5707,smoothstep(.15,1.,k));
  float dist=mix(.35,5.3,pow(k,1.4));
  vec3 focus=mix(vec3(1.05,0.,.2),vec3(0.),smoothstep(0.,.8,k));
  float az=-.6+k*.8;
  vec3 dir=vec3(cos(elev)*cos(az),sin(elev),cos(elev)*sin(az));
  vec3 ro=focus+dir*dist;
  vec3 fw=normalize(focus-ro);vec3 wup=mix(vec3(0,1,0),vec3(-sin(az),0.,cos(az)),smoothstep(.6,1.,k));
  vec3 rt=normalize(cross(wup,fw));vec3 up=cross(fw,rt);
  vec3 rd=normalize(fw*1.6+uv.x*rt+uv.y*up);
  vec3 col=vec3(0);
  {vec3 g=rd*300.;vec3 id=floor(g);float h=hash13(id);if(h>.993)col+=vec3(.9,.9,1.)*smoothstep(.3,0.,length(fract(g)-.5))*(h-.993)*90.;}
  // 与星系盘所在的包围体相交
  vec2 hb=sphere(ro,rd,vec3(0),3.2);
  float trans=1.;vec3 acc=vec3(0);
  if(hb.y>0.){
    float t0=max(hb.x,0.),t1=hb.y;
    // 只在 |y|<0.35 的平板内积分
    float ty0=(-.35-ro.y)/rd.y,ty1=(.35-ro.y)/rd.y;if(ty0>ty1){float tmp=ty0;ty0=ty1;ty1=tmp;}
    t0=max(t0,ty0);t1=min(t1,ty1);
    if(t1>t0){
      const int N=72;float dt=(t1-t0)/float(N);float t=t0+dt*hash12(gl_FragCoord.xy+fract(uT)*100.);
      for(int i=0;i<N;i++){vec3 p=ro+rd*t;vec4 g=galaxy(p);
        acc+=trans*g.rgb*dt;trans*=exp(-g.a*dt);if(trans<.01)break;t+=dt;}
    }
  }
  col=col*trans+acc+diskStars(ro,rd)*sqrt(trans+.05)*smoothstep(.3,.9,uA);
  // 中心黑洞：阴影 + 光子环（与瞳孔对齐）
  if(uB>0.){
    vec3 w=-ro;float b=dot(w,rd);float dm=length(w-rd*b);
    float R=.58*uB;
    col*=smoothstep(R*.96,R*1.04,dm);
    col+=vec3(1.,.75,.45)*exp(-pow((dm-R*1.03)/(.006+.008*R),2.))*2.2*uB+vec3(1.,.6,.25)*exp(-max(dm-R,0.)/.18)*step(R,dm)*.8*uB;
  }
  col*=uC;
  fragColor=vec4(col,1.);
}

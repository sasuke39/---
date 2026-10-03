// ===== 第 1 / 16 镜：洞穴岩壁上的喷绘手印 =====
// uA = 喷涂进度 0..1；uB = 手的抬起进度 0..1（0 = 按在墙上，1 = 完全离开）
// uC = 结尾模式（1：中央是六指新手印，旧的五指手印在左上方）；uD = 颜料湿润反光
uniform float uA,uB,uC,uD;

float rockH(vec2 p){return fbm(vec3(p*1.3,1.))*.8+ridged(vec3(p*3.2,2.))*.3+fbm3(vec3(p*12.,3.))*.05+noise(vec3(p*60.,4.))*.006;}
vec3 rockN(vec2 p){float e=.0025;float h=rockH(p);return normalize(vec3(-(rockH(p+vec2(e,0))-h)/e*.07,-(rockH(p+vec2(0,e))-h)/e*.07,1.));}

// 喷涂颜料密度：围绕手的雾状喷溅 + 细小液滴；手所在处为负形
float spray(vec2 p,vec2 c,float amt,float six,float seed){
  if(amt<=0.)return 0.;
  vec2 d=p-c;float r=length(d*vec2(1.,.82));
  float rad=.62*(.55+.45*amt)+.06*(fbm3(vec3(d*3.,seed))-.5);
  float cloud=smoothstep(rad,rad*.35,r)*(.55+.45*fbm3(vec3(d*9.,seed+1.)));
  // 液滴：多层网格上的随机小点
  float drops=0.;
  for(int i=0;i<3;i++){float s=90.+float(i)*110.;vec2 g=d*s;vec2 id=floor(g);vec2 f=fract(g)-.5;float h=hash12(id+seed*7.+float(i)*31.);
    vec2 o=(vec2(hash12(id+1.7),hash12(id+5.3))-.5)*.6;float sz=.12+.25*hash12(id+9.);
    drops=max(drops,step(1.-smoothstep(rad*1.25,0.,r)*.55,h)*smoothstep(sz,sz*.5,length(f-o)));}
  float hd=handSD(p-c,six);
  float rim=exp(-max(hd,0.)/.07)*(.7+.3*fbm3(vec3(d*14.,seed+3.)));   // 紧贴手边缘的浓颜料
  float m=sat(cloud*amt*1.1+rim*smoothstep(.1,.8,amt)*.95+drops*sat(amt*1.5)*.8);
  float hand=smoothstep(-.003,.004,hd); // 手所在处为 0
  return m*hand;}

void main(){
  vec2 uv=suv();
  // 火把：左上方，带闪烁
  float fl=1.+.12*sin(uT*11.)+.08*sin(uT*23.+1.)+.1*(noise(vec3(uT*6.,0.,0.))-.5);
  vec3 LP=vec3(-.75+.02*sin(uT*7.),.95+.02*sin(uT*9.),.9);
  vec3 n=rockN(uv);
  vec3 P=vec3(uv,rockH(uv)*.05);vec3 Ld=LP-P;float dist=length(Ld);Ld/=dist;
  float dif=max(dot(n,Ld),0.);float att=1./(1.+dist*dist*4.5);
  // 岩石底色：石灰岩 + 铁锈色条纹 + 方解石闪点
  float st=fbm3(vec3(uv*vec2(1.2,4.),5.));
  vec3 alb=mix(vec3(.58,.5,.42),vec3(.5,.33,.22),smoothstep(.45,.7,st))*(.75+.35*fbm3(vec3(uv*6.,6.)));
  alb=mix(alb,vec3(.2,.17,.15),smoothstep(.6,.8,fbm3(vec3(uv*3.,8.)))*.5);
  // 古老的手印（褪色）：用不同角度和大小，暗示这里已经有很多代人来过
  float old=0.,oldB=0.;
  for(int i=0;i<3;i++){float fi=float(i);vec2 c=vec2(-.42+fi*.55,.62-fi*.18+(fi==2.?-1.2:0.));float a=(fi-1.)*.5;float s=.55-fi*.05;
    vec2 q=rot(a)*(uv-c)/s;float sp=spray(q,vec2(0.),1.,0.,fi+20.)*(.16+.08*fi);
    if(i==1)oldB=max(oldB,sp*.7);else old=max(old,sp);}
  // 结尾：旧的五指手印移到左上方，中央是新的六指手印
  float main5=0.,main6=0.;
  if(uC>.5){vec2 q=rot(.32)*(uv-vec2(-.4,.56))/.52;main5=spray(q,vec2(0.),1.,0.,3.)*.85;main6=spray(uv,vec2(0.),uA,1.,7.);}
  else main5=spray(uv,vec2(0.),uA,0.,3.);
  vec3 ochre=vec3(.3,.055,.025),ochre2=vec3(.38,.07,.03),mang=vec3(.05,.035,.03);
  alb=mix(alb,alb*.25+ochre*.75,old*.5);alb=mix(alb,mang,oldB);
  alb=mix(alb,ochre2,main5);alb=mix(alb,ochre*1.1,main6);
  vec3 col=alb*(vec3(1.,.52,.2)*4.*pow(dif,1.4)*att*fl+vec3(.03,.025,.03)*.25);
  // 未干颜料的反光
  col+=vec3(1.,.6,.3)*pow(max(dot(reflect(-Ld,n),vec3(0,0,1)),0.),30.)*(main5+main6)*uD*.6*att*fl;
  // 手：按在墙上，看到的是手背；抬起时向镜头移动、放大、虚化
  if(uB<1.){
    float k=uB*uB;vec2 hp=(uv-vec2(-.05*k,-.12*k))/(1.+.35*k);
    float d=handSD(hp,uC>.5?1.:0.);
    float e=.004;float dx=handSD(hp+vec2(e,0),uC>.5?1.:0.)-d,dy=handSD(hp+vec2(0,e),uC>.5?1.:0.)-d;
    float hgt=sqrt(sat(-d/.1));vec3 hn=normalize(vec3(-vec2(dx,dy)/e*(1.-hgt)*1.6,1.));
    vec3 Lh=normalize(LP-vec3(hp,.1));float hd=max(dot(hn,Lh),0.);
    vec3 skin=vec3(.3,.17,.12)*(.8+.4*fbm3(vec3(hp*30.,9.)));
    // 指节与皮肤纹理
    skin*=1.-.15*smoothstep(.6,.9,noise(vec3(hp*60.,2.)));
    // 手背也沾上了颜料
    float sp=uC>.5?spray(hp,vec2(0.),uA,1.,7.):spray(hp,vec2(0.),uA,0.,3.);
    float onHand=sat(uA*.9)*(.5+.5*fbm3(vec3(hp*14.,4.)))*smoothstep(-.12,0.,d);
    skin=mix(skin,ochre2*.9,onHand*.7);
    vec3 hc=skin*(vec3(1.,.52,.2)*2.6*pow(hd,2.)*fl*att*1.4+vec3(.02,.015,.015));
    hc+=vec3(1.,.48,.18)*pow(1.-hn.z,2.)*.35*fl*smoothstep(-.3,.6,dot(normalize(vec2(dx,dy)),normalize(LP.xy-hp))); // 朝火把一侧的轮廓光
    if(uC>.5)hc*=.35;                       // 结尾那只手隐在阴影里，看不清
    float cover=smoothstep(.003+k*.03,-.003-k*.03,d)*(1.-sm((uB-.55)/.45));
    // 手在墙上的投影
    float sh=smoothstep(.06,-.04,handSD(uv-vec2(.05,-.06)*(1.+k*4.),uC>.5?1.:0.))*(1.-uB)*.6;
    col*=1.-sh;col=mix(col,hc,cover);
  }
  // 洞穴里的烟雾与火光的漫射
  col+=vec3(.25,.1,.04)*.12*fbm3(vec3(uv*2.,uT*.15))*fl*smoothstep(1.6,.2,length(uv-LP.xy));
  col*=smoothstep(1.9,.3,length((uv-vec2(-.2,.25))*vec2(1.3,.8)));
  fragColor=vec4(col,1.);
}

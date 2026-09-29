// ===== 图层 G：恒星 → 银河系（正对镜头）→ 银心黑洞（单位：米；1 星系单位 U = 2.35e20 米）=====
// uB = 银心黑洞（瞳孔）大小 0..1
uniform float uA,uB,uC,uD;
const float U=2.35e20;
const vec2 SUNG=vec2(1.05,.35); // 太阳在星系中的位置（星系单位）
float lg(float x){return log(x)/log(10.);}
float armF(vec2 xz){float r=length(xz);float th=atan(xz.y,xz.x)+uT*.04;float warp=fbm3(vec3(xz*3.,1.));float ph=th-log(max(r,.05))*2.6+warp*1.2;
  return pow(.5+.5*cos(2.*ph),6.)+.35*pow(.5+.5*cos(4.*ph+1.),8.);}
vec4 galaxy(vec3 p){float r=length(p.xz);float arm=armF(p.xz);float disk=exp(-r/.85)*exp(-abs(p.y)/(.035+.025*r));
  float bulge=exp(-length(p*vec3(1.,1.7,1.))/.14);float knots=smoothstep(.45,.85,fbm(vec3(p.xz*9.,p.y*6.)));
  float dust=smoothstep(.42,.62,fbm(vec3(p.xz*7.,p.y*12.)+vec3(0,0,1.)))*smoothstep(.02,.5,arm)*disk*(1.-smoothstep(.1,.3,armF(p.xz*1.08)));
  vec3 armCol=mix(vec3(.3,.55,1.),vec3(.35,.95,1.),fbm3(p*4.));vec3 hot=vec3(1.,.45,.75)*smoothstep(.6,.9,knots)*arm*disk*3.;
  vec3 em=armCol*arm*disk*(.6+1.6*knots)+vec3(1.,.72,.38)*bulge*6.+vec3(1.,.8,.55)*disk*.25+hot;return vec4(em,dust*28.+disk*.4);}
void main(){
  vec2 uv=suv();float L=lg(uS);float px=uS/960.;
  // 镜头焦点：从太阳（锚点）漂移到银心
  float k=sm(sat((L-19.2)/1.4));
  vec2 focG=mix(SUNG,vec2(0.),k);           // 星系单位
  vec2 gp=focG+uv*uS/U;                     // 当前像素在星系平面上的位置（星系单位）
  vec2 wp=(focG-SUNG)*U+uv*uS;              // 以太阳为原点的米制坐标（避免大数加小数的精度损失）
  vec3 col=vec3(0);
  // 多尺度星点：每个八度一个网格，单元大小 4^k × 1e15 米，只画屏幕上 3~300 像素之间的
  float dens=exp(-length(gp)/.9)*(.1+armF(gp))+.02;
  for(int o=0;o<22;o++){float c=1e12*pow(4.,float(o));float cp=c/px;if(cp<5.||cp>160.)continue;
    vec2 g=wp/c;vec2 id=floor(g);vec2 f=fract(g)-.5;float h=hash12(id+float(o)*13.1);
    vec2 off=(vec2(hash12(id+3.7),hash12(id+9.2))-.5)*.7;float d=length(f-off)*cp;
    float prob=o<11?.06:clamp(dens*.5,0.,.5);
    float fade=smoothstep(5.,14.,cp)*smoothstep(160.,60.,cp);
    vec3 sc=mix(vec3(.7,.82,1.),vec3(1.,.8,.55),hash12(id+5.));
    float br=pow(hash12(id+8.),6.)*6.+.25;
    col+=sc*step(1.-prob,h)*exp(-d*d*.6)*fade*br;}
  // 星系本体：竖直方向积分（正对视角）
  float gA=smoothstep(18.3,19.4,L);
  if(gA>0.){vec3 acc=vec3(0);float tr=1.;float dt=.6/20.;
    for(int i=0;i<20;i++){float y=.3-float(i)*dt;vec4 g=galaxy(vec3(gp.x,y,gp.y));acc+=tr*g.rgb*dt;tr*=exp(-g.a*dt);}
    col=col*mix(1.,tr,gA)+acc*gA*1.1;}
  // 银心黑洞：阴影 + 光子环
  if(uB>0.){float dm=length(gp)*U/uS;float R=.145*uB;
    col*=smoothstep(R*.96,R*1.04,dm);col+=vec3(1.,.75,.45)*exp(-pow((dm-R*1.03)/(.004+.006*R),2.))*2.*uB+vec3(1.,.6,.25)*exp(-max(dm-R,0.)/.12)*step(R,dm)*.6*uB;}
  fragColor=vec4(col,1.);
}

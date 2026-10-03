// ===== 公共函数：噪声 / fbm / 工具 =====
#define PI 3.14159265
#define TAU 6.28318531
uniform vec2 uRes;      // 渲染分辨率
uniform float uT;       // 全片时间（秒）
uniform float uLT;      // 本镜头内时间（秒）
uniform float uP;       // 本镜头进度 0..1
out vec4 fragColor;

float sat(float x){return clamp(x,0.,1.);}
float hash11(float p){p=fract(p*.1031);p*=p+33.33;p*=p+p;return fract(p);}
float hash12(vec2 p){vec3 p3=fract(vec3(p.xyx)*.1031);p3+=dot(p3,p3.yzx+33.33);return fract((p3.x+p3.y)*p3.z);}
float hash13(vec3 p3){p3=fract(p3*.1031);p3+=dot(p3,p3.zyx+31.32);return fract((p3.x+p3.y)*p3.z);}
vec3 hash33(vec3 p3){p3=fract(p3*vec3(.1031,.1030,.0973));p3+=dot(p3,p3.yxz+33.33);return fract((p3.xxy+p3.yxx)*p3.zyx);}
float noise(vec3 x){vec3 i=floor(x),f=fract(x);f=f*f*(3.-2.*f);
  return mix(mix(mix(hash13(i),hash13(i+vec3(1,0,0)),f.x),mix(hash13(i+vec3(0,1,0)),hash13(i+vec3(1,1,0)),f.x),f.y),
             mix(mix(hash13(i+vec3(0,0,1)),hash13(i+vec3(1,0,1)),f.x),mix(hash13(i+vec3(0,1,1)),hash13(i+vec3(1,1,1)),f.x),f.y),f.z);}
float noise2(vec2 x){vec2 i=floor(x),f=fract(x);f=f*f*(3.-2.*f);
  return mix(mix(hash12(i),hash12(i+vec2(1,0)),f.x),mix(hash12(i+vec2(0,1)),hash12(i+vec2(1,1)),f.x),f.y);}
float fbm(vec3 p){float a=.5,s=0.;for(int i=0;i<5;i++){s+=a*noise(p);p=p*2.03+vec3(1.7,9.2,3.1);a*=.5;}return s;}
float fbm3(vec3 p){float a=.5,s=0.;for(int i=0;i<3;i++){s+=a*noise(p);p=p*2.03+vec3(1.7,9.2,3.1);a*=.5;}return s;}
float fbm2(vec2 p){float a=.5,s=0.;for(int i=0;i<5;i++){s+=a*noise2(p);p=p*2.03+vec2(1.7,9.2);a*=.5;}return s;}
float ridged(vec3 p){float a=.5,s=0.;for(int i=0;i<4;i++){s+=a*(1.-abs(noise(p)*2.-1.));p*=2.1;a*=.5;}return s;}
mat2 rot(float a){float c=cos(a),s=sin(a);return mat2(c,-s,s,c);}
// 3D voronoi：返回 (到最近点距离, 到边界距离, 单元 id)
vec3 voronoi(vec3 x){vec3 p=floor(x),f=fract(x);float d1=8.,d2=8.;float id=0.;
  for(int k=-1;k<=1;k++)for(int j=-1;j<=1;j++)for(int i=-1;i<=1;i++){vec3 b=vec3(i,j,k);vec3 r=b-f+hash33(p+b);float d=dot(r,r);
    if(d<d1){d2=d1;d1=d;id=hash13(p+b);}else if(d<d2)d2=d;}
  return vec3(sqrt(d1),sqrt(d2)-sqrt(d1),id);}
vec2 sphere(vec3 ro,vec3 rd,vec3 c,float r){vec3 oc=ro-c;float b=dot(oc,rd),h=b*b-dot(oc,oc)+r*r;if(h<0.)return vec2(-1);h=sqrt(h);return vec2(-b-h,-b+h);}
// 屏幕坐标：竖屏，y 方向范围 [-1,1]，x 为 [-0.5625,0.5625]
vec2 suv(){return (gl_FragCoord.xy-.5*uRes)/(.5*uRes.y);}
float sm(float t){t=clamp(t,0.,1.);return t*t*(3.-2.*t);}
float smin(float a,float b,float k){float h=clamp(.5+.5*(b-a)/k,0.,1.);return mix(b,a,h)-k*h*(1.-h);}
float sdSeg(vec2 p,vec2 a,vec2 b,float ra,float rb){vec2 pa=p-a,ba=b-a;float h=clamp(dot(pa,ba)/dot(ba,ba),0.,1.);return length(pa-ba*h)-mix(ra,rb,h);}
// 一根手指：根部 b，方向角 ang（相对竖直，弧度），三节长度 l，根部半径 r，每节弯曲 bend
float finger(vec2 p,vec2 b,float ang,vec3 l,float r,float bend){
  vec2 d=vec2(-sin(ang),cos(ang));vec2 p1=b+d*l.x;
  d=rot(-bend)*d;vec2 p2=p1+d*l.y;d=rot(-bend*1.3)*d;vec2 p3=p2+d*l.z;
  float s=sdSeg(p,b,p1,r,r*.9);s=min(s,sdSeg(p,p1,p2,r*.9,r*.82));s=min(s,sdSeg(p,p2,p3,r*.82,r*.74));return s;}
// ===== 全片唯一的形状：一只右手（掌心朝向镜头，五指自然张开）=====
// 坐标为屏幕单位（suv），手掌中心大约在 (0,-0.12)。six>0.5 时多出第六根手指。
float handSD(vec2 p,float six){
  p.y+=.02;
  vec2 q=p-vec2(.0,-.3);float w=.17+.025*sat((q.y+.16)/.32);
  float palm=length(max(abs(q)-vec2(w,.14),0.))+min(max(abs(q.x)-w,abs(q.y)-.14),0.)-.06;
  float arm=sdSeg(p,vec2(.01,-.48),vec2(.04,-1.4),.135,.16);
  float h=smin(palm,arm,.09);
  h=smin(h,finger(p,vec2(-.125,-.14),.19,vec3(.21,.13,.095),.058,.035),.04);    // 食指
  h=smin(h,finger(p,vec2(-.04,-.12),.03,vec3(.24,.145,.1),.061,.03),.04);       // 中指
  h=smin(h,finger(p,vec2(.05,-.13),-.13,vec3(.22,.135,.095),.057,.035),.04);    // 无名指
  if(six>.5)h=smin(h,finger(p,vec2(.11,-.15),-.27,vec3(.19,.115,.085),.053,.04),.035); // 第六指
  vec2 pb=six>.5?vec2(.165,-.2):vec2(.125,-.17);float pa=six>.5?-.48:-.36;
  h=smin(h,finger(p,pb,pa,vec3(.165,.1,.075),.05,.05),.04);                     // 小指
  h=smin(h,finger(p,vec2(-.15,-.36),1.0,vec3(.16,.125,.09),.072,-.16),.08);    // 拇指
  return h;}

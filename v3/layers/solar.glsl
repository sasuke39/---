// ===== 图层 F：太阳系 —— 戴森球包裹的太阳 + 行星轨道（单位：米，距离为艺术化压缩）=====
uniform float uA,uB,uC,uD;
vec3 LS=normalize(vec3(.62,.16,.56));
const float SRAD=7e8;
vec3 SP(){return LS*3.1e9;}
float lg(float x){return log(x)/log(10.);}
mat3 shellRot(){float a=uT*.05;float c=cos(a),s=sin(a);return mat3(c,0,s,0,1,0,-s,0,c);}
vec3 sunSurf(vec3 n,vec3 rd){float mu=max(dot(n,-rd),0.);vec3 v=voronoi(n*38.+vec3(0,uT*.15,0));float gran=smoothstep(0.,.25,v.y)*.35+.65;
  float big=fbm(n*6.+uT*.05);vec3 c=mix(vec3(1.,.28,.04),vec3(1.,.72,.35),pow(gran*big,1.5));return c*(.35+.65*pow(mu,.45))*gran*3.2;}
void main(){
  vec2 uv=suv();float F=4.;float L=lg(uS);
  vec2 foc=mix(vec2(0.),SP().xz,sm(sat((L-9.7)/.8)));
  vec3 ro=vec3(foc.x,F*uS+SP().y*sm(sat((L-9.7)/.8)),foc.y);vec3 rd=normalize(vec3(uv.x,-F,uv.y));
  vec3 col=vec3(0);
  {vec3 g=normalize(vec3(uv.x,.8,uv.y))*300.;vec3 id=floor(g);float h=hash13(id);if(h>.99)col+=vec3(.9,.9,1.)*smoothstep(.3,0.,length(fract(g)-.5))*(h-.99)*60.;}
  // 平面上的点：到行星轨道的距离
  float tp=-ro.y/rd.y;vec3 pp=ro+rd*tp;float px=uS/960.;
  vec2 sc=SP().xz;float ds=length(pp.xz-sc);
  for(int i=0;i<5;i++){float R=3.1e9*pow(1.75,float(i)-1.);float w=max(px*1.2,R*.002);col+=vec3(.5,.7,1.)*.18*exp(-pow((ds-R)/w,2.))*smoothstep(1e13,1e11,uS);
    float a=uT*.05*pow(1.75,-float(i))+float(i)*2.1;vec2 pl=sc+R*vec2(cos(a),sin(a));if(i==1)pl=vec2(0.);
    float dp=length(pp.xz-pl);col+=vec3(.6,.8,1.)*exp(-pow(dp/max(px*2.,1.),2.))*1.5;}
  // 太阳 + 戴森壳（在太阳局部单位下计算）
  vec3 lo=(ro-SP())/SRAD;
  float b=dot(-lo,rd);vec3 cp=lo+rd*b;float dmin=length(cp);float ang=atan(cp.z,cp.x);
  float cor=exp(-(dmin-1.)*2.5)*(.6+.4*fbm3(vec3(ang*3.,dmin*2.,uT*.1)))*step(1.,dmin);
  vec3 corona=vec3(1.,.5,.18)*cor*1.1+vec3(1.,.6,.3)*.35/(1.+pow(dmin*.8,2.));
  vec2 hs=sphere(lo,rd,vec3(0),1.);vec3 sun=vec3(0);if(hs.x>0.)sun=sunSurf(normalize(lo+rd*hs.x),rd);
  vec2 hh=sphere(lo,rd,vec3(0),1.32);vec3 front=vec3(0);float occ=0.;
  if(hh.x>0.){vec3 p=lo+rd*hh.x;vec3 n=normalize(p);vec3 nl=shellRot()*n;vec3 v=voronoi(nl*6.5);
    float present=step(v.z,.94)*step(.025,v.y);float seam=smoothstep(.025,.0,v.y)*step(v.z,.94);
    float ndv=max(dot(n,-rd),0.);vec3 pc=vec3(.03,.028,.027)*(.4+.6*hash11(v.z*31.))*(.7+.3*fbm3(nl*40.));
    pc+=vec3(1.,.5,.2)*.08*pow(1.-ndv,2.)+vec3(.9,.5,.2)*.04*smoothstep(.2,.0,v.x);
    vec2 lgd=fract(nl.xz*120.);pc+=vec3(.5,.85,1.)*step(.93,hash12(floor(nl.xz*120.)))*smoothstep(.3,0.,length(lgd-.5))*1.2;
    front=pc;occ=present;sun+=vec3(1.,.55,.2)*seam*2.2*(hs.x>0.?1.:.3);}
  col+=corona*(1.-occ*.85);col=mix(col+sun,front,occ);
  fragColor=vec4(col,1.);
}

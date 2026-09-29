// ===== 镜头：戴森球 —— 亿万块镜片包裹太阳 =====
// uA = 镜头拉远进度；uB = 覆盖进度；uC = 淡入
uniform float uA,uB,uC,uD;
const float SR=1.,SH=1.32; // 太阳半径，壳层半径
mat3 shellRot(){float a=uT*.05;float c=cos(a),s=sin(a);return mat3(c,0,s,0,1,0,-s,0,c);}

vec3 sunSurf(vec3 n,vec3 rd){
  float mu=max(dot(n,-rd),0.);
  vec3 v=voronoi(n*38.+vec3(0,uT*.15,0));
  float gran=smoothstep(0.,.25,v.y)*.35+.65;
  float big=fbm(n*6.+uT*.05);
  float spot=smoothstep(.72,.8,fbm3(n*3.+7.));
  vec3 c=mix(vec3(1.,.28,.04),vec3(1.,.72,.35),pow(gran*big,1.5));
  c*=(.35+.65*pow(mu,.45))*(1.-spot*.85)*gran;
  return c*3.2;
}
float coverage(vec3 n){ // 覆盖从一侧向另一侧推进
  float a=dot(n,normalize(vec3(-.6,.5,-.6)))*.5+.5;
  return smoothstep(a-.08,a+.08,uB*1.25-.1);
}
void main(){
  vec2 uv=suv();
  float k=1.-pow(1.-sat(uA),3.);
  vec3 ro=vec3(.4,.25,-3.0-k*8.);ro.xz*=rot(.25-k*.3);
  vec3 ta=vec3(0.);vec3 fw=normalize(ta-ro);vec3 rt=normalize(cross(vec3(0,1,0),fw));vec3 up=cross(fw,rt);
  vec3 rd=normalize(fw*1.6+uv.x*rt+uv.y*up);
  vec3 col=vec3(0);
  // 星空
  {vec3 g=rd*260.;vec3 id=floor(g);float h=hash13(id);if(h>.992)col+=vec3(1.)*smoothstep(.3,0.,length(fract(g)-.5))*(h-.992)*100.;}
  // 日冕：射线离太阳的最近距离
  float b=dot(-ro,rd);vec3 cp=ro+rd*b;float dmin=length(cp);
  float ang=atan(cp.y,cp.x);
  float streak=.6+.4*fbm3(vec3(ang*3.,dmin*2.,uT*.1));
  float cor=exp(-(dmin-SR)*3.2)*streak;
  vec3 corona=vec3(1.,.5,.18)*cor*1.2*step(SR,dmin)+vec3(1.,.6,.3)*.25/(1.+pow(dmin*1.2,2.));
  float lightLeak=1.;
  vec2 hs=sphere(ro,rd,vec3(0),SR);
  vec3 sun=vec3(0);
  if(hs.x>0.)sun=sunSurf(normalize(ro+rd*hs.x),rd);
  // 日珥：边缘的火焰
  float edge=dmin-SR;if(edge>0.&&edge<.25){float f=fbm(vec3(ang*6.,edge*8.-uT*.3,uT*.2));sun+=vec3(1.,.4,.1)*smoothstep(.55,.9,f)*exp(-edge*14.)*6.;}
  // 壳层：前面一层、后面一层
  vec2 hh=sphere(ro,rd,vec3(0),SH);
  vec3 front=vec3(0);float occ=0.;
  if(hh.x>0.){
    for(int L=1;L>=0;L--){
      float tt=L==0?hh.x:hh.y;vec3 p=ro+rd*tt;vec3 n=normalize(p);vec3 nl=shellRot()*n;
      vec3 v=voronoi(nl*6.5);float cov=coverage(nl);
      float present=step(v.z,cov*1.05)*step(.025,v.y);
      float seam=smoothstep(.025,.0,v.y)*step(v.z,cov*1.05);
      if(L==1){ // 远侧壳层：从内部被照亮的背面（被太阳本体挡住的部分看不到）
        if(hs.x<0.||hs.x>tt){}
        float lit=present;vec3 inner=vec3(.9,.45,.15)*.6*(.4+.6*v.x);
        sun=mix(sun,inner*(hs.x>0.?0.:1.),lit*step(hs.x,0.));
      }else{
        float ndv=max(dot(n,-rd),0.);
        vec3 pc=vec3(.03,.028,.027)*(.4+.6*hash11(v.z*31.))*(.7+.3*fbm3(nl*40.));
        pc+=vec3(1.,.5,.2)*.08*pow(1.-ndv,2.)+vec3(.9,.5,.2)*.04*smoothstep(.2,.0,v.x);
        pc+=vec3(.6,.7,.8)*pow(1.-ndv,5.)*.3;                       // 金属边缘的反光
        vec2 lg=fract(nl.xy*120.);float lamp=step(.93,hash12(floor(nl.xy*120.)))*smoothstep(.3,0.,length(lg-.5));
        pc+=vec3(.5,.85,1.)*lamp*1.2;
        front=pc;occ=present;
        sun+=vec3(1.,.55,.2)*seam*2.2*(hs.x>0.?1.:.3);           // 缝隙里漏出的阳光
      }
    }
  }
  col+=corona*(1.-occ*.85);
  col=mix(col+sun,front,occ);
  col*=uC;
  fragColor=vec4(col,1.);
}

// ===== 镜头：雾中生长的有机巨构城市（光线步进 SDF）=====
// uA = 镜头上升进度；uB = 生长进度；uC = 从瞳孔的黑中淡入
uniform float uA,uB,uC,uD;
const float CELL=20.;
vec3 SUN=normalize(vec3(.15,.12,1.));

float grow(float h){return smoothstep(h*.55,h*.55+.45,uB);}

// 返回距离；m.x=塔 id，m.y=塔高，m.z=半径
float map(vec3 p,out vec3 m){
  vec2 cell=floor(p.xz/CELL);vec2 cc=(cell+.5)*CELL;
  float hs=hash12(cell);vec2 jit=(vec2(hash12(cell+7.1),hash12(cell+3.3))-.5)*5.;
  vec3 q=vec3(p.x-cc.x-jit.x,p.y,p.z-cc.y-jit.y);
  float H=(50.+260.*hs*hs)*(.15+.85*grow(hash12(cell+1.9)));
  float avenue=step(1.,abs(cell.x+.5))*step(.35,hash12(cell+11.)); // x=0 附近留出一条大道，部分单元空着
  float taper=1.-.55*sat(q.y/max(H,1.));
  float rad=(2.8+4.2*hash12(cell+5.))*taper*(1.+.22*sin(q.y*.11+hs*30.))*(1.+.06*sin(q.y*1.3+hs*9.));
  float d=length(q.xz)-rad;
  d=length(vec2(max(d,0.),max(q.y-H,0.)))+min(max(d,q.y-H),0.);
  d=mix(1e3,d,avenue);
  // 限制步长不越过单元边界（避免漏掉相邻单元的塔）
  vec2 f=fract(p.xz/CELL)*CELL;float bd=min(min(f.x,CELL-f.x),min(f.y,CELL-f.y))+.2;
  m=vec3(hs,H,rad);
  float g=p.y; // 地面
  m=vec3(hs,H,rad);
  return min(min(d*.8,bd),g);
}
vec3 gM;vec2 gCell;
float mapN(vec3 p){
  vec2 cell=floor(p.xz/CELL);float best=p.y;gM=vec3(0);gCell=vec2(-999.);
  for(int j=-1;j<=1;j++)for(int i=-1;i<=1;i++){vec2 c2=cell+vec2(i,j);if(abs(c2.x+.5)<1.||hash12(c2+11.)<.35)continue;
    vec2 cc=(c2+.5)*CELL;float hs=hash12(c2);vec2 jit=(vec2(hash12(c2+7.1),hash12(c2+3.3))-.5)*5.;
    vec3 q=vec3(p.x-cc.x-jit.x,p.y,p.z-cc.y-jit.y);float H=(50.+260.*hs*hs)*(.15+.85*grow(hash12(c2+1.9)));
    float taper=1.-.55*sat(q.y/max(H,1.));float rad=(2.8+4.2*hash12(c2+5.))*taper*(1.+.22*sin(q.y*.11+hs*30.))*(1.+.06*sin(q.y*1.3+hs*9.));
    float d=length(q.xz)-rad;d=length(vec2(max(d,0.),max(q.y-H,0.)))+min(max(d,q.y-H),0.);
    if(d<best){best=d;gM=vec3(hs,H,rad);gCell=c2;}}
  return best*.8;}
float mapD(vec3 p){return mapN(p);}
vec3 nrm(vec3 p){vec2 e=vec2(.02,0);return normalize(vec3(mapD(p+e.xyy)-mapD(p-e.xyy),mapD(p+e.yxy)-mapD(p-e.yxy),mapD(p+e.yyx)-mapD(p-e.yyx)));}

vec3 skyCol(vec3 rd){
  float s=max(dot(rd,SUN),0.);
  vec3 c=mix(vec3(.35,.15,.07),vec3(.015,.02,.04),sat(rd.y*2.2));
  c+=vec3(1.,.55,.25)*pow(s,12.)*1.5+vec3(1.,.8,.5)*pow(s,300.)*30.;
  float cl=fbm(vec3(rd.xz/max(rd.y,.05)*1.2,uT*.03));c=mix(c,c*.55+vec3(.35,.18,.1)*pow(s,4.),smoothstep(.45,.75,cl)*sat(rd.y*4.));
  return c;
}
vec3 fogCol(vec3 rd){float s=max(dot(rd,SUN),0.);return mix(vec3(.03,.03,.04),vec3(.5,.2,.07),pow(s,7.))+vec3(1.,.55,.25)*pow(s,40.)*.6;}

// 光线到一条平行于 z 轴的直线的最近距离，用来画飞行器光带
float laneGlow(vec3 ro,vec3 rd,vec2 xy,float spd,float tmax,float seed){
  vec3 w=vec3(ro.x-xy.x,ro.y-xy.y,0.);vec3 D=vec3(0,0,1);
  float b=dot(rd,D),dd=dot(rd,w),e=dot(D,w);float den=1.-b*b;if(den<1e-4)return 0.;
  float tr=(b*e-dd)/den;if(tr<0.||tr>tmax)return 0.;float s=(e-b*dd)/den*-1.;
  vec3 pr=ro+rd*tr;float z=pr.z;
  float dist=length(vec2(pr.x-xy.x,pr.y-xy.y));
  float dash=smoothstep(.6,.95,fract(z*.05-uT*spd+seed))*step(.4,hash11(floor(z*.05-uT*spd+seed)+seed*13.));
  return exp(-dist*dist/(.012*tr*.02+.004))*dash/(1.+tr*.02)*smoothstep(15.,60.,tr);
}

void main(){
  vec2 uv=suv();
  float up=uA;
  vec3 ro=vec3(1.5,6.+up*150.,-60.+up*90.);
  float pitch=.12+up*.2;
  vec3 fw=normalize(vec3(0.,sin(pitch),cos(pitch)));vec3 rt=normalize(cross(vec3(0,1,0),fw));vec3 upv=cross(fw,rt);
  vec3 rd=normalize(fw*1.35+uv.x*rt+uv.y*upv);
  rd.xy*=rot(.03*sin(uT*.5));

  float t=0.;vec3 m;float hit=0.;
  for(int i=0;i<300;i++){vec3 p=ro+rd*t;float d=mapN(p);if(d<.0015*t+.01){hit=1.;break;}t+=d*(t>150.?1.15:1.);if(t>800.)break;}
  m=gM;vec2 hitCell=gCell;
  vec3 col;
  if(hit>.5){
    vec3 p=ro+rd*t;vec3 n=nrm(p);
    if(hitCell.x<-900.){ // 湿润地面
      col=vec3(.02,.02,.025)*(.5+.5*fbm3(vec3(p.xz*.3,0.)));
      col+=fogCol(reflect(rd,n))*.15*(1.-sat(t/300.));
    }else{
      vec2 cell=hitCell;float hs=m.x;float H=m.y;
      vec2 cc=(cell+.5)*CELL;vec2 jit=(vec2(hash12(cell+7.1),hash12(cell+3.3))-.5)*5.;
      vec2 lq=p.xz-cc-jit;float ang=atan(lq.y,lq.x);
      float dif=max(dot(n,SUN),0.),rim=pow(1.-max(dot(n,-rd),0.),3.);
      vec3 alb=mix(vec3(.03,.03,.035),vec3(.08,.07,.065),hash12(cell+2.));
      alb*=.6+.4*fbm3(vec3(ang*3.,p.y*.3,hs*10.));
      col=alb*(dif*vec3(1.,.6,.35)*1.2+vec3(.12,.1,.12))+rim*fogCol(rd)*.35;
      // 窗户：柱面网格
      vec2 wg=vec2(ang*m.z*2.4,p.y*1.6);vec2 wid=floor(wg);vec2 wf=fract(wg);
      float on=step(.78,hash12(wid+hs*100.))*smoothstep(220.,50.,t)*(.3+.7*step(.45,fbm3(vec3(wid*.15,hs*9.))))*step(.18,wf.x)*step(.25,wf.y)*step(wf.x,.82)*step(wf.y,.75);
      vec3 wc=mix(vec3(1.,.62,.3),vec3(.6,.85,1.),step(.8,hash12(wid*1.7)));
      col+=on*wc*1.1*(.4+.6*hash12(wid+3.));
      // 生物发光的纵向脉络（部分塔）
      if(hs>.55){float vein=smoothstep(.035,.0,abs(fract(ang/TAU*9.+p.y*.012)-.5))*smoothstep(260.,40.,t);col+=vein*vec3(.2,.9,1.)*1.2*(.6+.4*sin(p.y*.2-uT*3.));}
      // 正在生长的塔尖：纳米机器的亮带
      float gtip=exp(-pow((p.y-H)/1.2,2.))*(1.-grow(hash12(cell+1.9)))*step(.02,uB);
      col+=gtip*vec3(.4,.85,1.)*3.;
    }
    // 高度雾（解析积分）
    float a=.012,b=.03;
    float fog=sat(a/b*exp(-ro.y*b)*(1.-exp(-t*rd.y*b))/max(abs(rd.y),1e-3)*sign(rd.y+1e-5));
    fog=max(fog,1.-exp(-t*.0045));
    col=mix(col,fogCol(rd),fog);
  }else{
    col=skyCol(rd);
    float a=.022,b=.035;float fog=sat(a/b*exp(-ro.y*b)/max(rd.y,.02));
    col=mix(col,fogCol(rd),sat(fog)*.9);
  }
  // 飞行器光带（多条航道）
  float tmax=hit>.5?t:1e4;float lg=0.;
  for(int i=0;i<7;i++){float fi=float(i);vec2 xy=vec2((hash11(fi*3.1)-.5)*10.,8.+fi*9.+hash11(fi)*6.);lg+=laneGlow(ro,rd,xy,.4+hash11(fi*7.)*.8,tmax,fi);}
  col+=lg*vec3(1.,.75,.5)*3.;
  // 远处的空中巨构：一个悬在雾里的光环
  {vec3 c=vec3(0.,140.,420.);vec3 w=ro-c;float tt=-w.y/rd.y;if(tt>0.&&tt<tmax){vec3 pp=ro+rd*tt-c;float r=length(pp.xz);
    col+=vec3(.6,.85,1.)*exp(-pow((r-120.)/1.5,2.))*1.5*exp(-tt*.002);}}
  col*=uC;
  fragColor=vec4(col,1.);
}

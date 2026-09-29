// ===== 图层 C：俯视巨构城市 —— 塔顶群、金色雾海、长影、飞行器光带（单位：米）=====
uniform float uA,uB,uC,uD;
vec3 LS=normalize(vec3(.62,.16,.56));
const float CELL=140.,ROOF=22.,FOGY=-160.;
vec4 gT; // 最近塔的信息：x=id,y=顶高,z=半径,w=生长
float growOf(vec2 c){float h=hash12(c+9.);return h<.12?smoothstep(4.2+h*10.,6.6+h*10.,uT):1.;}
float towerD(vec3 p,vec2 c,out vec4 info){
  vec2 cc=(c+.5)*CELL;float hs=hash12(c);vec2 jit=(vec2(hash12(c+7.1),hash12(c+3.3))-.5)*30.;
  float top=-150.+320.*pow(hash12(c+2.),1.4);float rad=10.+20.*hash12(c+5.);
  if(c.x==-1.&&c.y==-1.){cc=vec2(0.);jit=vec2(0.);top=0.;rad=ROOF;}
  float g=growOf(c);top=mix(FOGY-20.,top,g);
  vec3 q=vec3(p.x-cc.x-jit.x,p.y,p.z-cc.y-jit.y);
  float r=rad*(1.+.1*sin(q.y*.04+hs*20.))*(1.+.35*smoothstep(top-10.,top-rad*3.,q.y)*step(.5,hs))*(1.+.25*smoothstep(top-rad*.6,top-rad*2.,q.y)*0.);
  float dome=length(vec2(max(length(q.xz)-r*.55,0.),max(q.y-top,0.)))-r*.45; // 圆润的顶
  float d=max(length(q.xz)-r,q.y-top-r*.35);d=min(d,dome);
  info=vec4(hs,top,r,g);return d;}
float map(vec3 p){vec2 c=floor((p.xz+vec2(CELL*.5))/CELL)-vec2(0.);c=floor(p.xz/CELL);float best=1e9;
  // 锚点塔所在单元为 (-1,-1)（中心在原点）
  for(int j=-1;j<=1;j++)for(int i=-1;i<=1;i++){vec2 c2=c+vec2(i,j);vec4 inf;
    if(hash12(c2+11.)<.8&&!(c2.x==-1.&&c2.y==-1.))continue;
    float d=towerD(p,c2,inf);if(d<best){best=d;gT=inf;}}
  // 锚点塔（总是存在，中心在原点）
  {vec4 inf;float d=towerD(p,vec2(-1.,-1.),inf);if(d<best){best=d;gT=inf;}}
  return best;}
vec3 nrm(vec3 p){vec2 e=vec2(.05,0);return normalize(vec3(map(p+e.xyy)-map(p-e.xyy),map(p+e.yxy)-map(p-e.yxy),map(p+e.yyx)-map(p-e.yyx)));}
float shadowT(vec3 ro){float t=2.;for(int i=0;i<40;i++){float h=map(ro+LS*t);if(h<.5)return 0.;t+=max(h,4.);if(t>3000.)break;}return 1.;}

float svoro(vec2 x,float k){vec2 p=floor(x),f=fract(x);float res=0.;
  for(int j=-1;j<=1;j++)for(int i=-1;i<=1;i++){vec2 b=vec2(i,j);vec2 o=vec2(hash12(p+b),hash12(p+b+17.3));
    float d=length(b+o-f);res+=exp(-k*d);}return -log(res)/k;}
float gFine=1.;
float fogH(vec2 x){float d1=svoro(x*.0055+uT*.01,7.),d2=svoro(x*.02+3.,7.);
  return 38.*fbm3(vec3(x*.0011,uT*.02))+(32.*smoothstep(.9,.0,d1)+0.*d2)*gFine+420.*fbm3(vec3(x*.00016,1.7))+3.*noise(vec3(x*.06,0.));}
vec3 fogShade(vec3 p,vec3 rd,float px){
  gFine=smoothstep(10.,3.,px);float e=max(2.,px*2.5);float h=fogH(p.xz);
  vec3 n=normalize(vec3(-(fogH(p.xz+vec2(e,0))-h)/e,1.,-(fogH(p.xz+vec2(0,e))-h)/e));
  float dif=max(dot(n,LS),0.);float back=pow(1.-max(dot(n,vec3(0,1,0)),0.),2.);
  float sh=shadowT(vec3(p.x,FOGY+h+6.,p.z));
  vec3 lit=vec3(1.,.5,.2)*1.35*(.3+.7*dif)*mix(.12,1.,sh);
  vec3 amb=vec3(.12,.12,.2)*.55;
  float val=fbm3(vec3(p.xz*.0025,5.));vec3 c=mix(vec3(.36,.33,.32),vec3(.46,.42,.4),val)*(lit+amb)+vec3(1.,.45,.2)*.18*back*sh;
  // 雾层下隐约透出的城市暖光
  float glow=smoothstep(.45,.85,fbm3(vec3(p.xz*.003,2.)))*smoothstep(40.,5.,h);
  c+=vec3(1.,.5,.2)*glow*.18;
  return c;}
float laneGlow(vec3 ro,vec3 rd,float tmax,float px){
  float g=0.;
  for(int i=0;i<6;i++){float fi=float(i);float y=-60.+fi*28.;float t=(y-ro.y)/rd.y;if(t<0.||t>tmax)continue;
    vec2 p=(ro+rd*t).xz;float a=hash11(fi*3.7)*PI;vec2 dir=vec2(cos(a),sin(a));vec2 nn=vec2(-dir.y,dir.x);
    float off=(hash11(fi*9.1)-.5)*1200.;float spacing=380.;
    float dl=dot(p,nn)-off;dl=dl-spacing*floor(dl/spacing+.5);
    float along=dot(p,dir)-uT*(60.+fi*25.)*(mod(fi,2.)*2.-1.);
    float w=max(.7,px*.9);float dash=smoothstep(.55,.95,fract(along/40.))*step(.35,hash11(floor(along/40.)+fi));
    g+=exp(-dl*dl/(w*w))*dash*min(1.,1.5/max(px,1.));}
  return g;}

void main(){
  vec2 uv=suv();float F=4.;
  vec3 ro=vec3(0.,.2+F*uS,0.);vec3 rd=normalize(vec3(uv.x,-F,uv.y));
  float px=uS/960.*(1.);
  float tF=(FOGY-ro.y)/rd.y;
  float t=0.;bool hit=false;
  for(int i=0;i<220;i++){vec3 p=ro+rd*t;float d=map(p);if(d<.0008*t+.02){hit=true;break;}t+=d*.9;if(t>tF)break;}
  vec3 col;float tmax=tF;
  if(hit&&t<tF){
    tmax=t;vec3 p=ro+rd*t;vec3 n=nrm(p);vec4 inf=gT;
    float sh=shadowT(p+n*1.);float dif=max(dot(n,LS),0.)*sh;
    float top=inf.y;float isTop=smoothstep(.5,.8,n.y);
    vec3 alb=mix(vec3(.035,.035,.04),vec3(.07,.065,.06),hash11(inf.x*17.));
    // 塔顶：花园、石材、光环
    vec3 v=voronoi(vec3(p.xz*2.6,0.));vec3 roofc=mix(vec3(.12,.11,.1),vec3(.2,.185,.165),v.z)*(.7+.4*fbm3(vec3(p.xz*.5,1.)));
    roofc=mix(roofc,vec3(.04,.08,.03),smoothstep(.5,.72,fbm3(vec3(p.xz*.08+inf.x*9.,4.)))*.9);
    alb=mix(alb,roofc,isTop);
    vec3 emi=vec3(0);
    float rloc=length(p.xz-(p.xz-vec2(0.)))*0.;
    // 侧面窗户
    float ang=atan(p.z,p.x);vec2 wg=vec2(ang*140.,p.y*.6);vec2 wid=floor(wg);
    emi+=(1.-isTop)*vec3(1.,.66,.35)*step(.86,hash12(wid+inf.x*50.))*.5*smoothstep(1.5,.3,px);
    // 塔顶边缘的光环 + 生长中的塔尖（纳米机器亮带）
    emi+=vec3(1.,.72,.42)*1.3*smoothstep(1.5,.0,abs(p.y-top+1.))*(1.-isTop*.6);
    emi+=vec3(.4,.85,1.)*5.*(1.-inf.w)*step(.02,inf.w)*smoothstep(8.,0.,abs(p.y-top));
    col=alb*(vec3(1.,.6,.34)*2.3*dif+vec3(.1,.14,.26)*.28*(.5+.5*n.y))+emi;
    col=mix(col,fogShade(ro+rd*tF,rd,px),smoothstep(.5,.12,inf.z/(px*40.)));
    // 远处塔体融入雾的颜色
    col=mix(col,fogShade(ro+rd*tF,rd,px)*.8,sat((FOGY+120.-p.y)/160.)*.8);
  }else{
    col=fogShade(ro+rd*tF,rd,px);
  }
  
  // 高空时加一层薄薄的大气
  col=mix(col,vec3(.55,.35,.25),sat(log(max(uS,1.))/log(10.)*.06-.12));
  fragColor=vec4(col,1.);
}

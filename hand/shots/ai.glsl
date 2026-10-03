// ===== 第 14 镜：AI 扩散模型“去噪”出一只手 =====
// uA = 去噪进度 0..1（离散成若干步）；uB = 是否第六指（最后 2 帧为 1）；uC = 总步数
uniform float uA,uB,uC,uD;

// 目标图像：棚拍质感的手（深色渐变背景、柔光、皮肤次表面散射感）
vec3 target(vec2 uv,float six,float blur){
  vec3 bg=mix(vec3(.004,.006,.015),vec3(.03,.03,.07),smoothstep(-1.,1.,uv.y))+vec3(.12,.06,.3)*.12*exp(-dot(uv-vec2(.3,.4),uv-vec2(.3,.4))*2.);
  float d=handSD(uv,six);
  float e=.004;float dx=handSD(uv+vec2(e,0),six)-d,dy=handSD(uv+vec2(0,e),six)-d;
  float hgt=sqrt(sat(-d/.1));vec3 n=normalize(vec3(-vec2(dx,dy)/e*(1.-hgt)*1.4,1.));
  vec3 L1=normalize(vec3(-.5,.6,.7)),L2=normalize(vec3(.8,-.1,.4));
  vec3 skin=vec3(.5,.29,.2);
  vec3 c=skin*(.06+1.25*pow(max(dot(n,L1),0.),1.5))*smoothstep(-1.1,.4,uv.y+uv.x*.3)+vec3(.45,.4,1.)*.5*pow(max(dot(n,L2),0.),3.);
  c+=vec3(.9,.3,.2)*.12*(1.-hgt);                 // 边缘的次表面红晕
  c*=.85+.15*fbm3(vec3(uv*40.,1.));
  float m=smoothstep(blur+.002,-blur-.002,d);
  return mix(bg,c,m);}

void main(){
  vec2 uv=suv();
  float steps=max(uC,1.);
  float k=floor(uA*steps+1e-4)/steps;            // 离散步数：画面一步一步地“跳”
  float sigma=pow(1.-k,1.6);                     // 噪声强度
  // 早期只有低频结构（模糊的色块），后期出现细节
  float blur=.25*sigma*sigma;
  vec3 x0=target(uv,uB,blur);
  // 潜空间噪声：彩色、块状（4px 的块）、每一步都重新采样
  vec2 cell=floor(gl_FragCoord.xy/4.);float step_=floor(uA*steps);
  vec3 nz=hash33(vec3(cell,step_*7.31))-.5;
  vec3 nz2=hash33(vec3(floor(gl_FragCoord.xy/16.),step_*3.1))-.5;
  vec3 noiseCol=nz*1.4+nz2*.8+.5;
  vec3 col=mix(x0,noiseCol,sigma*.95);
  // 每一步切换时，画面轻微闪一下
  col*=1.+.15*smoothstep(.06,0.,fract(uA*steps));
  fragColor=vec4(col,1.);
}

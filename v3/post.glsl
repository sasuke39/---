// ===== 后期：两路镜头混合 + 泛光 + ACES + 色差 + 暗角 + 颗粒 =====
uniform sampler2D uTa,uTb;
uniform float uMix,uExpo,uFlash;
vec3 bloom(sampler2D t,vec2 uv){vec3 b=vec3(0);float w=0.;
  for(int i=2;i<8;i++){float fi=float(i);float ww=1./(1.+fi*.6);b+=textureLod(t,uv,fi).rgb*ww;w+=ww;}return b/w;}
vec3 samp(sampler2D t,vec2 uv){vec2 d=(uv-.5)*.0025;return vec3(texture(t,uv+d).r,texture(t,uv).g,texture(t,uv-d).b);}
vec3 aces(vec3 x){return clamp((x*(2.51*x+.03))/(x*(2.43*x+.59)+.14),0.,1.);}
void main(){
  vec2 uv=gl_FragCoord.xy/uRes;
  vec3 a=samp(uTa,uv)+bloom(uTa,uv)*.35;
  vec3 c=a;
  if(uMix>0.){vec3 b=samp(uTb,uv)+bloom(uTb,uv)*.35;float r=length((uv-.5)*vec2(uRes.x/uRes.y,1.))*2.;float m=smoothstep(0.,1.,uMix*1.9-r*.75);c=mix(a,b,m);}
  c*=uExpo;
  c+=vec3(uFlash);
  c=aces(c);
  float v=length((uv-.5)*vec2(1.,1.3));c*=mix(1.,.55,smoothstep(.35,.95,v));
  c=pow(c,vec3(1./2.2));
  float g=hash13(vec3(gl_FragCoord.xy,floor(uT*30.)))-.5;c+=g*.035;
  fragColor=vec4(c,1.);
}

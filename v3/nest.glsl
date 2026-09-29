// 尺度嵌套合成：外层 uTa，内层 uTb 只在半径 uR（屏幕单位）以内显示，边缘柔和过渡
uniform sampler2D uTa,uTb;
uniform float uR,uAlpha;
void main(){
  vec2 uv=gl_FragCoord.xy/uRes;vec2 s=suv();float r=length(s);
  vec3 a=texture(uTa,uv).rgb,b=texture(uTb,uv).rgb;
  float m=(1.-smoothstep(uR*.55,uR*.95,r))*uAlpha;
  fragColor=vec4(mix(a,b,m),1.);
}

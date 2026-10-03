uniform float uA,uB,uC,uD;
void main(){vec2 uv=suv();float d=handSD(uv-vec2(-.3,0.)*0.,0.);float d6=handSD(uv,1.);
  vec3 c=vec3(.05);c=mix(c,vec3(.9),smoothstep(.003,-.003,uv.x<0.?handSD(uv*1.+vec2(.0,0.),0.):d6));fragColor=vec4(c,1.);}

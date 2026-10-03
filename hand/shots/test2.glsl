uniform float uA,uB,uC,uD;
void main(){vec2 uv=suv();vec3 c=vec3(.05);c=mix(c,vec3(.9),smoothstep(.003,-.003,handSD(uv,uA)));fragColor=vec4(c,1.);}

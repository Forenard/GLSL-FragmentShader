mat2 c=rotate2D(t);vec3 d=vec3((FC.xy*2.-r)/r.y,-2)/2.,p,a,q,k;a+=.25;p.z+=5.;float i,e,n,f;p.xz*=c;d.xz*=c;for(;++i<24.;e<.001?o+=.4/i:o-=d.x*.01){q=p;e=1e6;n=0.;while(n++<8.){q.xy=abs(q.xy);q-=.2;q.xy*=c;q.yz*=c;q.zx*=c;e=min(length(q-clamp(q,-a,a)),e);}p+=d*e;}
precision highp float;

uniform vec2 resolution;
uniform vec2 mouse;
uniform float time;

vec3 C_pos=vec3(0,0,3);
vec3 C_dir=vec3(0,0,-1);
vec3 C_up=vec3(0,1,0);
vec3 L_dir=vec3(-0.57, 0.57, 0.57);
float targetDepth = 1.;
float PI=3.14159265;

#define NUM_OCTAVES 3
#define NUM_TEX 12

vec3 rot(vec3 p, float angle, vec3 axis){
    vec3 a = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float r = 1.0 - c;
    mat3 m = mat3(
        a.x * a.x * r + c,
        a.y * a.x * r + a.z * s,
        a.z * a.x * r - a.y * s,
        a.x * a.y * r - a.z * s,
        a.y * a.y * r + c,
        a.z * a.y * r + a.x * s,
        a.x * a.z * r + a.y * s,
        a.y * a.z * r - a.x * s,
        a.z * a.z * r + c
    );
    return m * p;
}

highp float random(vec2 co){
    highp float a = 12.9898;
    highp float b = 78.233;
    highp float c = 43758.5453;
    highp float dt= dot(co.xy ,vec2(a,b));
    highp float sn= mod(dt,3.14);
    return fract(sin(sn) * c);
}


highp float noise(in vec2 st)
{
    vec2 i = floor(st);
    vec2 f = fract(st);
    float a = random(i + vec2(0.0, 0.0));
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3. - 2. * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1. - u.x) + (d - b) * u.x * u.y;
}

float fbm(in vec2 st)
{
    float v = .0;
    float a = .5;
    for (int i = 0; i < NUM_OCTAVES; i++)
    {
        v += a * noise(st);
        st = st * 4.5;
        a *= .5;
    }

    return v;
}

float domainWarp(vec2 st){
    vec2 q = vec2(0.);
    q.x = fbm(st + vec2(0.));
    q.y = fbm(st + vec2(1.));
    vec2 r = vec2(0.);
    r.x = fbm(st + (4. * q) + vec2(4.7, 6.3) + (0.15));
    r.y = fbm(st + (4. * q) + vec2(2.1, 5.9) + (0.12));
    float f = fbm(st + 4.0 * r);
	float res=f * f * f + (0.6 * f * f) + (0.5 * f);
    return fract(res);
}

vec3 dup(vec3 p){
	vec3 q=p;
	q.xz=mod(p.xz,12.)-6.;
  return q;
}

float heightFunc(vec3 p){
	
	return min(p.y+noise(p.xz),p.y+noise(p.xz));
}

float boxFunc(vec3 p){
  vec3 vera=vec3(-3.,-3.,-3.);
  vec3 verb=vec3(3.,1200.,3.);
  vec3 offset=vec3(0,0,0);
  float edge=.02;
	
  vec3 q=dup(p);
	q=rot(q,time+q.y*0.5,vec3(0,1,0));
  q-=offset;
  return length(q)-length(clamp(q,vera,verb))-edge;
}


float distFunc(vec3 p){
    return min(boxFunc(p),heightFunc(p));
}

vec3 genNormal(vec3 p){
    float d = 0.001;
    return normalize(vec3(
        distFunc(p + vec3(  d, 0.0, 0.0)) - distFunc(p + vec3( -d, 0.0, 0.0)),
        distFunc(p + vec3(0.0,   d, 0.0)) - distFunc(p + vec3(0.0,  -d, 0.0)),
        distFunc(p + vec3(0.0, 0.0,   d)) - distFunc(p + vec3(0.0, 0.0,  -d))
    ));
}

vec3 tex(vec2 p){
	float ar=atan(p.y,p.x)+PI;
	ar*=1.;
	float a=length(p);
	vec2 q=normalize(p);
	float s=abs(5.*sin(time))+1.;
	float d=floor(ar*3.*s)*.3/s;
	float u=d+.2;
	vec3 t=(d<a&&a<u)?vec3(fract(d*5.+time),fract(d+time),fract(d*11.+time)):vec3(0.);
	//float t =smoothstep(.4,.5,a)*smoothstep(.4,.5,1.-a);
	return t;
}

void main()
{
	float i = sin(time*3.);
	C_pos=vec3(time*15.,sin(time)+6.,.0);
	C_dir=vec3(cos(time),0,sin(time/2.));
	C_dir=normalize(C_dir);
	C_up=rot(C_up,time,-C_dir);
	C_up=normalize(C_up);
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);
    vec3 C_side = cross(C_dir,C_up);
  vec3 ray = normalize(C_side*p.x+C_up*p.y +C_dir*targetDepth);
	if(i<.0){
		float randx=random(vec2(floor(time*30.)));
		float randy=random(vec2(floor(time*30.+.256)));
		p+=vec2(randx,randy)*.2;
	}
  float tmp, dist;
  tmp = 0.0;
  vec3 D_pos = C_pos;
  for(int i = 0; i < 64; i++){
      dist = distFunc(D_pos);
      tmp += dist;
      D_pos = C_pos + tmp * ray;
  }
    
  vec3 color=vec3(1.);
	
  if(abs(dist) < 0.001){
      vec3 normal = genNormal(D_pos);
      float diff = clamp(dot(L_dir, normal), 0.1, 1.0);
	  float fog=clamp(10./length(D_pos-C_pos),0.,1.);
	  vec3 mixed=mix(vec3(.8, .3, .2),vec3(.2,.5,1.),diff);
      color *= 1.5*mixed*fog;
  }else{
      vec2 v = vec2(0.0, 1.0);
	p.y+=.05;
	float t = dot(p, v);
	  
	  vec3 mixed=mix(vec3(.6,.6,.2),vec3(.2,.6,.6),t);
	color=p.y<0.?mix(vec3(.8, .3, .2),vec3(.2,.5,1.),p.y+1.):mixed;
	  float bloom=clamp(10./length(D_pos-C_pos),0.,1.);
	  color*=vec3(.6,.2,.2)*bloom*15.;
  }
	color=clamp(color,vec3(0.),vec3(1.));
	//color*=clamp(vec3(cos(time),sin(time*1.5+1.5),sin(time/2.)),vec3(.7),vec3(1.));
	
	
	
	color=(i<.0)?vec3(1.)-1.5*color:color;
	
	if(i<.0){
		for(int j=0;j<NUM_TEX;j++){
			float a=length(p);
			float ar=atan(p.y,p.x)+float(j)*2.*PI/float(NUM_TEX)+float(j)*time;
			ar=random(vec2(floor(float(j)*time)))*2.*PI;
			vec2 q=a*vec2(cos(ar),sin(ar));
			color+=.7*tex(q);
		}
	}
	
  gl_FragColor = vec4(color, 1.0);
}
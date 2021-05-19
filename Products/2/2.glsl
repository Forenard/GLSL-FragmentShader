//for https://twigl.app/ as classic
precision highp float;
uniform vec2 resolution;
uniform vec2 mouse;
uniform float time;
uniform sampler2D backbuffer;

vec3 C_pos=vec3(0,1,0);
vec3 C_dir=vec3(0,-.5,-1);
vec3 C_up=vec3(0,1,0);
vec3 L_dir=vec3(-.57,.57,.57);
vec3 L_pos=vec3(0,3,0);
float L_int=100.;
float targetDepth=1.;
const float PI=3.14159265;
const float angle=70.;
const float fov=angle*.5*PI/180.;

mat3 rotate3D(float angle,vec3 axis){
  vec3 a=normalize(axis);
  float s=sin(angle);
  float c=cos(angle);
  float r=1.-c;
  return mat3(
    a.x*a.x*r+c,
    a.y*a.x*r+a.z*s,
    a.z*a.x*r-a.y*s,
    a.x*a.y*r-a.z*s,
    a.y*a.y*r+c,
    a.z*a.y*r+a.x*s,
    a.x*a.z*r+a.y*s,
    a.y*a.z*r-a.x*s,
    a.z*a.z*r+c
  );
}

vec3 dup(vec3 p){
  return mod(p,4.)-2.;
}

float distFuncBox(vec3 p){
  vec3 vera=vec3(-.5);
  vec3 verb=vec3(.5);
  vec3 offset=vec3(0,0,0);
  float edge=.02;
  
  vec3 q=dup(p);
  q-=offset;
  return length(q)-length(clamp(q,vera,verb))-edge;
}

float distFuncFloor(vec3 p){
  return dot(p,vec3(0.,1.,0.))+1.;
}

float distFunc(vec3 p){
  return distFuncBox(p);
}

vec3 genNormal(vec3 p){
  float d=.0001;
  return normalize(vec3(
      distFunc(p+vec3(d,0.,0.))-distFunc(p+vec3(-d,0.,0.)),
      distFunc(p+vec3(0.,d,0.))-distFunc(p+vec3(0.,-d,0.)),
      distFunc(p+vec3(0.,0.,d))-distFunc(p+vec3(0.,0.,-d))
    ));
  }
  
  void rotCam(){
    C_pos=vec3(cos(time),3.+sin(time),sin(time*.54));
    C_dir=normalize(vec3(0,3,0)-C_pos);
    C_up=rotate3D(90.*.5*PI/180.,vec3(0,0,1.))*C_dir;
  }
  
  void main(){
    rotCam();
    vec2 p=(gl_FragCoord.xy*2.-resolution)/max(resolution.x,resolution.y);
    vec3 C_side=cross(C_dir,C_up);
    vec3 ray=normalize(sin(fov)*C_side*p.x+sin(fov)*C_up*p.y+C_dir*(targetDepth-cos(fov)));
    
    float tmp,dist;
    tmp=0.;
    vec3 D_pos=C_pos;
    for(int i=0;i<256;i++){
      dist=distFunc(D_pos);
      tmp+=dist;
      D_pos=C_pos+tmp*ray;
    }
    
    vec3 color;
    if(abs(dist)<.001){
      float l=mod(floor(length(D_pos)),12.)/12.;
      vec3 normal=genNormal(D_pos);
      float diff=L_int*clamp(dot(normalize(D_pos-L_pos),normal),.1,1.)/length(D_pos-L_pos);
      color=vec3(l,.4,.5)*diff;
    }else{
      color=vec3(.8,.3,.5);
    }
    gl_FragColor=vec4(color,1.);
  }
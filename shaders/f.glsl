#version 330

uniform vec2 resolution;
uniform vec3 ro;
uniform vec3 rot;

void pR(inout vec2 p, float a) {
	p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

struct Hit {
    float dist;
    int iter;
};


float Union(float a, float b) {
    return min(a, b);
}

float Substract(float a, float b) {
    return max(-a, b);
}

float Intersect(float a, float b) {
    return max(a, b);
}

float SoftUnion(float a, float b, float k) {
    k *= 2.0;
    float x = b-a;
    return 0.5*( a+b-sqrt(x*x+k*k) );
}



float sphere(vec3 p, vec3 position, float radius) {
    return length(p-position) - radius;
}

float box(vec3 p, vec3 position, vec3 size) {
  vec3 q = abs(p-position) - size;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float torus(vec3 p, vec3 position, vec2 size)
{
  vec2 q = vec2(length((p-position).xz)-size.x,(p-position).y);
  return length(q)-size.y;
}


float plane(vec3 p, float position) {
    return p.y - position;
}

float map(vec3 p) {
    // float sphere1 = sphere(p, vec3(0, 0, 0), 1.3);
    // float box1 = box(p, vec3(0, 0, 0), vec3(1, 1, 1));
    // float torus1 = torus(p, vec3(0, 0, 0), vec2(1.2, 0.2));
    // float plane = plane(p, 0);


    // float SphereXBox = Substract(sphere1, box1);
    // float TorusXPrevious = SoftUnion(torus1, SphereXBox, 0.1);
    // float PlaneXPrevious = Substract(TorusXPrevious, plane);

    float sphere1 = sphere(p, vec3(2, 0, 0), 1.3);
    float box1 = box(p, vec3(-2, 0, 0), vec3(1, 1, 1));
    float torus1 = torus(p, vec3(0, 4, 0), vec2(1.2, 0.2));
    float plane = plane(p, -2);


    float SphereXBox = Union(sphere1, box1);
    float TorusXPrevious = Union(torus1, SphereXBox);
    float PlaneXPrevious = Union(TorusXPrevious, plane);

    float Final = PlaneXPrevious;

    return Final;
}

Hit RayMarch(vec3 ro, vec3 rd){
    float hit = 0;
    float object=0;
    int it = 0;
    for (int i = 0; i < 256; i++) {
        it = i;
        vec3 p = ro + object * rd;
        hit = map(p);
        object += hit;
        if (abs(hit) < 0.01 || object > 500) break;
    }
    return Hit(object, it);
}

vec3 getLight(vec3 p, vec3 rd, vec3 n) {
    vec3 lightPos = vec3(10.0, 55.0, -20.0);
    vec3 L = normalize(lightPos - p);
    vec3 V = -rd;
    vec3 R = reflect(-L, n);

    vec3 specColor = vec3(0.5);
    vec3 specular = specColor * pow(clamp(dot(R, V), 0.0, 1.0), 10.0);
    vec3 diffuse = vec3(clamp(dot(L, n), 0.0, 1.0));
    vec3 ambient = vec3(0.05);
    vec3 fresnel = vec3(0.25 * pow(1.0 + dot(rd, n), 3.0));

    float d = RayMarch(p + n * 0.02, normalize(lightPos)).dist;
    if (d < length(lightPos - p)) return ambient + fresnel;

    return diffuse + ambient + specular + fresnel;
}

vec3 getNormal(vec3 p) {
    vec2 e = vec2(0.01, 0.0);
    vec3 n = vec3(map(p)) - vec3(map(p - e.xyy), map(p - e.yxy), map(p - e.yyx));
    return normalize(n);
}

void main(){
    vec2 uv = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec3 color = vec3(0, 0, 0);

    vec3 rd = normalize(vec3(uv, 1));

    pR(rd.yz, rot.x);
    pR(rd.xz, rot.y);
    pR(rd.xy, rot.z);

    Hit hit = RayMarch(ro, rd);
    float dist = hit.dist;
    vec3 p = ro + rd * dist;
    vec3 n = getNormal(p);

    if (dist < 256.0) {
        color = getLight(p, rd, n);
    }

    gl_FragColor = vec4(pow(color, vec3(1/2.2)), 1);
}
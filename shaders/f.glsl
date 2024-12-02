#version 330

uniform vec2 resolution;
uniform vec3 ro;
uniform vec3 rot;

const int MAX_STEPS = 256;
const float MAX_DIST = 500;
const float EPSILON = 0.001;

void pR(inout vec2 p, float a) {
	p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

struct Shape {
    vec3 position;
    vec3 size;
    vec3 color;
    int type;
    float dist;
};

struct Hit {
    float dist;
    int iter;
    vec3 color;
};

Shape Union(Shape a, Shape b) {
    return (a.dist < b.dist) ? a : b;
}

Shape Intersect(Shape a, Shape b) {
    return (a.dist < b.dist) ? b : a;
}

Shape Substract(Shape a, Shape b) {
    return (-a.dist < b.dist) ? b : a;
}

Shape SoftUnion(Shape a, Shape b, float k) {
    float h = clamp( 0.5+0.5*(b.dist-a.dist)/k, 0.0, 1.0 );

    float blendDst = mix( b.dist, a.dist, h ) - k*h*(1.0-h);
    vec3 blendCol = mix(b.color,a.color,h);
    return Shape(b.position, b.size, blendCol, b.type, blendDst);;
}



float sphereDist(vec3 p, vec3 position, float radius) {
    return length(p-position) - radius;
}

float boxDist(vec3 p, vec3 position, vec3 size) {
  vec3 q = abs(p-position) - size;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float torusDist(vec3 p, vec3 position, vec2 size)
{
  vec2 q = vec2(length((p-position).xz)-size.x,(p-position).y);
  return length(q)-size.y;
}

float planeDist(vec3 p, float position) {
    return p.y - position;
}

float shapeDist(Shape s, vec3 p) {
    if (s.type == 0) return sphereDist(p, s.position, s.size.x);
    if (s.type == 1) return boxDist(p, s.position, s.size);
    if (s.type == 2) return torusDist(p, s.position, s.size.xy);
    if (s.type == 3) return planeDist(p, s.position.y);
}

Shape map(vec3 p) {
    Shape sphere = Shape(vec3(0, 3, 0), vec3(1.3), vec3(1, 0, 0), 0, 0);
    sphere.dist = shapeDist(sphere, p);

    Shape box = Shape(vec3(0, 0, 0), vec3(1, 1, 1), vec3(0, 0, 1), 1, 0);
    box.dist = shapeDist(box, p);

    Shape torus = Shape(vec3(0, 4, 0), vec3(4, 0.6, 0), vec3(0, 1, 0), 2, 0);
    torus.dist = shapeDist(torus, p);

    Shape plane = Shape(vec3(0, -1, 0), vec3(0), vec3(1, 1, 1), 3, 0);
    plane.dist = shapeDist(plane, p);

    Shape sphere_X_box = SoftUnion(sphere, box, 2);
    Shape previous_X_torus = Union(sphere_X_box, torus);
    Shape previous_X_plane = Union(previous_X_torus, plane);

    return previous_X_plane;
}

Hit RayMarch(vec3 ro, vec3 rd){
    Shape hit = Shape(vec3(0, 0, 0), vec3(0, 0, 0), vec3(0, 0, 0), 0, 0);
    Hit object=Hit(0, 0, vec3(0));
    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + object.dist * rd;
        hit = map(p);
        object.dist += hit.dist;
        object.color = hit.color;
        object.iter = i;
        if (abs(hit.dist) < EPSILON || object.dist > MAX_DIST) break;
    }
    return object;
}

vec3 getLight(vec3 p, vec3 rd, vec3 n, vec3 color) {
    vec3 lightPos = vec3(10.0, 55.0, -20.0);
    vec3 L = normalize(lightPos - p);
    vec3 V = -rd;
    vec3 R = reflect(-L, n);

    vec3 specColor = vec3(0.5);
    vec3 specular = specColor * pow(clamp(dot(R, V), 0.0, 1.0), 10.0);
    vec3 diffuse = color * vec3(clamp(dot(L, n), 0.0, 1.0));
    vec3 ambient = color * vec3(0.05);
    vec3 fresnel = color *  vec3(0.25 * pow(1.0 + dot(rd, n), 3.0));

    float d = RayMarch(p + n * 0.02, normalize(lightPos)).dist;
    if (d < length(lightPos - p)) return ambient + fresnel;

    return diffuse + ambient + specular + fresnel;
}

vec3 getNormal(vec3 p) {
    vec2 e = vec2(EPSILON, 0.0);
    vec3 n = vec3(map(p).dist) - vec3(map(p - e.xyy).dist, map(p - e.yxy).dist, map(p - e.yyx).dist);
    return normalize(n);
}

void main(){
    vec2 uv = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec3 color = vec3(0.0, 0.5, 1.0);

    vec3 rd = normalize(vec3(uv, 1));

    pR(rd.yz, rot.x);
    pR(rd.xz, rot.y);
    pR(rd.xy, rot.z);

    Hit hit = RayMarch(ro, rd);
    float dist = hit.dist;
    vec3 p = ro + rd * dist;
    vec3 n = getNormal(p);

    if (dist < MAX_DIST) {
        color = getLight(p, rd, n, hit.color);
        color = mix(color, vec3(0.0, 0.5, 1.0), 1.0-exp(-0.00008 * dist * dist));
    }
    else {
        color -= max(0.4 * rd.y, 0.0);
    }

    gl_FragColor = vec4(pow(color, vec3(1/2.2)), 1);
}
#version 330 core

uniform vec2 resolution;
uniform vec3 ro;
uniform vec3 rot;

const int MAX_STEPS = 128;
const float MAX_DIST = 128;
const float EPSILON = 0.01;

void pR(inout vec2 p, float a) {
	p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

struct Shape {
    vec3 position;
    vec3 rotation;
    vec3 size;
    vec3 color;
    vec3 type;
    int combinationType;
    float dist;
};

const int SHAPES_AMOUNT = 6;
uniform Shape shapes[SHAPES_AMOUNT];

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
    a.dist = max(a.dist, -b.dist);
    if (a.dist <= -b.dist) {
        a.color = b.color;
    }
    return a;
}

Shape SoftUnion(Shape a, Shape b, float k) {
    float h = clamp( 0.5+0.5*(b.dist-a.dist)/k, 0.0, 1.0 );

    float blendDst = mix( b.dist, a.dist, h ) - k*h*(1.0-h);
    vec3 blendCol = mix(b.color,a.color,h);
    b.color = blendCol;
    b.dist = blendDst;

    return b;
}

Shape SoftIntersect(Shape a, Shape b, float k) {
    float h = clamp( 0.5-0.5*(b.dist-a.dist)/k, 0.0, 1.0 );

    float blendDst = mix( b.dist, a.dist, h ) - k*h*(1.0-h);
    vec3 blendCol = mix(b.color,a.color,h);
    b.color = blendCol;
    b.dist = blendDst;

    return b;
}

Shape SoftSubstract(Shape a, Shape b, float k) {
    float h = clamp( 0.5-0.5*(a.dist+b.dist)/k, 0.0, 1.0 );

    float blendDst = mix( a.dist, -b.dist, h ) + k*h*(1.0-h);
    vec3 blendCol = mix(a.color,b.color,h);
    b.color = blendCol;
    b.dist = blendDst;

    return b;
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

vec3 transformP(vec3 p, vec3 rot){
    vec3 finalP = p;

    pR(finalP.yz, rot.x);
    pR(finalP.xz, rot.y);
    pR(finalP.xy, rot.z);

    return finalP;
}

float shapeDist(Shape s, vec3 p) {
    if (s.type.y == 0) p = transformP(p, s.rotation);

    if (s.type.x == 0) return sphereDist(p, s.position, s.size.x);
    if (s.type.x == 1) return boxDist(p, s.position, s.size);
    if (s.type.x == 2) return torusDist(p, s.position, s.size.xy);
    if (s.type.x == 3) return planeDist(p, s.position.y);
}
Shape shapeCombination(Shape a, Shape b) {
    if (b.combinationType == 0) return Union(a, b);
    if (b.combinationType == 1) return Intersect(a, b);
    if (b.combinationType == 2) return Substract(a, b);
    if (b.combinationType == 3) return SoftUnion(a, b, 0.8);
    if (b.combinationType == 4) return SoftIntersect(a, b, 0.8);
    if (b.combinationType == 5) return SoftSubstract(a, b, 0.8);
}

Shape map(vec3 p) {

    Shape previousShape = shapes[0];
    previousShape.dist = shapeDist(previousShape, p);

    for (int i = 1; i < SHAPES_AMOUNT; i++) {
        Shape nowShape = shapes[i];
        nowShape.dist = shapeDist(nowShape, p);
        previousShape = shapeCombination(previousShape, nowShape);
    }

    Shape final_shape = previousShape;

    return final_shape;
}

Hit RayMarch(vec3 ro, vec3 rd){
    Shape hit;
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

vec3 getNormal(vec3 p) {
    vec2 e = vec2(EPSILON, 0.0);
    vec3 n = vec3(map(p).dist) - vec3(map(p - e.xyy).dist, map(p - e.yxy).dist, map(p - e.yyx).dist);
    return normalize(n);
}
float getAmbientOcclusion(vec3 p, vec3 normal) {
    float occ = 0.0, weight = 1.0;
    for (int i = 0; i < 8; i++) {
        float len = 0.01 + 0.02 * float(i * i);
        occ += (len - map(p + normal * len).dist) * weight;
        weight *= 0.85;
    }
    return 1.0 - clamp(0.6 * occ, 0.0, 1.0);
}
float getSoftShadow(vec3 p, vec3 lightPos) {
    float res = 1.0, dist = 0.01, lightSize = 0.03, maxDist = 60.0;
    for (int i = 0; i < MAX_STEPS && dist < maxDist; i++) {
        float hit = map(p + lightPos * dist).dist;
        res = min(res, hit / (dist * lightSize));
        dist += hit;
        if (hit < 0.0001) break;
    }
    return clamp(res, 0.0, 1.0);
}
vec3 getLight(vec3 p, vec3 rd, vec3 color) {
    vec3 lightPos = vec3(20.0, 55.0, -25.0);
    vec3 L = normalize(lightPos - p);
    vec3 N = getNormal(p);
    vec3 V = -rd;
    vec3 R = reflect(-L, N);

    float NdotL = dot(N, L);
    float RdotV = clamp(dot(R, V), 0.0, 1.0);
    float shadow = getSoftShadow(p + N * 0.02, normalize(lightPos));
    float occ = getAmbientOcclusion(p, N);

    vec3 specular = 1.3 * vec3(0.6, 0.5, 0.4) * pow(RdotV, 10.0);
    vec3 diffuse = 0.9 * color * clamp(NdotL, 0.0, 1.0);
    vec3 ambient = 0.05 * color;
    vec3 fresnel = 0.15 * color * pow(1.0 + dot(rd, N), 3.0);

    return (0.05 * color * clamp(dot(N, -L), 0.0, 1.0) + ambient + fresnel) * occ + (specular * occ + diffuse) * shadow;
}

void main(){
    vec2 uv = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;

    vec3 rd = normalize(vec3(uv, 1));
    vec3 color = vec3(0.0, 0.5, 1.0)-max(0.4 * rd.y, 0.0);

    pR(rd.yz, rot.x);
    pR(rd.xz, rot.y);

    Hit hit = RayMarch(ro, rd);
    float dist = hit.dist;
    vec3 p = ro + rd * dist;

    if (dist < MAX_DIST) 
        color = getLight(p, rd, hit.color);
    

    gl_FragColor = vec4(pow(color, vec3(1/2.2)), 1);
}

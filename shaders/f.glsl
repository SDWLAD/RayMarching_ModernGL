#version 330

uniform vec2 resolution;
uniform vec3 ro;

struct Hit {
    float dist;
    int iter;
};

float smin( float a, float b, float k )
{
    k *= 2.0;
    float x = b-a;
    return 0.5*( a+b-sqrt(x*x+k*k) );
}

vec3 light(vec3 n, int i, vec3 ro, vec3 p) {
    vec3 lightDir = normalize(vec3(1, 1, -1));
    float diffuse = max(dot(n, lightDir), 0.0);
    vec3 col = vec3(diffuse);

    float occ = (float(i) / 512.0);
    occ = 1 - occ;
    occ *= occ;
    col *= occ;

    float fog = length(p - ro);
    fog /= 256;
    fog = clamp(fog, 0, 1);
    fog *= fog;
    col = col * (1 - fog) + 0.1 * fog;

    return col;
}

float sphere(vec3 p, vec3 position, float radius) {
    return length(p-position) - radius;
}

float box(vec3 p, vec3 position, vec3 size) {
  vec3 q = abs(p-position) - size;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float plane(vec3 p, float position) {
    return p.y - position;
}

float map(vec3 p) {
    float sphere1 = sphere(p, vec3(-1.5, 0, 0), 1.0);
    float box1 = box(p, vec3(1.5, 0, 0), vec3(1, 1, 1));
    float plane = plane(p, -2);
    return min(plane, smin(sphere1, box1, 0.5));
}

Hit RayMarch(vec3 ro, vec3 rd){
    float hit, object;
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

vec3 getNormal(vec3 p) {
    vec2 e = vec2(0.01, 0.0);
    vec3 n = vec3(map(p)) - vec3(map(p - e.xyy), map(p - e.yxy), map(p - e.yyx));
    return normalize(n);
}

void main(){
    vec2 uv = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec3 color = vec3(0, 0, 0);

    vec3 rd = normalize(vec3(uv, 1));

    Hit hit = RayMarch(ro, rd);
    float dist = hit.dist;
    vec3 p = ro + rd * dist;
    vec3 n = getNormal(p);

    if (dist < 256.0) {
        color = light(n, hit.iter, ro, p);
    }

    gl_FragColor = vec4(color, 1);
}
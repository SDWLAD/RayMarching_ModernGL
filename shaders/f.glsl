#version 330

uniform vec2 resolution;

vec3 light(vec3 n) {
    vec3 lightDir = normalize(vec3(1, 1, -1));

    float diffuse = max(dot(n, lightDir), 0.0);

    return vec3(diffuse);
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
    return min(plane, min(sphere1, box1));
}

float RayMarch(vec3 ro, vec3 rd){
    float hit, object;
    for (int i = 0; i < 256; i++) {
        vec3 p = ro + object * rd;
        hit = map(p);
        object += hit;
        if (abs(hit) < 0.01 || object > 500) break;
    }
    return object;
}

vec3 getNormal(vec3 p) {
    vec2 e = vec2(0.01, 0.0);
    vec3 n = vec3(map(p)) - vec3(map(p - e.xyy), map(p - e.yxy), map(p - e.yyx));
    return normalize(n);
}

void main(){
    vec2 uv = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec3 color = vec3(0, 0, 0);

    vec3 ro = vec3(0, 2, -5);
    vec3 rd = normalize(vec3(uv, 1));

    float dist = RayMarch(ro, rd);
    vec3 p = ro + rd * dist;
    vec3 n = getNormal(p);

    if (dist < 256.0) {
        color = light(n);
    }

    gl_FragColor = vec4(color, 1);
}
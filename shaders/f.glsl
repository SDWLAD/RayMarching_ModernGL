#version 330

uniform vec2 resolution;

float RayMarch(vec3 ro, vec3 rd){
    float hit, object;
    for (int i = 0; i < 256; i++) {
        vec3 p = ro + object * rd;
        hit = length(p)-1.0;
        object += hit;
        if (abs(hit) < 0.01 || object > 500) break;
    }
    return object;
}

void main(){
    vec2 uv = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec3 color = vec3(0, 0, 0);

    vec3 ro = vec3(0, 0, -5);
    vec3 rd = normalize(vec3(uv, 1));

    float dist = RayMarch(ro, rd);

    if (dist < 256.0) {
        color = vec3(1, 1, 1);
    }

    gl_FragColor = vec4(color, 1);
}
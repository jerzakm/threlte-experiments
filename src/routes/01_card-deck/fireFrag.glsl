uniform float time;
uniform sampler2D card;
uniform sampler2D frameArea;
uniform sampler2D monster;
uniform vec4 resolution;
varying vec2 vUv;

vec3 rgb2hsv(vec3 c) {
  vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
  vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
  vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

  float d = q.x - min(q.w, q.y);
  float e = 1.0e-10;
  return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
  vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float rand(vec2 n) {
  return fract(sin(cos(dot(n, vec2(12.9898, 12.1414)))) * 83758.5453);
}

float noise(vec2 n) {
  const vec2 d = vec2(0.0, 1.0);
  vec2 b = floor(n), f = smoothstep(vec2(0.0), vec2(1.0), fract(n));
  return mix(mix(rand(b), rand(b + d.yx), f.x), mix(rand(b + d.xy), rand(b + d.yy), f.x), f.y);
}

float fbm(vec2 n) {
  float total = 0.0, amplitude = 1.0;
  for(int i = 0; i < 5; i++) {
    total += noise(n) * amplitude;
    n += n * 1.7;
    amplitude *= 0.47;
  }
  return total;
}

void main() {

  vec4 cardColor = texture2D(card, vUv).rgba;
  vec4 frameArea = texture2D(frameArea, vUv).rgba;
  vec4 monster = texture2D(monster, vUv * 1.).rgba;

  if(frameArea.a > 0.) {

    const vec3 c1 = vec3(0.5, 0.0, 0.1);
    const vec3 c2 = vec3(0.9, 0.1, 0.0);
    const vec3 c3 = vec3(0.2, 0.1, 0.7);
    const vec3 c4 = vec3(1.0, 0.9, 0.1);
    const vec3 c5 = vec3(0.1);
    const vec3 c6 = vec3(0.9);
    vec2 speed = vec2(0., 1.);
    float shift = 1.327 + sin(time * 2.0) / 2.4;

    vec2 p = vUv;
    p *= 4.;
    p.x -= time / 2.1;
    float q = fbm(p - time * 0.01 + 1.0 * sin(time) / 10.0);
    float q3 = fbm(p - time * 0.9 - 10.0 * cos(time) / 30.0) - 4.0;
    q = q3 / 3.8;
    vec2 r = vec2(fbm(p + q / 2.0 + time * speed.x - p.x - p.y), fbm(p + q - time * speed.y));
    vec3 c = mix(c1, c2, fbm(p + r)) + mix(c3, c4, r.x) - mix(c5, c6, r.y);
    vec3 color = vec3(c * cos(shift * vUv.y / resolution.y));
    color += .05;
    color.r *= .8;
    vec3 hsv = rgb2hsv(color);
    hsv.y *= hsv.z * 1.1;
    hsv.z *= hsv.y * 1.13;
    hsv.y = (2.2 - hsv.z * .9) * 1.20;
    // hsv.x += 0.71; tint
    color = hsv2rgb(hsv);
    color *= 0.9;

    color = mix(color, cardColor.rgb, cardColor.a);

    if(monster.a > 0.5) {
      color = monster.rgb;
    }

    gl_FragColor = vec4(color.x, color.y, color.z, 1.);
    return;
  } else {
    gl_FragColor = vec4(cardColor * 1.25);
  }

}
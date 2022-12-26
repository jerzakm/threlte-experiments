varying vec2 vUv;
uniform float iTime;
uniform float opacity;
uniform vec3 iResolution;

#define SEED1 (1.705)
#define SEED2 (1.379)
#define DMUL 8.12235325

vec2 stepnoise(vec2 p, float size) {
  p += 10.0;
  float x = floor(p.x / size) * size;
  float y = floor(p.y / size) * size;

  x = fract(x * 0.1) + 1.0 + x * 0.0002;
  y = fract(y * 0.1) + 1.0 + y * 0.0003;

  float a = fract(1.0 / (0.000001 * x * y + 0.00001));
  a = fract(1.0 / (0.000001234 * a + 0.00001));

  float b = fract(1.0 / (0.000002 * (x * y + x) + 0.00001));
  b = fract(1.0 / (0.0000235 * b + 0.00001));

  return vec2(a, b);

}

float poly(float a, float b, float c, float ta, float tb, float tc) {
  return (a * ta + b * tb + c * tc) / (ta + tb + tc);
}
float mask(vec2 p) {
  vec2 r = stepnoise(p, 5.5) - 0.5;
  p[0] += r[0] * DMUL;
  p[1] += r[1] * DMUL;

  float f = fract(p[0] * SEED1 + p[1] / (SEED1 + 0.15555)) * 1.03;
  return poly(pow(f, 150.0), f * f, f, 1.0, 0.0, 1.3);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = vUv * iResolution.xy;
  float niceNoise = mask(vUv * 3000.);
  float basicNoise = (float((9 * int(fragCoord.x) + 5 * int(fragCoord.y)) % 11) + 0.5) / 11.0;

  fragColor = vec4(vec3(niceNoise), 1.);
}

void main() {
  mainImage(gl_FragColor, gl_FragCoord.xy);
}
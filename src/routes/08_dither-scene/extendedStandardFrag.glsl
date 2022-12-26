lowp vec4 permute(in lowp vec4 x) {
  return mod(x * x * 34. + x, 289.);
}
lowp float snoise(in mediump vec3 v) {
  const lowp vec2 C = vec2(0.16666666666, 0.33333333333);
  const lowp vec4 D = vec4(0, .5, 1, 2);
  lowp vec3 i = floor(C.y * (v.x + v.y + v.z) + v);
  lowp vec3 x0 = C.x * (i.x + i.y + i.z) + (v - i);
  lowp vec3 g = step(x0.yzx, x0);
  lowp vec3 l = (1. - g).zxy;
  lowp vec3 i1 = min(g, l);
  lowp vec3 i2 = max(g, l);
  lowp vec3 x1 = x0 - i1 + C.x;
  lowp vec3 x2 = x0 - i2 + C.y;
  lowp vec3 x3 = x0 - D.yyy;
  i = mod(i, 289.);
  lowp vec4 p = permute(permute(permute(i.z + vec4(0., i1.z, i2.z, 1.)) + i.y + vec4(0., i1.y, i2.y, 1.)) + i.x + vec4(0., i1.x, i2.x, 1.));
  lowp vec3 ns = .142857142857 * D.wyz - D.xzx;
  lowp vec4 j = -49. * floor(p * ns.z * ns.z) + p;
  lowp vec4 x_ = floor(j * ns.z);
  lowp vec4 x = x_ * ns.x + ns.yyyy;
  lowp vec4 y = floor(j - 7. * x_) * ns.x + ns.yyyy;
  lowp vec4 h = 1. - abs(x) - abs(y);
  lowp vec4 b0 = vec4(x.xy, y.xy);
  lowp vec4 b1 = vec4(x.zw, y.zw);
  lowp vec4 sh = -step(h, vec4(0));
  lowp vec4 a0 = b0.xzyw + (floor(b0) * 2. + 1.).xzyw * sh.xxyy;
  lowp vec4 a1 = b1.xzyw + (floor(b1) * 2. + 1.).xzyw * sh.zzww;
  lowp vec3 p0 = vec3(a0.xy, h.x);
  lowp vec3 p1 = vec3(a0.zw, h.y);
  lowp vec3 p2 = vec3(a1.xy, h.z);
  lowp vec3 p3 = vec3(a1.zw, h.w);
  lowp vec4 norm = inversesqrt(vec4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;
  lowp vec4 m = max(.6 - vec4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.);
  return .5 + 12. * dot(m * m * m, vec4(dot(p0, x0), dot(p1, x1), dot(p2, x2), dot(p3, x3)));
}
varying vec2 vUv;
varying vec3 vPosition;

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

float s(float x, float y, vec2 uv) {
  vec4 clr = vec4(diffuse, 1.);
  float f = clr[0] * 0.3 + clr[1] * 0.6 + clr[1] * 0.1;

  return f;
}
mat3 mynormalize(mat3 mat) {
  float sum = mat[0][0] + mat[0][1] + mat[0][2] + mat[1][0] + mat[1][1] + mat[1][2] + mat[2][0] + mat[2][1] + mat[2][2];
  return mat / sum;
}

void main() {
  vec3 pos3d = vPosition * 40.;
  float noise3d = snoise(pos3d);

  vec2 r = stepnoise(vUv, 6.0);  
  // vec4 clr = texture(iChannel0, fragCoord.xy / iResolution.xy);
  vec4 clr = vec4(diffuse, 1.);
  float f = clr[0] * 0.3 + clr[1] * 0.6 + clr[1] * 0.1;
  float d = 0.5;
  mat3 mat = mat3(vec3(d, d, d), vec3(d, 2.0, d), vec3(d, d, d));

  vec2 uv3 = vUv;

  float f1 = s(0.0, 0.0, vUv);
  mat = mynormalize(mat) * 1.0;
  f = s(-1.0, -1.0, uv3) * mat[0][0] + s(-1.0, 0.0, uv3) * mat[0][1] + s(-1.0, 1.0, uv3) * mat[0][2] + s(0.0, -1.0, uv3) * mat[1][0] + s(0.0, 0.0, uv3) * mat[1][1] + s(0.0, 1.0, uv3) * mat[1][2] + s(1.0, -1.0, uv3) * mat[2][0] + s(1.0, 0.0, uv3) * mat[2][1] + s(1.0, 1.0, uv3) * mat[2][2];

  f = (f - s(0.0, 0.0, uv3));
  f *= 80.0;
  f = f1 - f;

  float c = mask(vUv);
  c = float(f >= noise3d);

  // csm_DiffuseColor = vec4(vec3(c), 1.);
  csm_FragColor = vec4(vec3(c), 1.);
}
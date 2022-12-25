varying vec2 vUv;
varying vec3 vPosition;
uniform vec3 trailMaker;
uniform sampler2D trailA;
uniform sampler2D trailB;

vec3 sdgCircle(in vec2 p, in float r) {
  float d = length(p);
  return vec3(d - r, p / d);
}

void main() {

  vec3 color = vec3(vUv, vPosition.y);

  vec2 p = vUv - trailMaker.xy * 0.1 - 0.5;
  const float ra = 0.25;
  vec3 dg = sdgCircle(p, ra);
  float d = dg.x;
  vec2 g = dg.yz;

  vec3 col = (d > 0.0) ? vec3(0.0, 0.0, 0.0) : vec3(1.0, 1.0, 1.0);

  vec4 a = texture2D(trailA, vUv);
  vec4 b = texture2D(trailB, vUv);

  gl_FragColor = a;

}
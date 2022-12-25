varying vec2 vUv;
varying vec3 vPosition;
uniform vec3 trailMaker;
uniform sampler2D heightmap;
uniform sampler2D trail;

void main() {

  // vec3 a = texture2D(heightmap, vUv).rgb * vec3(1., 1., 1.);
  // vec3 a = texture2D(heightmap, vUv).rgb * vPosition;
  vec3 a = vec3(vPosition.rg, vPosition.b);

  gl_FragColor = vec4(a, 1.);

}
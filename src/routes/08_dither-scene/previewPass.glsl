uniform sampler2D tDiffuse;
uniform sampler2D uSceneTex;
varying vec2 vUv;
#include <common>

void main() {
  vec4 clr = texture2D(uSceneTex, vUv);
  gl_FragColor = vec4(clr.xyz, 1.0);
}
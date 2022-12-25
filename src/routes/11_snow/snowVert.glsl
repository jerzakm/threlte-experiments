varying vec2 vUv;
varying vec3 vPosition;
uniform vec3 trailMaker;

void main() {
  vUv = uv;
  vec4 modelViewPosition = modelViewMatrix * vec4(position, 1.0);
  gl_Position = projectionMatrix * modelViewPosition;
  vPosition = (modelMatrix * vec4(position, 1.0)).xyz;
}

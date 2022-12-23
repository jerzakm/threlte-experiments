varying vec2 vUv;
varying vec3 vPosition;
void main() {
  vUv = uv;
  vPosition = (modelMatrix * vec4(position, 1.0)).xyz;
}
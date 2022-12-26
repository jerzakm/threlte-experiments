uniform float translationX;
uniform float translationY;
uniform float translationZ;
uniform float scaleX;
uniform float scaleY;
uniform float scaleZ;
uniform float rotationX;
uniform float rotationY;
uniform float rotationZ;
varying vec2 vUv;
varying mat4 vPosition;
void main() {
  vUv = uv;
  mat4 tPos = mat4(vec4(1.0, 0.0, 0.0, 0.0), vec4(0.0, 1.0, 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(translationX, translationY, translationZ, 1.0));
  mat4 rXPos = mat4(vec4(1.0, 0.0, 0.0, 0.0), vec4(0.0, cos(rotationX), -sin(rotationX), 0.0), vec4(0.0, sin(rotationX), cos(rotationX), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
  mat4 rYPos = mat4(vec4(cos(rotationY), 0.0, sin(rotationY), 0.0), vec4(0.0, 1.0, 0.0, 0.0), vec4(-sin(rotationY), 0.0, cos(rotationY), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
  mat4 rZPos = mat4(vec4(cos(rotationZ), -sin(rotationZ), 0.0, 0.0), vec4(sin(rotationZ), cos(rotationZ), 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
  mat4 sPos = mat4(vec4(scaleX, 0.0, 0.0, 0.0), vec4(0.0, scaleY, 0.0, 0.0), vec4(0.0, 0.0, scaleZ, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
  vPosition = tPos * rXPos * rZPos * rYPos * sPos;
  gl_Position = projectionMatrix * modelViewMatrix * vPosition * vec4(position, 1.0);
}
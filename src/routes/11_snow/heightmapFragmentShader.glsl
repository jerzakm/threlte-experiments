#include <common>
uniform vec3[512] objects;
uniform float mouseSize;
uniform float intensity;

void main() {

  vec2 cellSize = 1.0 / resolution.xy;
  vec2 uv = gl_FragCoord.xy * cellSize;

  // heightmapValue.x == height from previous frame
  // heightmapValue.y == height from penultimate frame
  // heightmapValue.z, heightmapValue.w not used
  vec4 heightmapValue = texture2D(heightmap, uv);

  vec4 north = texture2D(heightmap, uv + vec2(0.0, cellSize.y));
  vec4 south = texture2D(heightmap, uv + vec2(0.0, -cellSize.y));
  vec4 east = texture2D(heightmap, uv + vec2(cellSize.x, 0.0));
  vec4 west = texture2D(heightmap, uv + vec2(-cellSize.x, 0.0));

  float change = 0.;

  int keepParsing = 1;

  int i = 0;

  while(keepParsing == 1) {
    vec3 trail = objects[i];

    float phase = max(2., clamp(length((uv - vec2(0.5)) * BOUNDS - vec2(trail.x, -trail.y)) * PI / trail.z * 0.5, 1.0, PI));
    change += (cos(phase) + 1.0) * intensity;
    i++;
    if(trail.z == 0.) {
      keepParsing = 0;
    }
    if(i == 511) {
      keepParsing = 0;
    }
  }

  if(change < 0.25) {
    change *= -1.;
  }
  float newHeight = (heightmapValue.y) * 0.9995;
  newHeight += change;

  newHeight = max(-2.5, newHeight);

  heightmapValue.y = heightmapValue.x;
  heightmapValue.x = newHeight;

  gl_FragColor = vec4(newHeight);

}
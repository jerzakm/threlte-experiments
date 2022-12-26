#include <common>

uniform vec2 mousePos;
uniform float mouseSize;
uniform float viscosityConstant;
uniform float heightCompensation;
uniform float intensity;

void main() {

  vec2 cellSize = 1.0 / resolution.xy;

  vec2 uv = gl_FragCoord.xy * cellSize;

  // heightmapValue.x == height from previous frame
  // heightmapValue.y == height from penultimate frame
  // heightmapValue.z, heightmapValue.w not used
  vec4 heightmapValue = texture2D(heightmap, uv);

  // Get neighbours
  vec4 north = texture2D(heightmap, uv + vec2(0.0, cellSize.y));
  vec4 south = texture2D(heightmap, uv + vec2(0.0, -cellSize.y));
  vec4 east = texture2D(heightmap, uv + vec2(cellSize.x, 0.0));
  vec4 west = texture2D(heightmap, uv + vec2(-cellSize.x, 0.0));

  // https://web.archive.org/web/20080618181901/http://freespace.virgin.net/hugo.elias/graphics/x_water.htm

  // Mouse influence
  float mousePhase = max(2., clamp(length((uv - vec2(0.5)) * BOUNDS - vec2(mousePos.x, -mousePos.y)) * PI * 2. / mouseSize * 1.1, 1.0, PI));

  float mousePhase2 = clamp(length((uv - vec2(0.5)) * BOUNDS - vec2(mousePos.x, -mousePos.y)) * PI / mouseSize * 0.5, 0.0, PI);

  float newHeight = (heightmapValue.y) * 0.9995;

  float change = (cos(mousePhase) + 1.0) * intensity;

  if(change < 0.25) {
    change *= -1.;
  }

  newHeight += change;

  if(mousePhase2 > 0.5 && mousePhase2 < 1.5) {

    // newHeight += mousePhase2;
  }

  newHeight = max(-2.5, newHeight);

  heightmapValue.y = heightmapValue.x;
  heightmapValue.x = newHeight;

  gl_FragColor = vec4(newHeight);

}
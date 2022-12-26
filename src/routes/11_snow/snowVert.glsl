varying vec2 vUv;
varying vec3 vPosition;
uniform vec3 trailMaker;
uniform sampler2D heightmap;

#include <common>
#include <uv_pars_vertex>
#include <uv2_pars_vertex>
#include <displacementmap_pars_vertex>
#include <envmap_pars_vertex>
#include <color_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <shadowmap_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>

void main() {
  float WIDTH = 512.;
  float BOUNDS = 512.;
  vUv = uv;
  vec2 cellSize = vec2(1.0 / WIDTH, 1.0 / WIDTH);

				#include <uv_vertex>
				#include <uv2_vertex>
				#include <color_vertex>

				// # include <beginnormal_vertex>
				// Compute normal from heightmap
  vec3 objectNormal = vec3((texture2D(heightmap, uv + vec2(-cellSize.x, 0)).x - texture2D(heightmap, uv + vec2(cellSize.x, 0)).x) * WIDTH / BOUNDS, (texture2D(heightmap, uv + vec2(0, -cellSize.y)).x - texture2D(heightmap, uv + vec2(0, cellSize.y)).x) * WIDTH / BOUNDS, 1.0);
				//<beginnormal_vertex>

				#include <morphnormal_vertex>
				#include <skinbase_vertex>
				#include <skinnormal_vertex>
				#include <defaultnormal_vertex>

				//# include <begin_vertex>
  float heightValue = texture2D(heightmap, uv).x;
  vec3 transformed = vec3(position.x, position.y, heightValue);
				//<begin_vertex>

				#include <morphtarget_vertex>
				#include <skinning_vertex>
				#include <displacementmap_vertex>
				#include <project_vertex>
				#include <logdepthbuf_vertex>
				#include <clipping_planes_vertex>

				#include <worldpos_vertex>
				#include <envmap_vertex>
				#include <shadowmap_vertex>
  vPosition = (modelMatrix * vec4(position, 1.0)).xyz - transformed;
}

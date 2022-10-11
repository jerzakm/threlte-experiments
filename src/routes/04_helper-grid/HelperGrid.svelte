<script lang="ts">
	import { DisposableObject, MeshInstance, useThrelte } from '@threlte/core';
	import { Color, PlaneGeometry, ShaderMaterial, DoubleSide, Mesh } from 'three';

	export let color = 'white';
	export let size1 = 10;
	export let size2 = 100;
	export let distance = 8000;
	export let axes = 'xzy';

	// https://github.com/Fyrestar/THREE.InfiniteGridHelper/blob/master/InfiniteGridHelper.js

	const { invalidate } = useThrelte();

	const makeGridMaterial = (axes: string) => {
		return new ShaderMaterial({
			side: DoubleSide,

			uniforms: {
				uSize1: {
					value: size1
				},
				uSize2: {
					value: size2
				},
				uColor: {
					value: new Color(color)
				},
				uDistance: {
					value: distance
				}
			},
			transparent: true,
			vertexShader: `
       
       varying vec3 worldPosition;
   
       uniform float uDistance;
       
       void main() {
       
            vec3 pos = position.${axes} * uDistance;
            pos.${planeAxes} += cameraPosition.${planeAxes};
            
            worldPosition = pos;
            
            gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
       
       }
       `,

			fragmentShader: `
       
       varying vec3 worldPosition;
       
       uniform float uSize1;
       uniform float uSize2;
       uniform vec3 uColor;
       uniform float uDistance;
        
        
        
        float getGrid(float size) {
        
            vec2 r = worldPosition.${planeAxes} / size;
            
            
            vec2 grid = abs(fract(r - 0.5) - 0.5) / fwidth(r);
            float line = min(grid.x, grid.y);
            
        
            return 1.0 - min(line, 1.0);
        }
        
       void main() {
       
            
              float d = 1.0 - min(distance(cameraPosition.${planeAxes}, worldPosition.${planeAxes}) / uDistance, 1.0);
            
              float g1 = getGrid(uSize1);
              float g2 = getGrid(uSize2);
              
              
              gl_FragColor = vec4(uColor.rgb, mix(g2, g1, g1) * pow(d, 3.0));
              gl_FragColor.a = mix(0.5 * gl_FragColor.a, gl_FragColor.a, g2);
            
              if ( gl_FragColor.a <= 0.0 ) discard;
            
       
       }
       
       `,

			extensions: {
				derivatives: true
			}
		});
	};

	const planeAxes = axes.slice(0, 2);

	const geometry = new PlaneGeometry(2, 2, 1, 1);
	const material = makeGridMaterial(axes);

	const mesh = new Mesh(geometry, material);
	mesh.frustumCulled = false;

	$: mesh.material = makeGridMaterial(axes);

	$: updateUniforms(color, size1, size2, distance);

	const updateUniforms = (color: string, size1: number, size2: number, distance: number) => {
		material.uniforms.uSize1 = { value: size1 };
		material.uniforms.uSize2 = { value: size2 };
		material.uniforms.uColor = { value: new Color(color) };
		material.uniforms.uDistance = { value: distance };
		invalidate('Updating helper grid uniforms');
	};
</script>

<DisposableObject object={mesh} />
<MeshInstance {mesh} />

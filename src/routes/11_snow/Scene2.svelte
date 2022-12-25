<script lang="ts">
	const heightmapFragmentShader = `#include <common>

  uniform vec2 mousePos;
  uniform float mouseSize;
  uniform float viscosityConstant;
  uniform float heightCompensation;

  void main()	{

    vec2 cellSize = 1.0 / resolution.xy;

    vec2 uv = gl_FragCoord.xy * cellSize;

    // heightmapValue.x == height from previous frame
    // heightmapValue.y == height from penultimate frame
    // heightmapValue.z, heightmapValue.w not used
    vec4 heightmapValue = texture2D( heightmap, uv );

    // Get neighbours
    vec4 north = texture2D( heightmap, uv + vec2( 0.0, cellSize.y ) );
    vec4 south = texture2D( heightmap, uv + vec2( 0.0, - cellSize.y ) );
    vec4 east = texture2D( heightmap, uv + vec2( cellSize.x, 0.0 ) );
    vec4 west = texture2D( heightmap, uv + vec2( - cellSize.x, 0.0 ) );

    // https://web.archive.org/web/20080618181901/http://freespace.virgin.net/hugo.elias/graphics/x_water.htm

    

    // Mouse influence
    float mousePhase = max(2.,clamp( length( ( uv - vec2( 0.5 ) ) * BOUNDS - vec2( mousePos.x, - mousePos.y ) ) * PI / mouseSize*1.1 , 1.0, PI ));
    
    float mousePhase2 = clamp( length( ( uv - vec2( 0.5 ) ) * BOUNDS - vec2( mousePos.x, - mousePos.y ) ) * PI / mouseSize*0.5, 0.0, PI );
    

    float newHeight = ( heightmapValue.y ) * 0.999;

    float change = ( cos( mousePhase ) + 1.0 ) * 0.28;


    if(change<0.25){
      change *= -1.;
    }

    newHeight += change;

    if(mousePhase2> 0.5 && mousePhase2< 1.5){

      // newHeight += mousePhase2;
    }
    

    newHeight = max(-50., newHeight);

    heightmapValue.y = heightmapValue.x;
    heightmapValue.x = newHeight;

    gl_FragColor = vec4(newHeight);

  }`;

	const smoothFragmentShader = `uniform sampler2D smoothTexture;
  void main()	{

    vec2 cellSize = 1.0 / resolution.xy;

    vec2 uv = gl_FragCoord.xy * cellSize;

    // Computes the mean of texel and 4 neighbours
    vec4 textureValue = texture2D( smoothTexture, uv );
    textureValue += texture2D( smoothTexture, uv + vec2( 0.0, cellSize.y ) );
    textureValue += texture2D( smoothTexture, uv + vec2( 0.0, - cellSize.y ) );
    textureValue += texture2D( smoothTexture, uv + vec2( cellSize.x, 0.0 ) );
    textureValue += texture2D( smoothTexture, uv + vec2( - cellSize.x, 0.0 ) );

    textureValue /= 5.0;

    gl_FragColor = textureValue;

  }`;

	const readWaterLevelFragmentShader = `uniform vec2 point1;

uniform sampler2D levelTexture;

// Integer to float conversion from https://stackoverflow.com/questions/17981163/webgl-read-pixels-from-floating-point-render-target

float shift_right( float v, float amt ) {

  v = floor( v ) + 0.5;
  return floor( v / exp2( amt ) );

}

float shift_left( float v, float amt ) {

  return floor( v * exp2( amt ) + 0.5 );

}

float mask_last( float v, float bits ) {

  return mod( v, shift_left( 1.0, bits ) );

}

float extract_bits( float num, float from, float to ) {

  from = floor( from + 0.5 ); to = floor( to + 0.5 );
  return mask_last( shift_right( num, from ), to - from );

}

vec4 encode_float( float val ) {
  if ( val == 0.0 ) return vec4( 0, 0, 0, 0 );
  float sign = val > 0.0 ? 0.0 : 1.0;
  val = abs( val );
  float exponent = floor( log2( val ) );
  float biased_exponent = exponent + 127.0;
  float fraction = ( ( val / exp2( exponent ) ) - 1.0 ) * 8388608.0;
  float t = biased_exponent / 1.0;
  float last_bit_of_biased_exponent = fract( t ) * 2.0;
  float remaining_bits_of_biased_exponent = floor( t );
  float byte4 = extract_bits( fraction, 0.0, 8.0 ) / 255.0;
  float byte3 = extract_bits( fraction, 8.0, 16.0 ) / 255.0;
  float byte2 = ( last_bit_of_biased_exponent * 128.0 + extract_bits( fraction, 16.0, 23.0 ) ) / 255.0;
  float byte1 = ( sign * 128.0 + remaining_bits_of_biased_exponent ) / 255.0;
  return vec4( byte4, byte3, byte2, byte1 );
}

void main()	{

  vec2 cellSize = 1.0 / resolution.xy;

  float waterLevel = texture2D( levelTexture, point1 ).x;

  vec2 normal = vec2(
    ( texture2D( levelTexture, point1 + vec2( - cellSize.x, 0 ) ).x - texture2D( levelTexture, point1 + vec2( cellSize.x, 0 ) ).x ) * WIDTH / BOUNDS,
    ( texture2D( levelTexture, point1 + vec2( 0, - cellSize.y ) ).x - texture2D( levelTexture, point1 + vec2( 0, cellSize.y ) ).x ) * WIDTH / BOUNDS );

  if ( gl_FragCoord.x < 1.5 ) {

    gl_FragColor = encode_float( waterLevel );

  } else if ( gl_FragCoord.x < 2.5 ) {

    gl_FragColor = encode_float( normal.x );

  } else if ( gl_FragCoord.x < 3.5 ) {

    gl_FragColor = encode_float( normal.y );

  } else {

    gl_FragColor = encode_float( 0.0 );

  }

}`;

	const waterVertexShader = `
			uniform sampler2D heightmap;

			#define PHONG

			varying vec3 vViewPosition;

			#ifndef FLAT_SHADED

				varying vec3 vNormal;

			#endif

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

				vec2 cellSize = vec2( 1.0 / WIDTH, 1.0 / WIDTH );

				#include <uv_vertex>
				#include <uv2_vertex>
				#include <color_vertex>

				// # include <beginnormal_vertex>
				// Compute normal from heightmap
				vec3 objectNormal = vec3(
					( texture2D( heightmap, uv + vec2( - cellSize.x, 0 ) ).x - texture2D( heightmap, uv + vec2( cellSize.x, 0 ) ).x ) * WIDTH / BOUNDS,
					( texture2D( heightmap, uv + vec2( 0, - cellSize.y ) ).x - texture2D( heightmap, uv + vec2( 0, cellSize.y ) ).x ) * WIDTH / BOUNDS,
					1.0 );
				//<beginnormal_vertex>

				#include <morphnormal_vertex>
				#include <skinbase_vertex>
				#include <skinnormal_vertex>
				#include <defaultnormal_vertex>

			#ifndef FLAT_SHADED // Normal computed with derivatives when FLAT_SHADED

				vNormal = normalize( transformedNormal );

			#endif

				//# include <begin_vertex>
				float heightValue = texture2D( heightmap, uv ).x;
				vec3 transformed = vec3( position.x, position.y, heightValue );
				//<begin_vertex>

				#include <morphtarget_vertex>
				#include <skinning_vertex>
				#include <displacementmap_vertex>
				#include <project_vertex>
				#include <logdepthbuf_vertex>
				#include <clipping_planes_vertex>

				vViewPosition = - mvPosition.xyz;

				#include <worldpos_vertex>
				#include <envmap_vertex>
				#include <shadowmap_vertex>

			}`;

	import * as THREE from 'three';
	import { GPUComputationRenderer } from 'three/examples/jsm/misc/GPUComputationRenderer.js';
	import { SimplexNoise } from 'three/examples/jsm/math/SimplexNoise.js';
	import { OrbitControls, useFrame, useThrelte, T, useTexture } from '@threlte/core';

	import CustomShaderMaterial from 'three-custom-shader-material/vanilla';
	import { MeshStandardMaterial, PlaneGeometry, SphereGeometry, Vector2 } from 'three';
	import { Environment } from '@threlte/extras';
	import { decodeTerrainFromTile, genMartiniTerrain } from '$lib/martiniTerrain';
	import type { BufferGeometry } from 'three';
	import { ShaderMaterial } from 'three';
	import { DoubleSide } from 'three';

	import { default as fragmentShader } from './snowFrag.glsl?raw';
	import { default as vertexShader } from './snowVert.glsl?raw';
	import { DEG2RAD } from 'three/src/math/MathUtils';
	import { AutoColliders, Collider, RigidBody, World } from '@threlte/rapier';

	let playerPosition = [0, 0, 0];

	// animate();

	// Texture width for simulation
	const WIDTH = 512;

	// Water size in system units
	const BOUNDS = 512;

	let container, stats;
	let camera, scene, renderer;
	let mouseMoved = false;
	const mouseCoords = new THREE.Vector2();
	const raycaster = new THREE.Raycaster();

	let waterMesh;
	let meshRay;
	let gpuCompute;
	let heightmapVariable;
	let waterUniforms;
	let smoothShader;
	let readWaterLevelShader;
	let readWaterLevelRenderTarget;
	let readWaterLevelImage;
	const waterNormal = new THREE.Vector3();

	const NUM_SPHERES = 5;
	const spheres = [];
	let spheresEnabled = true;

	const simplex = new SimplexNoise();

	const ctx = useThrelte();
	init();
	function init() {
		// camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 1, 3000);
		// camera.position.set(0, 200, 350);
		// camera.lookAt(0, 0, 0);

		scene = new THREE.Scene();

		const sun = new THREE.DirectionalLight(0xffffff, 1.0);
		sun.position.set(300, 400, 175);
		scene.add(sun);

		const sun2 = new THREE.DirectionalLight(0x40a040, 0.2);
		sun2.position.set(-20, 20, -20);
		scene.add(sun2);

		renderer = ctx.renderer;

		const effectController = {
			mouseSize: 20.0,
			viscosity: 0.98,
			spheresEnabled: spheresEnabled
		};

		const valuesChanger = function () {
			heightmapVariable.material.uniforms['mouseSize'].value = effectController.mouseSize;
			heightmapVariable.material.uniforms['viscosityConstant'].value = effectController.viscosity;
		};

		initWater();

		valuesChanger();
	}

	function initWater() {
		const materialColor = 0xffffff;

		const geometry = new THREE.PlaneGeometry(BOUNDS, BOUNDS, WIDTH - 1, WIDTH - 1);

		const material = new THREE.ShaderMaterial({
			uniforms: THREE.UniformsUtils.merge([
				THREE.ShaderLib['phong'].uniforms,
				{
					heightmap: { value: null }
				}
			]),
			vertexShader: waterVertexShader,
			fragmentShader: THREE.ShaderChunk['meshphong_frag']
		});

		material.lights = true;

		// Material attributes from THREE.MeshPhongMaterial
		material.color = new THREE.Color(materialColor);
		material.specular = new THREE.Color(0x111111);
		material.shininess = 50;

		material.normalScale = new Vector2(1);

		// Sets the uniforms with the material values
		material.uniforms['diffuse'].value = material.color;
		material.uniforms['specular'].value = material.specular;
		material.uniforms['shininess'].value = Math.max(material.shininess, 1e-4);
		material.uniforms['opacity'].value = material.opacity;

		material.uniforms['normalScale'].value = material.normalScale;

		// Defines
		material.defines.WIDTH = WIDTH.toFixed(1);
		material.defines.BOUNDS = BOUNDS.toFixed(1);

		waterUniforms = material.uniforms;

		waterMesh = new THREE.Mesh(geometry, material);
		waterMesh.rotation.x = -Math.PI / 2;
		waterMesh.matrixAutoUpdate = false;
		waterMesh.updateMatrix();

		scene.add(waterMesh);

		// THREE.Mesh just for mouse raycasting
		const geometryRay = new THREE.PlaneGeometry(BOUNDS, BOUNDS, 1, 1);
		meshRay = new THREE.Mesh(
			geometryRay,
			new THREE.MeshBasicMaterial({ color: 0xffffff, visible: false })
		);
		meshRay.rotation.x = -Math.PI / 2;
		meshRay.matrixAutoUpdate = false;
		meshRay.updateMatrix();
		scene.add(meshRay);

		// Creates the gpu computation class and sets it up

		gpuCompute = new GPUComputationRenderer(WIDTH, WIDTH, renderer);

		if (renderer.capabilities.isWebGL2 === false) {
			gpuCompute.setDataType(THREE.HalfFloatType);
		}

		const heightmap0 = gpuCompute.createTexture();

		fillTexture(heightmap0);

		heightmapVariable = gpuCompute.addVariable('heightmap', heightmapFragmentShader, heightmap0);

		gpuCompute.setVariableDependencies(heightmapVariable, [heightmapVariable]);

		heightmapVariable.material.uniforms['mousePos'] = { value: new THREE.Vector2(10000, 10000) };
		heightmapVariable.material.uniforms['mouseSize'] = { value: 20.0 };
		heightmapVariable.material.uniforms['viscosityConstant'] = { value: 0.98 };
		heightmapVariable.material.uniforms['heightCompensation'] = { value: 0 };
		heightmapVariable.material.defines.BOUNDS = BOUNDS.toFixed(1);

		const error = gpuCompute.init();
		if (error !== null) {
			console.error(error);
		}

		// Create compute shader to smooth the water surface and velocity
		smoothShader = gpuCompute.createShaderMaterial(smoothFragmentShader, {
			smoothTexture: { value: null }
		});

		// Create compute shader to read water level
		readWaterLevelShader = gpuCompute.createShaderMaterial(readWaterLevelFragmentShader, {
			point1: { value: new THREE.Vector2() },
			levelTexture: { value: null }
		});
		readWaterLevelShader.defines.WIDTH = WIDTH.toFixed(1);
		readWaterLevelShader.defines.BOUNDS = BOUNDS.toFixed(1);

		// Create a 4x1 pixel image and a render target (Uint8, 4 channels, 1 byte per channel) to read water height and orientation
		readWaterLevelImage = new Uint8Array(4 * 1 * 4);

		readWaterLevelRenderTarget = new THREE.WebGLRenderTarget(4, 1, {
			wrapS: THREE.ClampToEdgeWrapping,
			wrapT: THREE.ClampToEdgeWrapping,
			minFilter: THREE.NearestFilter,
			magFilter: THREE.NearestFilter,
			format: THREE.RGBAFormat,
			type: THREE.UnsignedByteType,
			depthBuffer: false
		});
	}

	function fillTexture(texture) {
		const pixels = texture.image.data;
		let p = 0;
		for (let j = 0; j < WIDTH; j++) {
			for (let i = 0; i < WIDTH; i++) {
				const x = (i * 128) / WIDTH;
				const y = (j * 128) / WIDTH;

				// pixels[p + 0] = noise(x, y);
				pixels[p + 0] = 0;
				// pixels[p + 1] = pixels[p + 0];
				pixels[p + 1] = 0;
				pixels[p + 2] = 0;
				pixels[p + 3] = 1;
				p += 4;
			}
		}
	}

	function setMouseCoords(x, y) {
		mouseCoords.set(
			(x / renderer.domElement.clientWidth) * 2 - 1,
			-(y / renderer.domElement.clientHeight) * 2 + 1
		);
		mouseMoved = true;
	}

	function onPointerMove(event) {
		if (event.isPrimary === false) return;
		setMouseCoords(event.layerX, event.layerY);
	}

	ctx.renderer?.domElement.addEventListener('mousemove', onPointerMove);
	const cam = ctx.camera;

	const snowMaterial = new ShaderMaterial({
		fragmentShader,
		vertexShader,
		side: DoubleSide,
		uniforms: {
			trail: {
				value: null
			},
			heightmap: { value: null }
		}
	});

	const terrainMaterial = new CustomShaderMaterial({
		baseMaterial: THREE.MeshStandardMaterial,
		vertexShader: `
        varying vec2 vUv;
        varying vec3 vPosition;
        uniform sampler2D heightmap;
        void main() {
            vUv = uv;
            float tColor = texture2D(heightmap, vec2(vUv.x, 1.-vUv.y)).x;  
            vPosition = (modelMatrix * vec4(position, 1.0)).xyz;
            csm_Position = vec3(position.x, position.y + tColor*1., position.z);
        }
    `,
		fragmentShader: `
        uniform sampler2D heightmap;
        varying vec3 vPosition;
        varying vec2 vUv;
        void main() {
            // float heightValue = texture2D(heightmap, vUv).x;
            float tColor = texture2D(heightmap, vec2(vUv.x, 1.-vUv.y)).x;            
            vec3 tColorMod = vec3(min(0.5,-tColor*0.1));
            csm_DiffuseColor = vec4(diffuse-tColorMod, 1.);
            // csm_DiffuseColor = vec4(vUv, 1.,1.);
        }
    `,

		uniforms: {
			trail: {
				value: null
			},
			heightmap: { value: null }
		},

		color: 0xceceef,
		wireframe: false
	});

	let terrainMesh: THREE.Mesh;

	function render() {
		// Set uniforms: mouse interaction
		const uniforms = heightmapVariable.material.uniforms;
		if (mouseMoved) {
			raycaster.setFromCamera(mouseCoords, $cam);

			// const intersects = raycaster.intersectObject(meshRay);
			const intersects = raycaster.intersectObject(terrainMesh);

			if (intersects.length > 0) {
				const point = intersects[0].point;
				playerPosition = [point.x, point.y - 0.5, point.z];
				uniforms['mousePos'].value.set(point.x - BOUNDS, point.z);
			} else {
				uniforms['mousePos'].value.set(10000, 10000);
			}

			mouseMoved = false;
		} else {
			uniforms['mousePos'].value.set(10000, 10000);
		}

		// Do the gpu computation
		gpuCompute.compute();

		// Get compute output in custom uniform
		waterUniforms['heightmap'].value = gpuCompute.getCurrentRenderTarget(heightmapVariable).texture;

		snowMaterial.uniforms.trail.value =
			gpuCompute.getCurrentRenderTarget(heightmapVariable).texture;
		snowMaterial.uniforms.heightmap.value =
			gpuCompute.getCurrentRenderTarget(heightmapVariable).texture;

		terrainMaterial.uniforms.trail.value =
			gpuCompute.getCurrentRenderTarget(heightmapVariable).texture;
		terrainMaterial.uniforms.heightmap.value =
			gpuCompute.getCurrentRenderTarget(heightmapVariable).texture;

		// Render
		renderer.render(scene, camera);
	}

	useFrame(() => {
		const renderer = ctx.renderer;
		if (!renderer) return;
		renderer.autoClear = false;
		renderer.clear();
		render();
	});

	let terrainGeometry: BufferGeometry;
	let terrainPhysicsGeometry: BufferGeometry;

	const img = new Image(); // Create new img element

	// img.src = 'fuji_terrainmap.png';
	img.src = 'fuji_terraintile.png';
	img.addEventListener('load', (e) => {
		const terrain = decodeTerrainFromTile(img);
		terrainPhysicsGeometry = genMartiniTerrain(terrain, img.width, 50);
		terrainGeometry = genMartiniTerrain(terrain, img.width, 0);
	});
</script>

<T.PerspectiveCamera
	position={[1200, 1000, 400]}
	fov={30}
	let:ref
	makeDefault
	bind:ref={camera}
	far={99999}
>
	<OrbitControls
		enableZoom={true}
		target={{ x: 400, y: 0.5, z: 0 }}
		autoRotate
		autoRotateSpeed={0.0}
	/>
</T.PerspectiveCamera>

<T.Mesh position={playerPosition}>
	<T.SphereGeometry args={[10]} />
	<T.MeshStandardMaterial color={'red'} />
</T.Mesh>

<Environment files="03_env/belfast_sunset_puresky_4k.hdr" isBackground />

{#if terrainGeometry}
	<T.Mesh
		receiveShadow
		geometry={terrainGeometry}
		position={[BOUNDS * 0.5, 0, -BOUNDS * 0.5]}
		material={terrainMaterial}
		scale={[2, 2, 2]}
		bind:ref={terrainMesh}
	>
		<!-- <T.MeshStandardMaterial /> -->
	</T.Mesh>
{/if}

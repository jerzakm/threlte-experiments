<script lang="ts">
	import { useFrame, useTexture } from '@threlte/core';
	import { T, useThrelte } from '@threlte/core';
	import * as THREE from 'three';
	import { GPUComputationRenderer } from 'three/examples/jsm/misc/GPUComputationRenderer.js';
	import { DoubleSide, ShaderMaterial, Vector3, MeshStandardMaterial } from 'three';
	import type { RigidBody as TRigidBody, Collider as TCollider } from '@dimforge/rapier3d-compat';
	import CustomShaderMaterial from 'three-custom-shader-material/vanilla';

	/* SHADERS */
	import { default as fragmentShader } from './snowFrag.glsl?raw';
	import { default as vertexShader } from './snowVert.glsl?raw';
	import { default as heightmapFragmentShader } from './heightmapFragmentShader.glsl?raw';
	import { default as heightVertexShader } from './heightVertexShader.glsl?raw';
	import { default as readHeightFragmentShader } from './readHeightFragmentShader.glsl?raw';
	import { default as smoothFragmentShader } from './smoothFragmentShader.glsl?raw';

	interface Ball {
		startingPosition: { x: number; y: number; z: number };
		size: number;
		rigidBody?: TRigidBody;
	}

	export let terrainGeometry: any;
	export let testBall: any;
	export let balls: Ball[];

	export let terrainCollider: TCollider;

	const WIDTH = 1024;
	const BOUNDS = 512;

	const { scene, renderer } = useThrelte();

	let waterMesh;
	let meshRay;
	let gpuCompute: any;
	let heightmapVariable: any;
	let waterUniforms: any;
	let smoothShader;
	let readWaterLevelShader: any;
	let readWaterLevelRenderTarget;
	let readWaterLevelImage;

	init();
	function init() {
		const sun = new THREE.DirectionalLight(0xffffff, 1.0);
		sun.position.set(300, 400, 175);
		scene.add(sun);

		const sun2 = new THREE.DirectionalLight(0x40a040, 0.2);
		sun2.position.set(-20, 20, -20);
		scene.add(sun2);

		initSnow();
	}

	function initSnow() {
		const geometry = new THREE.PlaneGeometry(BOUNDS, BOUNDS, WIDTH - 1, WIDTH - 1);

		const material = new THREE.ShaderMaterial({
			uniforms: THREE.UniformsUtils.merge([
				THREE.ShaderLib['phong'].uniforms,
				{
					heightmap: { value: null }
				}
			]),
			vertexShader: heightVertexShader,
			fragmentShader: THREE.ShaderChunk['meshphong_frag']
		});

		// Defines
		material.defines.WIDTH = WIDTH.toFixed(1);
		material.defines.BOUNDS = BOUNDS.toFixed(1);

		waterUniforms = material.uniforms;

		waterMesh = new THREE.Mesh(geometry, material);
		waterMesh.rotation.x = -Math.PI / 2;
		waterMesh.matrixAutoUpdate = false;
		waterMesh.updateMatrix();

		// scene.add(waterMesh);

		// THREE.Mesh just for mouse raycasting
		const geometryRay = new THREE.PlaneGeometry(BOUNDS, BOUNDS, 1, 1);
		meshRay = new THREE.Mesh(
			geometryRay,
			new THREE.MeshBasicMaterial({ color: 0xffffff, visible: false })
		);
		meshRay.rotation.x = -Math.PI / 2;
		meshRay.matrixAutoUpdate = false;
		meshRay.updateMatrix();
		// scene.add(meshRay);

		// Creates the gpu computation class and sets it up

		if (!renderer) return;
		gpuCompute = new GPUComputationRenderer(WIDTH, WIDTH, renderer);

		if (renderer.capabilities.isWebGL2 === false) {
			gpuCompute.setDataType(THREE.HalfFloatType);
		}

		const starterHeightmap = gpuCompute.createTexture();

		fillTexture(starterHeightmap);

		heightmapVariable = gpuCompute.addVariable(
			'heightmap',
			heightmapFragmentShader,
			starterHeightmap
		);

		gpuCompute.setVariableDependencies(heightmapVariable, [heightmapVariable]);

		heightmapVariable.material.uniforms['objects'] = {
			value: []
		};

		// fill up vector
		for (let i = 0; i < 512; i++) {
			heightmapVariable.material.uniforms['objects'].value.push(new Vector3(0, 0, 0));
		}

		heightmapVariable.material.uniforms['mouseSize'] = { value: 20.0 };
		heightmapVariable.material.uniforms['viscosityConstant'] = { value: 0.98 };
		heightmapVariable.material.uniforms['heightCompensation'] = { value: 0 };
		heightmapVariable.material.uniforms['intensity'] = { value: 0.28 };
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
		readWaterLevelShader = gpuCompute.createShaderMaterial(readHeightFragmentShader, {
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

	function fillTexture(texture: any) {
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

	const snowNormal = useTexture('snow_normal.png');

	const terrainMaterial = new CustomShaderMaterial({
		baseMaterial: MeshStandardMaterial,
		vertexShader: `
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
      void main() {
          float tColor = texture2D(heightmap, vec2(vUv.x, 1.-vUv.y)).x;            
          float tColorVal = min(0.5,-tColor*0.1);
          vec3 tColorMod = vec3(tColorVal, tColorVal, tColorVal*0.5);
          tColorMod.b*= 0.9;
          csm_DiffuseColor = vec4(diffuse-tColorMod, 1.);            
          // DEFORM debug
          // csm_DiffuseColor = vec4(1.+ tColor*0.5,0., 0.-tColor*0.5, 1.);
      }
  `,

		normalMap: snowNormal,
		normalScale: new THREE.Vector2(0.1, 0.1),
		envMapIntensity: 0.2,
		emissiveIntensity: 0.5,
		wireframe: false,

		uniforms: {
			heightmap: { value: null }
		},

		color: 0xceceef
	});

	const snowMaterial = new ShaderMaterial({
		fragmentShader,
		vertexShader,
		side: DoubleSide,
		uniforms: {
			heightmap: { value: null }
		}
	});

	let terrainMesh: THREE.Mesh;

	// performance, can render every x frame
	let renderToggle = 0;
	const renderToggleMod = 1;

	function render() {
		renderToggle++;
		const uniforms = heightmapVariable.material.uniforms;

		if (renderToggle % renderToggleMod == 0) {
			for (let i = 0; i < balls.length; i++) {
				const ball = balls[i];
				if (ball.rigidBody) {
					const bCollider = ball.rigidBody.collider(0);

					const point = bCollider.translation();

					const collisionHackVal = 0.5;
					point.y -= collisionHackVal;

					bCollider.setTranslation(point);

					const collision = ball.rigidBody.collider(0).contactCollider(terrainCollider, 6);
					uniforms['objects'].value[i].set(
						point.x * 2 - 256,
						point.z * 2 - 256,
						ball.size * (collision ? 1 : 0)
					);
					point.y += collisionHackVal;
					bCollider.setTranslation(point);
				}
			}
			uniforms['intensity'].value = 0.2;
			gpuCompute.compute();
		}

		// Get compute output in custom uniform
		waterUniforms['heightmap'].value = gpuCompute.getCurrentRenderTarget(heightmapVariable).texture;

		snowMaterial.uniforms.heightmap.value =
			gpuCompute.getCurrentRenderTarget(heightmapVariable).texture;

		terrainMaterial.uniforms.heightmap.value =
			gpuCompute.getCurrentRenderTarget(heightmapVariable).texture;

		// Render
	}

	useFrame(() => {
		render();
	});
</script>

<T.Mesh
	geometry={terrainGeometry}
	material={terrainMaterial}
	bind:ref={terrainMesh}
	position={[0, 3, 0]}
	castShadow
	receiveShadow
>
	<!-- <T.MeshStandardMaterial /> -->
</T.Mesh>

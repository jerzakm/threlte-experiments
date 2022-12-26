<script lang="ts">
	import { default as heightmapFragmentShader } from './heightmapFragmentShader.glsl?raw';
	import { default as heightVertexShader } from './heightVertexShader.glsl?raw';
	import { default as readHeightFragmentShader } from './readHeightFragmentShader.glsl?raw';
	import { default as smoothFragmentShader } from './smoothFragmentShader.glsl?raw';

	import { OrbitControls, T, useFrame, useTexture, useThrelte } from '@threlte/core';
	import * as THREE from 'three';
	import { GPUComputationRenderer } from 'three/examples/jsm/misc/GPUComputationRenderer.js';

	import { decodeTerrainFromTile, genMartiniTerrain } from '$lib/martiniTerrain';
	import { Environment } from '@threlte/extras';
	import type { BufferGeometry } from 'three';
	import { DoubleSide, ShaderMaterial, Vector2 } from 'three';
	import CustomShaderMaterial from 'three-custom-shader-material/vanilla';

	import { AutoColliders, Collider, RigidBody, World } from '@threlte/rapier';
	import { default as fragmentShader } from './snowFrag.glsl?raw';
	import { default as vertexShader } from './snowVert.glsl?raw';

	const WIDTH = 1024;
	const BOUNDS = 512;

	let camera, scene, renderer;
	let mouseMoved = false;
	const mouseCoords = new THREE.Vector2();

	let waterMesh;
	let meshRay;
	let gpuCompute;
	let heightmapVariable;
	let waterUniforms;
	let smoothShader;
	let readWaterLevelShader;
	let readWaterLevelRenderTarget;
	let readWaterLevelImage;

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

		initSnow();
	}

	function initSnow() {
		const materialColor = 0xffffff;

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

	const snowMaterial = new ShaderMaterial({
		fragmentShader,
		vertexShader,
		side: DoubleSide,
		uniforms: {
			heightmap: { value: null }
		}
	});

	const snowNormal = useTexture('snow_normal.png');

	const terrainMaterial = new CustomShaderMaterial({
		baseMaterial: THREE.MeshStandardMaterial,
		vertexShader: `
        // varying vec2 vUv;
        varying vec3 vPosition;
        uniform sampler2D heightmap;
        void main() {
            vUv = uv;
            float tColor = texture2D(heightmap, vec2(vUv.x, 1.-vUv.y)).x;  
            vPosition = (modelMatrix * vec4(position, 1.0)).xyz;
            csm_Position = vec3(position.x, position.y + tColor*1., position.z);
            // csm_Normal = vec3(objectNormal.xyz);
        }
    `,
		fragmentShader: `
        uniform sampler2D heightmap;
        varying vec3 vPosition;
        // varying vec2 vUv;
        
        void main() {
            // float heightValue = texture2D(heightmap, vUv).x;
            float tColor = texture2D(heightmap, vec2(vUv.x, 1.-vUv.y)).x;            
            vec3 tColorMod = vec3(min(0.5,-tColor*0.1));
            tColorMod.b*= 0.9;
            csm_DiffuseColor = vec4(diffuse-tColorMod*1.3, 1.);            

            
            // UVS
            // csm_DiffuseColor = vec4(vUv, 1.,1.);


            // DEFORM debug
            // csm_DiffuseColor = vec4(tColorMod, 1.);
        }
    `,

		normalMap: snowNormal,
		normalScale: new THREE.Vector2(1.1, 1.1),
		envMapIntensity: 0.8,
		emissiveIntensity: 2,
		wireframe: false,

		uniforms: {
			heightmap: { value: null }
		},

		color: 0xceceef
	});

	let terrainMesh: THREE.Mesh;

	let balls = [
		{
			x: 200,
			y: 35,
			z: 80
		}
	];

	let testBall;

	let buttons: { [key: string]: boolean } = {};

	window.addEventListener('keydown', (e) => {
		buttons[e.key] = true;
		buttons = buttons;
	});

	window.addEventListener('keyup', (e) => {
		buttons[e.key] = false;
		buttons = buttons;
	});

	let bt = { x: 0, y: 0, z: 0 };

	function render() {
		const uniforms = heightmapVariable.material.uniforms;

		if (testBall) {
			const point = testBall.translation();
			bt = point;
			uniforms['mousePos'].value.set(point.x * 2 - 256, point.z * 2 - 256);
			uniforms['intensity'].value = 0.08;

			const impulseVector = {
				x: 0,
				y: 0,
				z: 0
			};

			const impulseStrength = 100;

			if (buttons.s) {
				impulseVector.z += impulseStrength;
			}
			if (buttons.w) {
				impulseVector.z -= impulseStrength;
			}

			if (buttons.d) {
				impulseVector.x += impulseStrength;
			}
			if (buttons.a) {
				impulseVector.x -= impulseStrength;
			}
			testBall.applyImpulse(impulseVector, true);
		}

		// Do the gpu computation
		gpuCompute.compute();

		// Get compute output in custom uniform
		waterUniforms['heightmap'].value = gpuCompute.getCurrentRenderTarget(heightmapVariable).texture;

		snowMaterial.uniforms.heightmap.value =
			gpuCompute.getCurrentRenderTarget(heightmapVariable).texture;

		terrainMaterial.uniforms.heightmap.value =
			gpuCompute.getCurrentRenderTarget(heightmapVariable).texture;

		// Render
	}

	let t = 0;

	useFrame(({ clock, composer }) => {
		const renderer = ctx.renderer;
		if (!renderer) return;
		render();

		t += clock.getDelta() * 1000;

		if (balls.length < 1) {
			balls.push({
				x: 200,
				y: 80,
				z: 80
			});
			balls = balls;
		}
	});

	let terrainGeometry: BufferGeometry;
	let terrainPhysicsGeometry: BufferGeometry;

	const img = new Image(); // Create new img element
	img.src = 'fuji_terraintile.png';
	img.addEventListener('load', (e) => {
		const terrain = decodeTerrainFromTile(img);
		terrainPhysicsGeometry = genMartiniTerrain(terrain, img.width, 50);
		terrainGeometry = genMartiniTerrain(terrain, img.width, 10);

		console.log(terrainGeometry.attributes.uv.array.length);
	});
</script>

<T.PerspectiveCamera let:ref position={[200 + bt.x / 2, 100, 200 + bt.z / 2]} fov={30} far={99999}>
	<OrbitControls enableZoom={true} target={{ x: 0 + bt.x, y: 0.5, z: bt.z }} />
</T.PerspectiveCamera>

<T.PerspectiveCamera position={[200, 50, 200]} fov={30} far={99999} makeDefault bind:ref={camera}>
	<OrbitControls enableZoom={true} target={0} autoRotate autoRotateSpeed={0.0} />
</T.PerspectiveCamera>

<Environment files="03_env/belfast_sunset_puresky_4k.hdr" isBackground />

<World
	gravity={{
		x: 0,
		y: -20,
		z: 0
	}}
>
	{#if terrainGeometry}
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

		<Collider
			shape={'trimesh'}
			args={[terrainPhysicsGeometry.attributes.position.array, terrainPhysicsGeometry.index.array]}
		/>
		{#each balls as ball}
			<RigidBody position={ball} type="dynamic" bind:rigidBody={testBall}>
				<AutoColliders shape={'ball'} restitution={0.6}>
					<T.Mesh castShadow receiveShadow>
						<T.SphereGeometry args={[5, 15, 15]} />
						<T.MeshStandardMaterial color={'blue'} />
					</T.Mesh>
				</AutoColliders>
			</RigidBody>
		{/each}
	{/if}

	<!-- <Debug depthTest={true} depthWrite={true} side={DoubleSide} /> -->
</World>

<T.DirectionalLight position={[40, 50, 50]} intensity={0.5} castShadow />
<T.DirectionalLight position={[200, 80, 200]} intensity={0.2} castShadow />
<!-- <T.AmbientLight intensity={0.2} /> -->

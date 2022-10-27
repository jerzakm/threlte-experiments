<script lang="ts">
	import {
		AmbientLight,
		DirectionalLight,
		Mesh,
		OrbitControls,
		PerspectiveCamera,
		useFrame,
		useThrelte
	} from '@threlte/core';
	import * as THREE from 'three';

	import { TextGeometry } from 'three/examples/jsm/geometries/TextGeometry';
	import { FontLoader } from 'three/examples/jsm/loaders/FontLoader';

	import HelperGrid from '../04_helper-grid/HelperGrid.svelte';
	import { default as fragmentShader } from './fragmentShader.glsl?raw';
	import { default as vertexShader } from './vertexShader.glsl?raw';

	const lospec = [
		0x10121c, 0x2c1e31, 0x6b2643, 0xac2847, 0xec273f, 0x94493a, 0xde5d3a, 0xe98537, 0xf3a833,
		0x4d3533, 0x6e4c30, 0xa26d3f, 0xce9248, 0xdab163, 0xe8d282, 0xf7f3b7, 0x1e4044, 0x006554,
		0x26854c, 0x5ab552, 0x9de64e, 0x008b8b, 0x62a477, 0xa6cb96, 0xd3eed3, 0x3e3b65, 0x3859b3,
		0x3388de, 0x36c5f4, 0x6dead6, 0x5e5b8c, 0x8c78a5, 0xb0a7b8, 0xdeceed, 0x9a4d76, 0xc878af,
		0xcc99ff, 0xfa6e79, 0xffa2ac, 0xffd1d5, 0xf6e8e0, 0xffffff
	];

	let textGeo: any;

	let textGeo2: any;

	new FontLoader().load('fonts/Sawton Circular Medium_Regular.json', function (response) {
		textGeo = new TextGeometry('Refractions', {
			font: response,
			size: 20,
			height: 3,
			curveSegments: 5,
			bevelThickness: 0.5,
			bevelSize: 1,
			bevelEnabled: true,
			bevelSegments: 2
		});

		textGeo.computeBoundingBox();

		textGeo2 = new TextGeometry('in Threlte', {
			font: response,
			size: 26,
			height: 3,
			curveSegments: 35,
			bevelThickness: 0.5,
			bevelSize: 0.5,
			bevelEnabled: true,
			bevelSegments: 15
		});

		textGeo2.computeBoundingBox();
	});

	const renderTarget = new THREE.WebGLRenderTarget(window.innerWidth, window.innerHeight, {
		minFilter: THREE.NearestFilter,
		magFilter: THREE.NearestFilter
	});

	const { renderer, scene } = useThrelte();

	let camera: any;

	const refractionMaterial = new THREE.ShaderMaterial({
		uniforms: {
			uRefractPower: { value: 0.2 },
			uSceneTex: { value: renderTarget.texture },
			uTransparent: { value: 0.5 },
			uNoise: { value: 0.001 },
			uHue: { value: 0.0 },
			uSat: { value: 1.0 },
			winResolution: { value: new THREE.Vector2(window.innerWidth, window.innerHeight) }
		},
		vertexShader,
		fragmentShader
	});

	let boxCount = 10;

	useFrame(({ clock }) => {
		if (!renderer) return;
		renderer.setRenderTarget(renderTarget);
		renderer.render(scene, camera);
		renderer.setRenderTarget(null);
		renderer.render(scene, camera);
	});
</script>

<PerspectiveCamera position={{ x: 70, y: 20, z: 100 }} fov={60} near={1} far={2000} bind:camera>
	<OrbitControls autoRotate={true} enableZoom={true} target={{ x: 70, y: 0, z: 0 }} />
</PerspectiveCamera>

<!-- <Environment path="/03_env/" files="spaichingen_hill_1k.hdr" isBackground /> -->

{#if textGeo}
	<Mesh material={refractionMaterial} geometry={textGeo} />
	<Mesh
		material={new THREE.MeshStandardMaterial({ color: lospec[15] })}
		geometry={textGeo2}
		position={{ x: -0, z: -30 }}
	/>
{/if}

<Mesh
	material={new THREE.MeshStandardMaterial({ color: 0x000000, side: THREE.DoubleSide })}
	geometry={new THREE.SphereGeometry(500, 500)}
	position={{ x: 0, y: 0, z: 0 }}
/>

<HelperGrid />

<DirectionalLight position={{ x: 15, y: 5, z: 10 }} intensity={0.7} />
<DirectionalLight position={{ x: 5, y: 5, z: -10 }} intensity={0.7} />
<AmbientLight intensity={1} />

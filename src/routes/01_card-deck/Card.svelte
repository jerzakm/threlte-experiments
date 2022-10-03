<script lang="ts">
	import { Group, Mesh, useFrame, useTexture } from '@threlte/core';
	import { spring } from 'svelte/motion';
	import {
		BoxGeometry,
		DoubleSide,
		MeshLambertMaterial,
		MeshStandardMaterial,
		PlaneGeometry,
		ShaderMaterial,
		Vector3,
		Vector4
	} from 'three';

	import { default as vertexShader } from '$lib/shaders/standardVertex.glsl?raw';
	import { default as fragmentShader } from './fireFrag.glsl?raw';
	import { get } from 'svelte/store';

	const scale = spring(1);

	const texture = useTexture('assets/cards/card fantasy golden shaded.png');
	const textureBack = useTexture('assets/cards/card fantasy back.png');

	const material = new ShaderMaterial({
		uniforms: {
			time: { value: 0 },
			resolution: {
				value: new Vector4()
			},
			card: {
				value: texture
			},
			frameArea: {
				value: useTexture('assets/cards/card fantasy golden frameArea.png')
			},
			monster: {
				value: useTexture('assets/monsters/devil.png')
			}
		},
		vertexShader,
		fragmentShader
	});

	const backMaterial = new MeshLambertMaterial({
		map: textureBack
	});

	const materials = [
		backMaterial,
		backMaterial,
		backMaterial,
		backMaterial,
		material,
		backMaterial
	];

	let currentPosition = new Vector3();

	useFrame(({ camera, clock }) => {
		const cam = get(camera);
		currentPosition = cam.position;

		material.uniforms.time.value = clock.elapsedTime;
		material.uniforms.resolution.value = new Vector4(window.innerWidth, window.innerHeight, 1, 1);
	});
	const geometry = new BoxGeometry(0.744, 1.039, 0.001);
</script>

<Mesh
	scale={$scale}
	interactive
	on:pointerenter={() => ($scale = 1.2)}
	on:pointerleave={() => ($scale = 1)}
	position={{ y: 0.75 }}
	castShadow
	{geometry}
	material={materials}
/>

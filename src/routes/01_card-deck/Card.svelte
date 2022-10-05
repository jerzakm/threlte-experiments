<script lang="ts">
	import { MeshInstance, useFrame, useTexture } from '@threlte/core';
	import { BoxGeometry, Mesh, MeshLambertMaterial, ShaderMaterial, Vector4 } from 'three';
	import { useCursor } from '@threlte/extras';
	import { cubicOut } from 'svelte/easing';
	import { tweened } from 'svelte/motion';
	import { DEG2RAD } from 'three/src/math/MathUtils';

	import { default as vertexShader } from '$lib/shaders/standardVertex.glsl?raw';
	import { default as fragmentShader } from './fireFrag.glsl?raw';

	const texture = useTexture('assets/cards/card fantasy golden shaded.png');
	const textureBack = useTexture('assets/cards/card fantasy back.png');

	export let position = { x: 0, y: 0, z: 0 };
	export let rotation = { x: 0, y: 0, z: 0 };

	// simple flipping animation with a svelte/motion store.
	export let flipped = false;
	const flipMod = tweened(0, {
		duration: 300,
		easing: cubicOut
	});

	$: flipped ? ($flipMod = 1) : ($flipMod = 0);

	// if the card is in Hand it renders it above the rest of the scene with higher render order and by setting material depth test to false
	export let inHand = false;
	let renderOrder = 0 + (inHand ? 1 : 0);

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
		fragmentShader,
		depthTest: !inHand
	});

	const backMaterial = new MeshLambertMaterial({
		map: textureBack
	});
	const geometry = new BoxGeometry(0.744, 1.039, 0.001);
	const materials = [
		backMaterial,
		backMaterial,
		backMaterial,
		backMaterial,
		material,
		backMaterial
	];

	const mesh = new Mesh(geometry, materials);
	const { hovering, onPointerEnter, onPointerLeave } = useCursor();
	useFrame(({ camera, clock }) => {
		// shader material update
		material.uniforms.time.value = clock.elapsedTime;
		material.uniforms.resolution.value = new Vector4(window.innerWidth, window.innerHeight, 1, 1);
	});
</script>

<MeshInstance
	interactive
	{mesh}
	position={{ x: position.x, y: position.y + 0 * $flipMod, z: position.z }}
	rotation={{ x: rotation.x, y: rotation.y + DEG2RAD * 180 * $flipMod, z: rotation.z }}
	on:click
	on:pointerenter={onPointerEnter}
	on:pointerleave={onPointerLeave}
	{renderOrder}
/>

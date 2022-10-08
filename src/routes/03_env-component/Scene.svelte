<script lang="ts">
	import { Group, Mesh, OrbitControls, PerspectiveCamera, useFrame } from '@threlte/core';
	import { MeshStandardMaterial, SphereGeometry } from 'three';
	import Environment from '$lib/components/Environment.svelte';

	let spheres = 15;

	let env = true;

	$: console.log(env);
</script>

<PerspectiveCamera position={{ x: 5, y: 15, z: 5 }} fov={60} near={1} far={20000}>
	<OrbitControls autoRotate={false} enableZoom={true} target={{ x: 0, y: 0, z: 0 }} />
</PerspectiveCamera>

<!-- <Environment
	path={'03_env/milkyway_cube/'}
	files={[
		'dark-s_nx.jpg',
		'dark-s_ny.jpg',
		'dark-s_nz.jpg',
		'dark-s_px.jpg',
		'dark-s_py.jpg',
		'dark-s_pz.jpg'
	]}
	isCubeMap
	isBackground
/> -->

{#if env}
	<Environment path={'03_env/'} files={'equirect_ruined_room.jpg'} isBackground />
{/if}

<Group>
	{#each { length: spheres } as sphere, i}
		<Mesh
			on:click={() => (env = !env)}
			geometry={new SphereGeometry(2)}
			material={new MeshStandardMaterial({
				color: 0xffffff,
				metalness: 1,
				roughness: 0,
				envMapIntensity: 1
			})}
			interactive
			castShadow
			receiveShadow
			position={{ x: Math.random() * 3 * i, y: 3, z: Math.random() * 3 * i }}
		/>
	{/each}
</Group>

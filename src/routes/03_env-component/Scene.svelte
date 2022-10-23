<script lang="ts">
	import { Group, Mesh, OrbitControls, PerspectiveCamera } from '@threlte/core';
	import { MeshStandardMaterial, SphereGeometry } from 'three';

	let spheres = 15;
</script>

<PerspectiveCamera position={{ x: 5, y: 15, z: 5 }} fov={60} near={1} far={20000}>
	<OrbitControls autoRotate={false} enableZoom={true} target={{ x: 0, y: 0, z: 0 }} />
</PerspectiveCamera>

<Group>
	{#each { length: spheres } as sphere, i}
		<Mesh
			geometry={new SphereGeometry(2)}
			material={new MeshStandardMaterial({
				color: 0xffffff,
				metalness: 1,
				roughness: 0,
				envMapIntensity: 1
			})}
			castShadow
			receiveShadow
			position={{ x: (Math.random() - 0.5) * 3 * i, y: 1, z: (Math.random() - 0.5) * 3 * i }}
		/>
	{/each}
</Group>

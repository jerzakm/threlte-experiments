<script lang="ts">
	import {
		Group,
		Mesh,
		OrbitControls,
		PerspectiveCamera,
		AmbientLight,
		DirectionalLight
	} from '@threlte/core';
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
				color: 0xff5555
			})}
			castShadow
			receiveShadow
			position={{ x: Math.random() * 5 * i, y: 3, z: Math.random() * 5 * i }}
		/>
	{/each}
</Group>

<AmbientLight color={0xffffff} intensity={0.5} />

<DirectionalLight />

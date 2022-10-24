<script lang="ts">
	import { Mesh, OrbitControls, PerspectiveCamera } from '@threlte/core';
	import { Environment } from '@threlte/extras';
	import { BoxGeometry, MeshStandardMaterial } from 'three';
</script>

<PerspectiveCamera position={{ x: 20, y: 25, z: 20 }} fov={60} near={1} far={20000}>
	<OrbitControls autoRotate={false} enableZoom={true} target={{ x: 10, y: 0, z: 10 }} />
</PerspectiveCamera>

<Environment path="/03_env/" files="spaichingen_hill_1k.hdr" />

<Mesh
	material={new MeshStandardMaterial({ color: 0xffffff })}
	geometry={new BoxGeometry(2, 2, 2)}
	position={{ x: 5, y: 0, z: 0 }}
/>

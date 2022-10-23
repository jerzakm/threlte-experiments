<script lang="ts">
	import { Mesh } from '@threlte/core';
	import { AutoColliders } from '@threlte/rapier';
	import { BoxGeometry, MeshStandardMaterial } from 'three';
	export let color: number;
</script>

<AutoColliders shape={'cuboid'} position={{ y: -0.5 }}>
	<Mesh
		receiveShadow
		geometry={new BoxGeometry(500, 0.5, 500)}
		material={new MeshStandardMaterial({ color })}
	/>
</AutoColliders>

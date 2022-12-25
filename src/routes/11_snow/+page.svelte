<script lang="ts">
	import { Canvas, Mesh, OrbitControls, PerspectiveCamera, useFrame } from '@threlte/core';
	import Scene from './Scene.svelte';
	import Scene2 from './Scene2.svelte';

	let elementToFollow;
</script>

<wrapper class="relative h-full">
	<Canvas frameloop={'always'}>
		<!-- <Scene /> -->
		<Scene2 />
	</Canvas>
</wrapper>

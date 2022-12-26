<script lang="ts">
	import { Canvas, Mesh, OrbitControls, PerspectiveCamera, useFrame } from '@threlte/core';
	import Scene from './Scene.svelte';

	let elementToFollow;
</script>

<wrapper class="relative h-full bg-black">
	<Canvas frameloop={'always'}>
		<Scene />
	</Canvas>
</wrapper>

<script lang="ts">
	import { Canvas } from '@threlte/core';
	import Scene from './Scene.svelte';
</script>

<wrapper class="relative h-full">
	<Canvas frameloop={'always'}>
		<Scene />
	</Canvas>
</wrapper>

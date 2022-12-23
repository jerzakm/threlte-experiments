<script lang="ts">
	import { Canvas } from '@threlte/core';
	import NewScene from './NewScene.svelte';
	import Scene from './Scene.svelte';
	import SceneMasking from './SceneMasking.svelte';
</script>

<wrapper class="relative h-full">
	<Canvas frameloop={'always'}>
		<!-- <Scene /> -->
		<!-- <NewScene /> -->
		<SceneMasking />
	</Canvas>
</wrapper>

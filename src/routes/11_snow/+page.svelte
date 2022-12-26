<script lang="ts">
	import { Canvas } from '@threlte/core';
	import Scene2 from './Scene2.svelte';
</script>

<wrapper class="relative h-full">
	<Canvas frameloop={'always'}>
		<Scene2 />
	</Canvas>
</wrapper>

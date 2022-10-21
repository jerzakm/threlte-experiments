<script lang="ts">
	import { Canvas } from '@threlte/core';
	import * as knobby from 'svelte-knobby';
	import Scene from './Scene.svelte';

	const controls = knobby.panel({
		$label: 'Grid options',
		color: '#ffffff',
		enabled: true
	});
</script>

<wrapper class="relative h-full">
	<Canvas>
		<Scene />
	</Canvas>
</wrapper>

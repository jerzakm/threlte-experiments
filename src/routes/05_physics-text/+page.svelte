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
	<h1 class="absolute text-3xl font-bold p-16">Type stuff to make it fall</h1>
	<Canvas>
		<Scene />
	</Canvas>
</wrapper>

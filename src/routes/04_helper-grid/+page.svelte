<script lang="ts">
	import { Canvas } from '@threlte/core';
	import * as knobby from 'svelte-knobby';
	import HelperGrid from './HelperGrid.svelte';
	import Scene from './Scene.svelte';

	const controls = knobby.panel({
		$label: 'Grid options',
		size1: {
			$label: 'size1',
			value: 10,
			min: 1,
			max: 100,
			step: 1
		},
		size2: {
			$label: 'size2',
			value: 100,
			min: 10,
			max: 1000,
			step: 1
		},
		color: '#ffffff',
		enabled: true,
		distance: {
			$label: 'distance',
			value: 8000,
			min: 500,
			max: 1000000,
			step: 100
		}

		// functions become buttons. if state is returned, it will
		// update the store
	});

	// the returned store is writable
	$controls.message = 'Hello Knobby!';
</script>

<wrapper class="relative h-full">
	<Canvas>
		{#if $controls.enabled}
			<HelperGrid
				size1={$controls.size1}
				size2={$controls.size2}
				color={$controls.color}
				distance={$controls.distance}
			/>
		{/if}
		<Scene />
	</Canvas>
</wrapper>

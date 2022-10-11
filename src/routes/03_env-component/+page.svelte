<script lang="ts">
	import Environment from '$lib/components/Environment.svelte';
	import { Canvas } from '@threlte/core';
	import * as knobby from 'svelte-knobby';
	import Scene from './Scene.svelte';

	const controls = knobby.panel({
		// labelled control panels are collapsible
		$label: 'Options',

		environmentEnabled: true,
		isBackground: true,

		// functions become buttons. if state is returned, it will
		// update the store
		increment: (value) => ({
			// ...value,
			// clicks: value.clicks + 1
		})
	});

	// the returned store is writable
	$controls.message = 'Hello Knobby!';
</script>

<wrapper class="relative h-full">
	<Canvas>
		{#if $controls.environmentEnabled}
			<!-- <Environment
		path={'03_env/milkyway_cube/'}
		files={[
			'dark-s_nx.jpg',
			'dark-s_ny.jpg',
			'dark-s_nz.jpg',
			'dark-s_px.jpg',
			'dark-s_py.jpg',
			'dark-s_pz.jpg'
		]}
		isCubeMap
		isBackground
	/> -->
			<Environment
				path={'03_env/'}
				files={'equirect_ruined_room.jpg'}
				isBackground={$controls.isBackground}
			/>
		{/if}
		<Scene />
	</Canvas>
</wrapper>

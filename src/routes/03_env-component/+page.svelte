<script lang="ts">
	import Environment from '$lib/components/Environment.svelte';
	import { Canvas } from '@threlte/core';
	import * as knobby from 'svelte-knobby';
	import Scene from './Scene.svelte';

	let path = '03_env/';
	let files: string | [string, string, string, string, string, string] = 'equirect_ruined_room.jpg';
	let isCubeMap = false;

	const controls = knobby.panel({
		// labelled control panels are collapsible
		$label: 'Options',

		environmentEnabled: true,
		isBackground: true,

		// functions become buttons. if state is returned, it will
		// update the store
		cubicJpgScene: () => {
			isCubeMap = true;
			path = '03_env/milkyway_cube/';
			files = [
				'dark-s_nx.jpg',
				'dark-s_ny.jpg',
				'dark-s_nz.jpg',
				'dark-s_px.jpg',
				'dark-s_py.jpg',
				'dark-s_pz.jpg'
			];
		},
		equirectJpgScene: () => {
			isCubeMap = false;
			path = '03_env/';
			files = 'equirect_ruined_room.jpg';
		}
	});

	// the returned store is writable
	$controls.message = 'Hello Knobby!';
</script>

<wrapper class="relative h-full">
	<Canvas>
		{#if $controls.environmentEnabled}
			<Environment {path} {files} isBackground={$controls.isBackground} {isCubeMap} />
		{/if}
		<Scene />
	</Canvas>
</wrapper>

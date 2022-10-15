<script lang="ts">
	import Environment from '$lib/components/Environment.svelte';
	import { Canvas } from '@threlte/core';
	import * as knobby from 'svelte-knobby';
	import Scene from './Scene.svelte';

	let path = '03_env/';
	let files: string | [string, string, string, string, string, string] = 'equirect_ruined_room.jpg';
	let isCubeMap = false;
	let format: 'ldr' | 'hdr' | 'exr' | undefined = 'ldr';

	const controls = knobby.panel({
		// labelled control panels are collapsible
		$label: 'Options',

		environmentEnabled: true,
		isBackground: true,
		groundProjection: {
			$label: 'Ground projected environment mapping',
			enabled: true,
			height: {
				$label: 'height',
				value: 10,
				min: 1,
				max: 100,
				step: 1
			},
			radius: {
				$label: 'radius',
				value: 400,
				min: 1,
				max: 1000,
				step: 1
			}
		},

		// functions become buttons. if state is returned, it will
		// update the store
		cubicJpgScene: () => {
			isCubeMap = true;
			path = '/03_env/Bridge2_cube/';
			files = ['posx.jpg', 'negx.jpg', 'posy.jpg', 'negy.jpg', 'posz.jpg', 'negz.jpg'];
			format = 'ldr';
		},
		equirectJpgScene: () => {
			isCubeMap = false;
			path = '/03_env/';
			files = 'equirect_ruined_room.jpg';
			format = 'ldr';
		},

		equirectExrScene: () => {
			isCubeMap = false;
			path = '/03_env/';
			files = 'piz_compressed.exr';
			format = 'exr';
		},
		cubicHdrScene: () => {
			isCubeMap = true;
			path = '/03_env/pisaHDR/';
			files = ['px.hdr', 'nx.hdr', 'py.hdr', 'ny.hdr', 'pz.hdr', 'nz.hdr'];
			format = 'hdr';
		}
	});

	$controls.cubicJpgScene();
</script>

<wrapper class="relative h-full">
	<Canvas>
		{#if $controls.environmentEnabled}
			<Environment
				{path}
				{files}
				isBackground={$controls.isBackground}
				{isCubeMap}
				{format}
				groundProjection={$controls.groundProjection.enabled
					? {
							radius: $controls.groundProjection.radius,
							height: $controls.groundProjection.height
					  }
					: undefined}
			/>
		{/if}
		<Scene />
	</Canvas>
</wrapper>

<script lang="ts">
	import { useTexture, useThrelte } from '@threlte/core';
	import { onMount, onDestroy } from 'svelte';
	import { CubeTextureLoader, EquirectangularReflectionMapping, sRGBEncoding } from 'three';

	export let path: string | undefined;
	export let files: string | [string, string, string, string, string, string];
	export let isCubeMap: boolean = false;
	export let isBackground: boolean | undefined = undefined;
	// TODO
	// export let encoding;
	// export let format = 'img'; // exr, hdr for loaders?
	// export let ground -- ground envmap implementation with radius and height (threejs addon)
	// export let scene -- allow for custom scene selection?

	const { scene, invalidate } = useThrelte();

	onMount(() => {
		if (isCubeMap) {
			if (!Array.isArray(files))
				throw new Error(`Files ${files} provided for a cubemap are not an Array.`);

			const loader = new CubeTextureLoader();
			loader.setPath(path || '');

			const textureCube = loader.load(files);
			textureCube.encoding = sRGBEncoding;

			scene.environment = textureCube;
			if (isBackground) scene.background = textureCube;
		} else {
			const textureEquirec = useTexture(`${path || ''}${files}`);
			textureEquirec.mapping = EquirectangularReflectionMapping;
			textureEquirec.encoding = sRGBEncoding;
			scene.environment = textureEquirec;
			if (isBackground) scene.background = textureEquirec;
		}
	});

	onDestroy(() => {
		scene.environment = null;
		scene.background = null;
		invalidate();
	});
</script>

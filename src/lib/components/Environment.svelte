<script lang="ts">
	import { DisposableObject, useTexture, useThrelte } from '@threlte/core';
	import { onMount, onDestroy } from 'svelte';
	import {
		CubeTexture,
		CubeTextureLoader,
		EquirectangularReflectionMapping,
		sRGBEncoding,
		Texture,
		TextureLoader
	} from 'three';

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

	$: envPath = `${path || ''}${files}`;
	let previousEnvPath: string = ``;

	$: console.log(envPath);

	let envTexture: CubeTexture | Texture | undefined;

	$: {
		if (envPath != previousEnvPath) {
			if (envTexture) {
				envTexture.dispose();
			}
			loadEnv();
			previousEnvPath = envPath;
		}

		// todo, react to isBackground prop change
	}

	const loadEnv = () => {
		if (isCubeMap) {
			if (!Array.isArray(files))
				throw new Error(`Files ${files} provided for a cubemap are not an Array.`);

			const loader = new CubeTextureLoader();
			loader.setPath(path || '');

			envTexture = loader.load(files, (textureCube) => {
				textureCube.encoding = sRGBEncoding;
				scene.environment = textureCube;
				if (isBackground) scene.background = textureCube;
				invalidate('Cube texture Environment loaded');
				envTexture = textureCube;
			});
		} else {
			envTexture = new TextureLoader().load(`${path || ''}${files}`, (textureEquirec) => {
				textureEquirec.mapping = EquirectangularReflectionMapping;
				textureEquirec.encoding = sRGBEncoding;
				scene.environment = textureEquirec;
				if (isBackground) scene.background = textureEquirec;
				invalidate('Equirectangular Environment loaded');
				envTexture = textureEquirec;
			});
		}
	};

	onDestroy(() => {
		scene.environment = null;
		scene.background = null;
		if (envTexture) envTexture.dispose();
		invalidate('Environment destroyed');
	});
</script>

<script lang="ts">
	import { useThrelte } from '@threlte/core';
	import { onDestroy } from 'svelte';
	import { HDRCubeTextureLoader } from 'three/examples/jsm/loaders/HDRCubeTextureLoader';

	import {
		CubeTextureLoader,
		DefaultLoadingManager,
		EquirectangularReflectionMapping,
		LinearFilter,
		PMREMGenerator,
		sRGBEncoding,
		Texture,
		TextureLoader
	} from 'three';
	import { EXRLoader } from 'three/examples/jsm/loaders/EXRLoader.js';

	export let path: string | undefined;
	export let files: string | string[];
	export let isCubeMap: boolean = false;
	export let isBackground: boolean | undefined = undefined;

	export let format: 'ldr' | 'hdr' | 'exr' = 'ldr';
	// export let ground -- ground envmap implementation with radius and height (threejs addon)

	const { scene, invalidate, renderer } = useThrelte();

	$: envPath = `${path || ''}${files}`;

	let previousEnvPath: string = ``;
	let envTexture: Texture;

	let currentFormat = '';

	const loadEnv = () => {
		// pmrem gen for cube and equirect
		const pmremGenerator = new PMREMGenerator(renderer);
		isCubeMap
			? pmremGenerator.compileCubemapShader()
			: pmremGenerator.compileEquirectangularShader();
		DefaultLoadingManager.onLoad = function () {
			pmremGenerator.dispose();
		};

		switch (format) {
			case 'ldr':
				if (isCubeMap) {
					if (!Array.isArray(files))
						throw new Error(`Files ${files} provided for a cubemap are not an Array.`);

					console.log(path, files);
					new CubeTextureLoader()
						.setPath(path || '')
						.load(files, (textureCube) => {
							textureCube.encoding = sRGBEncoding;
							envTexture = pmremGenerator.fromCubemap(textureCube).texture;
							setEnvironment();
						})
						.dispose();
				} else {
					new TextureLoader()
						.load(`${path || ''}${files}`, (textureEquirec) => {
							textureEquirec.mapping = EquirectangularReflectionMapping;
							textureEquirec.encoding = sRGBEncoding;
							envTexture = pmremGenerator.fromEquirectangular(textureEquirec).texture;
							setEnvironment();
						})
						.dispose();
					break;
				}
			case 'hdr':
				const hdrCubeMap = new HDRCubeTextureLoader().setPath(path || '').load(files, function () {
					envTexture = pmremGenerator.fromCubemap(hdrCubeMap).texture;
					hdrCubeMap.magFilter = LinearFilter;
					setEnvironment();
				});
				break;
			case 'exr':
				new EXRLoader()
					.load(`${path || ''}${files}`, function (texture) {
						envTexture = pmremGenerator.fromEquirectangular(texture).texture;
						setEnvironment();
					})
					.dispose();
				break;
		}
		currentFormat = format;
	};

	const setEnvironment = () => {
		scene.environment = envTexture;
		if (isBackground) scene.background = envTexture;
		invalidate();
	};

	$: {
		if (envPath != previousEnvPath || format != currentFormat) {
			if (envTexture) {
				envTexture.dispose();
			}
			console.log(envPath, previousEnvPath);
			loadEnv();

			previousEnvPath = envPath;
		}

		if (!isBackground && scene.background) {
			scene.background = null;
			invalidate('Removing Environment as scene.background');
		}
		if (isBackground && !scene.background && envTexture) {
			scene.background = envTexture;
			invalidate('Adding Environment as scene.background');
		}
	}

	onDestroy(() => {
		scene.environment = null;
		scene.background = null;
		if (envTexture) envTexture.dispose();
		invalidate('Environment destroyed');
	});
</script>

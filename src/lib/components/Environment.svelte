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
	import { GroundProjectedEnv } from 'three/examples/jsm/objects/GroundProjectedEnv.js';

	export let path: string | undefined;
	export let files: string | string[];
	export let isCubeMap: boolean = false;
	export let isBackground: boolean | undefined = undefined;
	export let groundProjection: { radius: number; height: number } | undefined = undefined;

	export let format: 'ldr' | 'hdr' | 'exr' = 'ldr';
	// export let ground -- ground envmap implementation with radius and height (threejs addon)

	const { scene, invalidate, renderer } = useThrelte();

	$: envPath = `${path || ''}${files}`;

	let previousEnvPath: string = ``;
	let processedEnv: Texture;
	let envMap: Texture;

	let currentFormat = '';

	let groundEnv: any;

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
							envMap = textureCube;
							textureCube.encoding = sRGBEncoding;
							processedEnv = pmremGenerator.fromCubemap(textureCube).texture;
							setEnvironment();
						})
						.dispose();
				} else {
					new TextureLoader()
						.load(`${path || ''}${files}`, (textureEquirec) => {
							envMap = textureEquirec;
							textureEquirec.mapping = EquirectangularReflectionMapping;
							textureEquirec.encoding = sRGBEncoding;
							processedEnv = pmremGenerator.fromEquirectangular(textureEquirec).texture;
							setEnvironment();
						})
						.dispose();
					break;
				}
			case 'hdr':
				const hdrCubeMap = new HDRCubeTextureLoader().setPath(path || '').load(files, function () {
					envMap = hdrCubeMap;
					processedEnv = pmremGenerator.fromCubemap(hdrCubeMap).texture;
					hdrCubeMap.magFilter = LinearFilter;
					setEnvironment();
				});
				break;
			case 'exr':
				new EXRLoader()
					.load(`${path || ''}${files}`, function (texture) {
						envMap = texture;
						processedEnv = pmremGenerator.fromEquirectangular(texture).texture;
						setEnvironment();
					})
					.dispose();
				break;
		}
		currentFormat = format;
	};

	const setEnvironment = () => {
		scene.environment = processedEnv;
		if (isBackground) scene.background = processedEnv;
		if (groundProjection) enableGroundEnv();
		invalidate();
	};

	const enableGroundEnv = () => {
		if (groundProjection) {
			groundEnv = new GroundProjectedEnv(envMap);
			groundEnv.scale.setScalar(100);
			groundEnv.radius = groundProjection.radius;
			groundEnv.height = groundProjection.height;
			scene.add(groundEnv);
		}
	};

	$: {
		if (envPath != previousEnvPath || format != currentFormat) {
			if (processedEnv) {
				processedEnv.dispose();
			}
			console.log(envPath, previousEnvPath);
			loadEnv();

			previousEnvPath = envPath;
		}

		if (!isBackground && scene.background) {
			scene.background = null;
			invalidate('Removing Environment as scene.background');
		}
		if (isBackground && !scene.background && processedEnv) {
			scene.background = processedEnv;
			invalidate('Adding Environment as scene.background');
		}
		if (groundEnv && groundProjection) {
			groundEnv.radius = groundProjection.radius;
			groundEnv.height = groundProjection.height;
			invalidate();
		}

		if (groundEnv && !groundProjection) {
			scene.remove(groundEnv);
			invalidate('Disabling ground projected environment');
		}
		if (!groundEnv && groundProjection && envMap) {
			enableGroundEnv();
			invalidate('Enabling ground projected environment');
		}
	}

	onDestroy(() => {
		scene.environment = null;
		scene.background = null;
		if (processedEnv) processedEnv.dispose();
		invalidate('Environment destroyed');
	});
</script>

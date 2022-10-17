<script lang="ts">
	import { useThrelte } from '@threlte/core';
	import { onDestroy } from 'svelte';
	import { HDRCubeTextureLoader } from 'three/examples/jsm/loaders/HDRCubeTextureLoader';
	import { RGBELoader } from 'three/examples/jsm/loaders/RGBELoader';
	import {
		CubeTextureLoader,
		DefaultLoadingManager,
		PMREMGenerator,
		sRGBEncoding,
		Texture,
		type TextureEncoding,
		TextureLoader,
		LinearEncoding
	} from 'three';
	import { GroundProjectedEnv } from 'three/examples/jsm/objects/GroundProjectedEnv.js';

	export let path: string | undefined;
	export let files: string | string[];
	export let isBackground: boolean | undefined = undefined;
	export let groundProjection: { radius: number; height: number } | undefined = undefined;
	export let format: 'ldr' | 'hdr' = 'ldr';
	export let encoding: TextureEncoding | undefined = undefined;

	const { scene, invalidate, renderer } = useThrelte();

	$: isCubeMap = Array.isArray(files);
	$: envPath = `${path || ''}${files}`;

	let previousEnvPath: string = ``;
	let currentProcessedEnv: Texture;
	let currentEnvMap: Texture;
	let currentFormat = '';
	let currentGroundEnv: any;

	const pickLoader = () => {
		if (isCubeMap && format == 'ldr') return new CubeTextureLoader();
		if (!isCubeMap && format == 'ldr') return new TextureLoader();
		if (isCubeMap && format == 'hdr') return new HDRCubeTextureLoader();
		if (!isCubeMap && format == 'hdr') return new RGBELoader();
		return new TextureLoader();
	};

	const loadEnvironment = () => {
		if (!renderer) throw new Error('Threlte renderer undefined');
		const pmremGenerator = new PMREMGenerator(renderer);
		DefaultLoadingManager.onLoad = function () {
			pmremGenerator.dispose();
		};
		const loader: any = pickLoader();

		if (isCubeMap) {
			pmremGenerator.compileCubemapShader();
			loader.setPath(path || '').load(files, (texture: any) => {
				currentEnvMap = texture;
				texture.encoding = encoding || sRGBEncoding;
				currentProcessedEnv = pmremGenerator.fromCubemap(texture).texture;
				setEnvironment();
			});
		} else {
			pmremGenerator.compileEquirectangularShader();
			loader.load(`${path || ''}${files}`, (texture: any) => {
				currentEnvMap = texture;
				texture.encoding = encoding || LinearEncoding;
				currentProcessedEnv = pmremGenerator.fromEquirectangular(texture).texture;
				setEnvironment();
			});
		}
		currentFormat = format;
	};

	const setEnvironment = () => {
		scene.environment = currentProcessedEnv;
		if (isBackground) scene.background = currentProcessedEnv;
		invalidate();
	};

	const toggleGroundEnv = (
		groundEnv: GroundProjectedEnv | undefined,
		groundEnvProps: { radius: number; height: number } | undefined,
		envMap: Texture
	) => {
		if (groundEnv && !groundEnvProps) {
			scene.remove(currentGroundEnv);
			currentGroundEnv = undefined;
			invalidate('Removing ground projected environment');
		}
		if (!groundEnv && groundEnvProps && envMap) {
			currentGroundEnv = new GroundProjectedEnv(envMap);
			currentGroundEnv.scale.setScalar(100);
			currentGroundEnv.radius = groundEnvProps.radius;
			currentGroundEnv.height = groundEnvProps.height;
			scene.add(currentGroundEnv);
			invalidate('Enabling ground projected environment');
		}
		if (groundEnv && groundEnvProps) {
			currentGroundEnv.radius = groundEnvProps.radius;
			currentGroundEnv.height = groundEnvProps.height;
			invalidate('Updating ground projected environment properties');
		}
	};

	$: toggleGroundEnv(currentGroundEnv, groundProjection, currentEnvMap);

	$: {
		// Reload environment on path change
		if (envPath != previousEnvPath || format != currentFormat) {
			if (currentProcessedEnv) {
				currentProcessedEnv.dispose();
			}
			loadEnvironment();
			previousEnvPath = envPath;
		}

		if (!isBackground && scene.background) {
			scene.background = null;
			invalidate('Removing Environment as scene.background');
		}
		if (isBackground && !scene.background && currentProcessedEnv) {
			scene.background = currentProcessedEnv;
			invalidate('Adding Environment as scene.background');
		}
	}

	onDestroy(() => {
		scene.environment = null;
		scene.background = null;
		if (currentProcessedEnv) currentProcessedEnv.dispose();
		invalidate('Environment destroyed');
	});
</script>

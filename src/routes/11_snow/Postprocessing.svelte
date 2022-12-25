<script lang="ts">
	import { useThrelte } from '@threlte/core';
	import {
		BloomEffect,
		BrightnessContrastEffect,
		ChromaticAberrationEffect,
		EffectComposer,
		EffectPass,
		KernelSize,
		RenderPass,
		SMAAEffect,
		SMAAPreset
	} from 'postprocessing';
	import { onDestroy } from 'svelte';
	import { tweened } from 'svelte/motion';
	import { Scene, Vector2 } from 'three';

	export let scene: Scene;
	export let camera: any;

	const ctx = useThrelte();

	const { renderer } = ctx;

	let bloomEffect: BloomEffect | undefined = undefined;

	const composer = new EffectComposer(renderer);
	ctx.composer = composer as any;

	const addComposerAndPasses = () => {
		composer.removeAllPasses();

		composer.addPass(new RenderPass(scene, camera));
		// bloomEffect = new BloomEffect({
		// 	intensity: 0.2,
		// 	luminanceThreshold: 0.15,
		// 	height: 512,
		// 	width: 512,
		// 	luminanceSmoothing: 0.08,
		// 	mipmapBlur: true,
		// 	kernelSize: KernelSize.MEDIUM
		// });
		// bloomEffect.luminancePass.enabled = true;
		// (bloomEffect as any).ignoreBackground = true;
		// composer.addPass(new EffectPass(camera, bloomEffect));
		// composer.addPass(
		// 	new EffectPass(
		// 		camera,
		// 		new ChromaticAberrationEffect({
		// 			offset: new Vector2(0.0005, 0.0005),
		// 			modulationOffset: 0,
		// 			radialModulation: false
		// 		})
		// 	)
		// );
		// composer.addPass(
		// 	new EffectPass(
		// 		camera,
		// 		new BrightnessContrastEffect({
		// 			brightness: 0,
		// 			contrast: 0.1
		// 		})
		// 	)
		// );
		// composer.addPass(
		// 	new EffectPass(
		// 		camera,
		// 		new SMAAEffect({
		// 			preset: SMAAPreset.LOW
		// 		})
		// 	)
		// );
	};

	$: if (renderer && camera && scene) {
		addComposerAndPasses();
	}
	onDestroy(() => {
		composer.removeAllPasses();
	});
</script>

<script lang="ts">
	import { useThrelte } from '@threlte/core';
	import {
		BloomEffect,
		BrightnessContrastEffect,
		EffectComposer,
		EffectPass,
		KernelSize,
		RenderPass,
		SMAAEffect,
		SMAAPreset
	} from 'postprocessing';
	import { onDestroy } from 'svelte';

	const ctx = useThrelte();

	const { renderer, camera, scene } = ctx;

	let bloomEffect: BloomEffect | undefined = undefined;

	const composer = new EffectComposer(renderer);
	ctx.composer = composer as any;

	const addComposerAndPasses = () => {
		composer.removeAllPasses();

		composer.addPass(new RenderPass(scene, $camera));
		bloomEffect = new BloomEffect({
			intensity: 1.0,
			luminanceThreshold: 0.77,
			height: 256,
			width: 256,
			luminanceSmoothing: 0.11,
			mipmapBlur: false,
			kernelSize: KernelSize.VERY_SMALL
		});

		composer.addPass(
			new EffectPass(
				$camera,
				new BrightnessContrastEffect({
					brightness: -0.1,
					contrast: 0.1
				})
			)
		);
		composer.addPass(
			new EffectPass(
				$camera,
				new SMAAEffect({
					preset: SMAAPreset.HIGH
				})
			)
		);

		bloomEffect.luminancePass.enabled = true;
		(bloomEffect as any).ignoreBackground = true;
		// composer.addPass(new EffectPass($camera, bloomEffect));
	};

	$: if (renderer && camera && scene) {
		addComposerAndPasses();
	}
	onDestroy(() => {
		composer.removeAllPasses();
	});
</script>

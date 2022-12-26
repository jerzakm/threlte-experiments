<script lang="ts">
	import { useFrame } from '@threlte/core';
	import { Vector3 } from 'three';
	import { DoubleSide } from 'three';
	import { ShaderMaterial } from 'three';
	import { default as noiseFragment } from './noiseMaterialFS.glsl?raw';
	import { default as noiseVertex } from './noiseMaterialVS.glsl?raw';

	const noiseMaterial = new ShaderMaterial({
		uniforms: {
			iResolution: { value: new Vector3() },
			iTime: { value: 0 }
		},
		fragmentShader: noiseFragment,
		vertexShader: noiseVertex,
		side: DoubleSide
	});

	useFrame(({ clock, renderer }) => {
		if (!renderer) return;
		noiseMaterial.uniforms.iTime.value = clock.getElapsedTime();
		noiseMaterial.uniforms.iResolution.value.set(
			renderer?.domElement.width,
			renderer?.domElement.height,
			1
		);
	});
</script>

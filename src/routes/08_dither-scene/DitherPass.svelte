<script lang="ts">
	import { useFrame } from '@threlte/core';
	import { Vector3 } from 'three';
	import { ShaderPass } from 'three/examples/jsm/postprocessing/ShaderPass';
	import { default as fragmentShader } from './ditherPass.glsl?raw';

	const DitherShader = {
		uniforms: {
			tDiffuse: { value: null },
			opacity: { value: 1.0 },
			iResolution: { value: new Vector3() },
			iTime: { value: 0 }
		},

		vertexShader: /* glsl */ `
  varying vec2 vUv;
  void main() {
    vUv = uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
  }`,

		fragmentShader
	};

	const ditherPass = new ShaderPass(DitherShader);

	useFrame(({ clock, renderer }) => {
		if (!renderer) return;

		ditherPass.uniforms.iResolution.value.set(
			renderer?.domElement.width,
			renderer?.domElement.height,
			1
		);
		ditherPass.uniforms.iTime.value = clock.getElapsedTime();
	});
</script>

<script lang="ts">
	import { useFrame, useThrelte, T, OrbitControls } from '@threlte/core';
	import { get } from 'svelte/store';
	import type { MeshBasicMaterial, PerspectiveCamera, PlaneGeometry } from 'three';
	import * as THREE from 'three';

	import { EffectComposer } from 'three/examples/jsm/postprocessing/EffectComposer.js';
	import { RenderPass } from 'three/examples/jsm/postprocessing/RenderPass.js';
	import { ShaderPass } from 'three/examples/jsm/postprocessing/ShaderPass';
	import { default as noiseFragment } from './noiseMaterialFS.glsl?raw';
	import { default as noiseVertex } from './noiseMaterialVS.glsl?raw';
	import { default as ditherFrag } from './ditherPass.glsl?raw';
	import { default as fragmentDitherTexture } from './ditherTexture.glsl?raw';
	import { DEG2RAD } from 'three/src/math/MathUtils';
	const fragmentShaderScreen = `  
  varying vec2 vUv;
  uniform sampler2D tDiffuse;

  void main() {

    gl_FragColor = texture2D( tDiffuse, vUv );

  }`;

	const fragmentShaderPass1 = `
  varying vec2 vUv;
  uniform float time;

  void main() {

    float r = vUv.x;
    if( vUv.y < 0.5 ) r = 0.0;
    float g = vUv.y;
    if( vUv.x < 0.5 ) g = 0.0;

    gl_FragColor = vec4( r, g, time, 1.0 );

  }`;

	const vertexShader = `
  varying vec2 vUv;
  void main() {

    vUv = uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

  }
`;

	const ctx = useThrelte();
	const { renderer, camera } = ctx;

	const pCamera = new THREE.PerspectiveCamera(30, window.innerWidth / window.innerHeight, 1, 10000);
	pCamera.position.z = 100;

	const cameraRTT = new THREE.OrthographicCamera(
		window.innerWidth / -2,
		window.innerWidth / 2,
		window.innerHeight / 2,
		window.innerHeight / -2,
		-10000,
		10000
	);
	cameraRTT.position.z = 100;

	const scene = new THREE.Scene();
	const sceneRTT = new THREE.Scene();
	const sceneNoiseRTT = new THREE.Scene();
	const sceneNoise = new THREE.Scene();
	const sceneScreen = new THREE.Scene();

	let light = new THREE.DirectionalLight(0xffffff);
	light.position.set(0, 0, 1).normalize();
	sceneRTT.add(light);

	light = new THREE.DirectionalLight(0xffaaaa, 1.5);
	light.position.set(0, 0, -1).normalize();
	sceneRTT.add(light);

	const rtTexture = new THREE.WebGLRenderTarget(window.innerWidth, window.innerHeight);

	const rtNoiseSphere = new THREE.WebGLRenderTarget(window.innerWidth, window.innerHeight);

	const material = new THREE.ShaderMaterial({
		uniforms: { time: { value: 0.0 } },
		vertexShader: vertexShader,
		fragmentShader: fragmentShaderPass1
	});

	const materialScreen = new THREE.ShaderMaterial({
		uniforms: { tDiffuse: { value: rtTexture.texture } },
		vertexShader: vertexShader,
		fragmentShader: fragmentShaderScreen,
		depthWrite: false
	});
	const plane = new THREE.PlaneGeometry(window.innerWidth, window.innerHeight);

	// const quad = new THREE.Mesh(plane, material);
	// quad.position.z = -100;
	// sceneRTT.add(quad);

	const noiseQuadMaterial = new THREE.ShaderMaterial({
		uniforms: {
			tDiffuse: { value: rtTexture.texture },
			tDither: { value: rtNoiseSphere.texture }
		},
		vertexShader: vertexShader,
		fragmentShader: fragmentDitherTexture,
		depthWrite: false
	});

	const noiseQuad = new THREE.Mesh(plane, noiseQuadMaterial);
	noiseQuad.position.z = -100;
	sceneNoiseRTT.add(noiseQuad);

	const torusGeometry = new THREE.TorusGeometry(5, 1, 15, 30);

	const mat1 = new THREE.MeshPhongMaterial({ color: 0x555555, specular: 0xffaa00, shininess: 5 });
	const mat2 = new THREE.MeshPhongMaterial({ color: 0x550000, specular: 0xff2200, shininess: 5 });

	const noiseMaterial = new THREE.ShaderMaterial({
		uniforms: {
			iResolution: { value: new THREE.Vector3() },
			iTime: { value: 0 },
			opacity: { value: 1 }
		},
		fragmentShader: noiseFragment,
		vertexShader: noiseVertex,
		side: THREE.DoubleSide
	});

	const noiseSphere = new THREE.Mesh(new THREE.SphereGeometry(1000, 50, 50), noiseMaterial);
	noiseSphere.position.set(0, 0, 100);
	sceneNoise.add(noiseSphere);

	const zmesh1 = new THREE.Mesh(torusGeometry, mat1);
	zmesh1.position.set(0, 0, 50);
	zmesh1.scale.set(5, 5, 5);
	sceneRTT.add(zmesh1);

	const zmesh2 = new THREE.Mesh(torusGeometry, mat2);
	zmesh2.position.set(0, 150, 100);
	zmesh2.scale.set(0.75, 0.75, 0.75);
	sceneRTT.add(zmesh2);

	const quad2 = new THREE.Mesh(plane, materialScreen);
	quad2.position.z = -100;
	sceneScreen.add(quad2);

	let delta = 0;

	let threlteCamera: PerspectiveCamera;

	//@ts-ignore
	const composer = new EffectComposer(renderer);
	const renderPass = new RenderPass(scene, pCamera);

	const DitherShader = {
		uniforms: {
			tDiffuse: { value: null },
			opacity: { value: 1.0 },
			iResolution: { value: new THREE.Vector3() },
			iTime: { value: 0 },
			tNoise: { value: rtTexture.texture }
		},

		vertexShader: /* glsl */ `
  varying vec2 vUv;
  void main() {
    vUv = uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
  }`,

		fragmentShader: ditherFrag
	};

	const ditherPass = new ShaderPass(DitherShader);

	composer.addPass(renderPass);
	composer.addPass(ditherPass);

	useFrame(({ clock }) => {
		noiseMaterial.uniforms.iTime.value = clock.getElapsedTime();
		noiseMaterial.uniforms.iResolution.value.set(
			renderer?.domElement.width,
			renderer?.domElement.height,
			1
		);

		if (!renderer) return;
		renderer.autoClear = false;
		const time = Date.now() * 0.0015;
		pCamera.position.x += (0 - pCamera.position.x) * 0.05;
		pCamera.position.y += (0 - pCamera.position.y) * 0.05;
		pCamera.lookAt(scene.position);
		if (zmesh1 && zmesh2) {
			// zmesh1.rotation.y = -time;
			// zmesh2.rotation.y = -time + Math.PI / 2;
		}
		if (material.uniforms['time'].value > 1 || material.uniforms['time'].value < 0) {
			delta *= -1;
		}
		material.uniforms['time'].value += delta;

		ditherPass.uniforms.iResolution.value.set(
			renderer?.domElement.width,
			renderer?.domElement.height,
			1
		);
		noiseMaterial.uniforms.iResolution.value.set(
			renderer?.domElement.width,
			renderer?.domElement.height,
			1
		);

		ditherPass.uniforms.iTime.value = clock.getElapsedTime();
		// Render noiseSphere into texture
		renderer.setRenderTarget(rtNoiseSphere);
		renderer.clear();
		renderer.render(sceneNoise, threlteCamera);

		// Render first scene into texture
		renderer.setRenderTarget(rtTexture);
		renderer.clear();
		renderer.render(sceneRTT, threlteCamera);

		// Render full screen quad with generated texture

		renderer.setRenderTarget(null);
		renderer.clear();
		// renderer.render(sceneScreen, cameraRTT);

		// Render second scene to screen
		// (using first scene as regular texture)

		// renderer.render(scene, pCamera);
		renderer.render(sceneNoiseRTT, cameraRTT);

		renderPass.camera = cameraRTT;
		renderPass.scene = sceneScreen;

		//@ts-ignore
		noiseSphere.position.set(...threlteCamera.position);
		noiseSphere.rotation.set(...threlteCamera.rotation);
		// composer.render(scene, cameraRTT);
	});
</script>

<T.PerspectiveCamera
	position={[-10, 10, -100]}
	fov={24}
	let:ref
	bind:ref={threlteCamera}
	makeDefault
>
	<OrbitControls enableZoom={true} target={{ y: 0.5 }} autoRotate />
</T.PerspectiveCamera>

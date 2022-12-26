<script lang="ts">
	import { useFrame, useThrelte, T, OrbitControls, useTexture } from '@threlte/core';
	import { get } from 'svelte/store';
	import { MeshLambertMaterial, Vector3, type PerspectiveCamera } from 'three';
	import * as THREE from 'three';

	import { EffectComposer } from 'three/examples/jsm/postprocessing/EffectComposer.js';
	import { RenderPass } from 'three/examples/jsm/postprocessing/RenderPass.js';
	import { default as noiseFragment2 } from './noiseMaterialFS2.glsl?raw';
	import { default as noiseVertex } from './noiseMaterialVS.glsl?raw';
	import { default as fragmentDitherTexture } from './ditherTexture.glsl?raw';
	import CustomShaderMaterial from 'three-custom-shader-material/vanilla';
	import { FBXLoader } from 'three/examples/jsm/loaders/FBXLoader';
	const fragmentShaderScreen = `  
  varying vec2 vUv;
  uniform sampler2D tDiffuse;

  void main() {

    gl_FragColor = texture2D( tDiffuse, vUv );

  }`;

	const vertexShader = `
  varying vec2 vUv;
  void main() {

    vUv = uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

  }
`;

	const bluenoise = useTexture('bluenoise2.png');

	const ctx = useThrelte();
	const { renderer, camera } = ctx;

	const pCamera = new THREE.PerspectiveCamera(30, window.innerWidth / window.innerHeight, 0, 10000);
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
	light.position.set(10, 10, 50);
	sceneRTT.add(light);

	light = new THREE.DirectionalLight(0xffaaaa, 4.5);
	light.position.set(-2, 10, -10);
	sceneRTT.add(light);

	const rtTexture = new THREE.WebGLRenderTarget(
		renderer?.domElement.width,
		renderer?.domElement.height
	);

	const rtNoiseMask = new THREE.WebGLRenderTarget(
		renderer?.domElement.width,
		renderer?.domElement.height
	);

	const materialScreen = new THREE.ShaderMaterial({
		uniforms: { tDiffuse: { value: rtTexture.texture } },
		vertexShader: vertexShader,
		fragmentShader: fragmentShaderScreen,
		depthWrite: false
	});
	const plane = new THREE.PlaneGeometry(window.innerWidth, window.innerHeight);

	const noiseQuadMaterial = new THREE.ShaderMaterial({
		uniforms: {
			tDiffuse: { value: rtTexture.texture },
			tDither: { value: rtNoiseMask.texture }
		},
		vertexShader: vertexShader,
		fragmentShader: fragmentDitherTexture,
		depthWrite: false
	});

	const noiseQuad = new THREE.Mesh(plane, noiseQuadMaterial);
	noiseQuad.position.z = -100;
	sceneNoiseRTT.add(noiseQuad);

	let blacksmith;

	const loader = new FBXLoader();
	loader.load(
		'assets/buildings/Blacksmith.fbx',
		function (fbx) {
			blacksmith = fbx;
			blacksmith.scale.set(0.03, 0.03, 0.03);

			const clone = blacksmith.clone(true);

			const materialArray = [];
			for (let i = 0; i < blacksmith.children[0].material.length; i++) {
				const newNoise = new THREE.ShaderMaterial({
					uniforms: {
						iResolution: { value: new THREE.Vector3() },
						tDiffuse: { value: null },
						iTime: { value: 0 },
						opacity: { value: 1 },
						uNoiseTex: { value: bluenoise }
					},
					fragmentShader: noiseFragment2,
					vertexShader: noiseVertex,
					side: THREE.DoubleSide
				});
				newNoise.uniforms.iResolution.value.set(
					renderer?.domElement.width,
					renderer?.domElement.height,
					1
				);
				materialArray.push(newNoise);
			}

			blacksmith.children[0].material = materialArray;
			sceneNoise.add(blacksmith);

			sceneRTT.add(clone);

			console.log(blacksmith.children[0].material, clone.children[0].material);
		},
		undefined,
		function (error) {
			console.error(error);
		}
	);

	const mat1 = new THREE.MeshPhongMaterial({ color: 0x555555, specular: 0xffaa00, shininess: 5 });

	const noiseMaterial = new THREE.ShaderMaterial({
		uniforms: {
			iResolution: { value: new THREE.Vector3() },
			tDiffuse: { value: null },
			iTime: { value: 0 },
			opacity: { value: 1 },
			uNoiseTex: { value: bluenoise }
		},
		fragmentShader: noiseFragment2,
		vertexShader: noiseVertex,
		side: THREE.DoubleSide
	});
	noiseMaterial.uniforms.iResolution.value.set(
		renderer?.domElement.width,
		renderer?.domElement.height,
		1
	);
	const box = new THREE.BoxGeometry(15, 1, 15);
	const noiseBox = new THREE.Mesh(box, noiseMaterial);
	noiseBox.position.set(0, -0.5, 0);
	sceneNoise.add(noiseBox);

	const zmesh1 = new THREE.Mesh(box, mat1);
	zmesh1.position.set(0, -0.5, 0);
	sceneRTT.add(zmesh1);

	const quad2 = new THREE.Mesh(plane, materialScreen);
	quad2.position.z = -100;
	sceneScreen.add(quad2);

	let delta = 0;

	let threlteCamera: PerspectiveCamera;

	import { default as dpasfrag } from './ditherPass.glsl?raw';

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

		fragmentShader: dpasfrag
	};
	import { ShaderPass } from 'three/examples/jsm/postprocessing/ShaderPass';
	const ditherPass = new ShaderPass(DitherShader);

	//@ts-ignore
	const composer = new EffectComposer(renderer);
	const renderPass = new RenderPass(sceneNoiseRTT, cameraRTT);
	composer.addPass(renderPass);
	// composer.addPass(ditherPass);

	useFrame(({ clock }) => {
		ditherPass.uniforms.iResolution.value.set(
			renderer?.domElement.width,
			renderer?.domElement.height,
			1
		);
		ditherPass.uniforms.iTime.value = clock.getElapsedTime();
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

		noiseMaterial.uniforms.iResolution.value.set(
			renderer?.domElement.width,
			renderer?.domElement.height,
			1
		);
		// Render noiseSphere into texture

		renderer.setRenderTarget(rtNoiseMask);
		renderer.clear();
		renderer.render(sceneNoise, threlteCamera);

		// Render first scene into texture
		renderer.setRenderTarget(rtTexture);
		renderer.clear();
		renderer.render(sceneRTT, threlteCamera);

		// Render full screen quad with generated texture
		renderer.setRenderTarget(null);
		renderer.clear();
		renderer.render(sceneScreen, cameraRTT);

		// renderer.render(sceneNoise, threlteCamera);

		// Render second scene to screen
		// (using first scene as regular texture)

		// renderer.render(scene, pCamera);
		// renderer.render(sceneNoise, threlteCamera);

		// renderPass.camera = cameraRTT;
		// renderPass.scene = sceneScreen;

		//@ts-ignore
		// noiseSphere.position.set(...threlteCamera.position);
		// noiseSphere.rotation.set(...threlteCamera.rotation);
		composer.render(sceneNoiseRTT, cameraRTT);
	});
</script>

<T.PerspectiveCamera
	position={[20, 25, 45]}
	fov={12}
	bind:ref={threlteCamera}
	makeDefault
	args={[30, undefined, 0.1]}
>
	<OrbitControls enableZoom={true} target={{ y: 0.5 }} autoRotateSpeed={0.2} autoRotate />
</T.PerspectiveCamera>

<script lang="ts">
	import { LayerableObject, OrbitControls, T, Three, useFrame, useThrelte } from '@threlte/core';
	import { FBXLoader } from 'three/examples/jsm/loaders/FBXLoader';
	import { degToRad } from 'three/src/math/MathUtils';
	import CustomShaderMaterial from 'three-custom-shader-material/vanilla';
	import { MeshLambertMaterial, MeshToonMaterial, type Group } from 'three';
	import { default as extendedStandardVert } from './extendedStandardVert.glsl?raw';
	import { default as extendedStandardFrag } from './extendedStandardFrag.glsl?raw';

	console.log(MeshLambertMaterial);

	let blacksmith: Group | undefined;

	const { renderer, scene } = useThrelte();

	const loader = new FBXLoader();
	loader.load(
		'assets/buildings/Blacksmith.fbx',
		function (fbx) {
			blacksmith = fbx;

			const material = new MeshLambertMaterial({ color: 'white' });

			const ditherMaterial = new CustomShaderMaterial({
				baseMaterial: MeshToonMaterial,
				color: 'orange',
				vertexShader: extendedStandardVert,
				fragmentShader: extendedStandardFrag
			});

			console.log(ditherMaterial);

			for (let i = 0; i < blacksmith.children[0].material.length; i++) {
				blacksmith.children[0].material[i] = ditherMaterial;
			}
		},
		undefined,
		function (error) {
			console.error(error);
		}
	);
	//https://www.shadertoy.com/view/Xl3czS
	useFrame(({ clock }) => {
		if (!renderer) return;

		// noiseMaterial.uniforms.iResolution.value.set(
		// 	renderer?.domElement.width,
		// 	renderer?.domElement.height,
		// 	1
		// );
		// ditherPass.uniforms.iResolution.value.set(
		// 	renderer?.domElement.width,
		// 	renderer?.domElement.height,
		// 	1
		// );
		// noiseMaterial.uniforms.iTime.value = clock.getElapsedTime();
		// ditherPass.uniforms.iTime.value = clock.getElapsedTime();

		// if (camera) camPosition = Object.values(camera.position);
	});

	let cc;
</script>

<T.PerspectiveCamera position={[3, 1.5, 5]} fov={30} let:ref makeDefault>
	<OrbitControls
		maxPolarAngle={degToRad(80)}
		enableZoom={true}
		target={{ y: 0.5 }}
		autoRotate
		autoRotateSpeed={0.3}
	/>
	<LayerableObject object={ref} />
</T.PerspectiveCamera>

<T.DirectionalLight position={[3, 10, 10]} intensity={0.5} />
<T.DirectionalLight position={[-3, 10, -10]} intensity={0.2} />
<T.AmbientLight intensity={0.2} />

<T.Group let:ref>
	<T.Mesh position.y={0.5} castShadow let:ref>
		<T.BoxGeometry />
		<T.MeshStandardMaterial color="#eeaa22" />
	</T.Mesh>
	<LayerableObject object={ref} />
</T.Group>

<T.Mesh receiveShadow rotation.x={degToRad(-90)}>
	<T.CircleGeometry args={[1, 72]} />
	<T.MeshStandardMaterial color="white" />
</T.Mesh>

{#if blacksmith}
	<!-- <Three type={blacksmith} scale={0.01} castShadow /> -->
{/if}

<!-- <T.Mesh castShadow let:ref material={noiseMaterial} position={camPosition}>
	<T.SphereGeometry args={[50, 200, 200]} />
</T.Mesh> -->

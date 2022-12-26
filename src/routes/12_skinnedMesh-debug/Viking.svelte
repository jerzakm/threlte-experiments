<script lang="ts">
	import { Three, useFrame, T } from '@threlte/core';
	import {
		Group,
		LoadingManager,
		MeshBasicMaterial,
		MeshStandardMaterial,
		Skeleton,
		SphereGeometry,
		Vector3
	} from 'three';
	import { AnimationMixer } from 'three';
	import { FBXLoader } from 'three/examples/jsm/loaders/FBXLoader.js';

	//https://stackoverflow.com/questions/36461699/three-js-get-updated-vertices-with-morph-targets

	// https://stackoverflow.com/questions/57332347/three-js-get-updated-vertices-with-skeletal-animations

	const loadingManager = new LoadingManager();

	export let testBall: any;

	let position: [number, number, number] = [0, 0, 0];
	let leftFootPosition: [number, number, number] = [0, 0, 0];

	let vikingThree;

	loadingManager.setURLModifier(function (url) {
		// this function is called for each asset request

		url = url.replace('U:/Dropbox/SyntyStudios/PolygonVikings/_working/Mike/Characters/', '');

		return url;
	});

	let viking: Group;
	let mixer: AnimationMixer;

	const loader = new FBXLoader(loadingManager);

	loader.load('assets/characters/Walking_viking.fbx', function (object) {
		mixer = new AnimationMixer(object);
		const action = mixer.clipAction(object.animations[0]);
		action.play();
		object.traverse(function (child) {
			if (child.isMesh) {
				child.castShadow = true;
				child.receiveShadow = true;
			}
		});
		viking = object;
	});

	useFrame(({ clock }) => {
		if (mixer) {
			mixer.update(0.005);
		}
	});
</script>

{#if viking}
	<Three type={viking} {position} bind:ref={vikingThree} scale={1} />
	<T.Mesh position={leftFootPosition}>
		<T.SphereGeometry args={[0.125, 10, 10]} />
		<T.MeshBasicMaterial color={'red'} />
	</T.Mesh>
{/if}

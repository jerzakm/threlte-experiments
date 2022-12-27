<script lang="ts">
	import { Instance, InstancedMesh, T, Three, useFrame, useThrelte } from '@threlte/core';
	import { Mesh } from 'three';
	import {
		AnimationMixer,
		CircleGeometry,
		DoubleSide,
		Group,
		LoadingManager,
		MeshBasicMaterial,
		MeshStandardMaterial,
		SkinnedMesh,
		SphereGeometry,
		Vector3
	} from 'three';
	import { FBXLoader } from 'three/examples/jsm/loaders/FBXLoader.js';

	import * as THREE from 'three';
	// import { SceneUtils } from 'three/examples/jsm/utils/SceneUtils';

	const getVertexPosition = function (skin: SkinnedMesh, index: number) {
		const skinIndices = new THREE.Vector4().fromBufferAttribute(
			skin.geometry.getAttribute('skinIndex') as THREE.BufferAttribute,
			index
		);

		const skinWeights = new THREE.Vector4().fromBufferAttribute(
			skin.geometry.getAttribute('skinWeight') as THREE.BufferAttribute,
			index
		);
		const skinVertex = new THREE.Vector3()
			.fromBufferAttribute(skin.geometry.getAttribute('position'), index)
			.applyMatrix4(skin.bindMatrix);
		const result = new THREE.Vector3(),
			temp = new THREE.Vector3(),
			tempMatrix = new THREE.Matrix4();
		const properties = ['x', 'y', 'z', 'w'];
		for (let i = 0; i < 4; i++) {
			const boneIndex = skinIndices[properties[i]];
			tempMatrix.multiplyMatrices(
				skin.skeleton.bones[boneIndex].matrixWorld,
				skin.skeleton.boneInverses[boneIndex]
			);

			result.add(
				temp.copy(skinVertex).applyMatrix4(tempMatrix).multiplyScalar(skinWeights[properties[i]])
			);
		}
		return result.applyMatrix4(skin.bindMatrixInverse);
	};

	let debugMesh: Mesh;

	//https://stackoverflow.com/questions/36461699/three-js-get-updated-vertices-with-morph-targets
	// https://stackoverflow.com/questions/57332347/three-js-get-updated-vertices-with-skeletal-animations
	//https://github.com/mrdoob/three.js/issues/3187

	const loadingManager = new LoadingManager();

	let position: [number, number, number] = [0, 0, 0];

	let vikingThree: Group;

	loadingManager.setURLModifier(function (url) {
		// this function is called for each asset request

		url = url.replace('U:/Dropbox/SyntyStudios/PolygonVikings/_working/Mike/Characters/', '');

		return url;
	});

	let viking: Group;
	let mixer: AnimationMixer;

	const loader = new FBXLoader(loadingManager);

	let targetArray: Vector3[] = [];
	let vertexPositionArray: [number, number, number][] = [];
	let bonePreviewHelpers: Mesh[] = [];
	let bonePreviewHelperPositions: Vector3[] = [];

	let skinnedMesh: SkinnedMesh;

	loader.load('assets/characters/Walking_viking.fbx', function (object) {
		mixer = new AnimationMixer(object);
		const action = mixer.clipAction(object.animations[0]);
		action.play();
		object.traverse(function (child: any) {
			if (child.isSkinnedMesh) {
				skinnedMesh = child;

				// for (let i = 0; i < skinnedMesh.geometry.attributes.position.count; i++) {
				// 	let target = new Vector3();
				// 	target = target.fromBufferAttribute(child.geometry.attributes.position, i);
				// 	targetArray.push(target);

				// 	positionArray.push([Math.random() * 2, Math.random() * 2, Math.random() * 2]);
				// }
				// for (let i = 0; i < skinnedMesh.geometry.attributes.position.count; i++) {
				// 	const r = transformedSkinVertex(skinnedMesh, i).multiply(new Vector3(0.01, 0.01, 0.01));
				// 	positionArray.push(r.toArray());
				// }

				// positionArray = positionArray;
			}
		});
		viking = object;
		targetArray = targetArray;
		vertexPositionArray = vertexPositionArray;
	});

	const cg = new SphereGeometry(3, 5, 5);
	const cm = new MeshStandardMaterial({ color: 'white', side: DoubleSide });

	debugMesh = new Mesh(cg, cm);

	const { scene } = useThrelte();

	scene.add(debugMesh);

	$: {
		if (skinnedMesh && debugMesh) {
			console.log(skinnedMesh);

			skinnedMesh.material.transparent = true;
			skinnedMesh.material.opacity = 0.5;
			const bone = skinnedMesh.skeleton.getBoneByName('LowerLeg_L');
			bone?.add(debugMesh);
			for (const bone of skinnedMesh.skeleton.bones) {
				const bonePreviewMesh = new Mesh(cg, cm);
				bone.add(bonePreviewMesh);
				bonePreviewHelpers.push(bonePreviewMesh);
				bonePreviewHelperPositions.push(new Vector3(0));
			}
		}
	}

	let tempCounter = 0;

	useFrame(({ clock }) => {
		tempCounter++;
		// console.log(debugMesh.getWorldPosition(new Vector3()));
		if (mixer) {
			for (let i = 0; i < bonePreviewHelpers.length; i++) {
				// bonePreviewHelpers[i].getWorldPosition(bonePreviewHelperPositions[i]);
			}
			// bonePreviewHelperPositions = bonePreviewHelperPositions;
			mixer.update(0.005);
			const mod = 36;
			if (skinnedMesh && tempCounter % 5 == 0) {
				for (let i = 0; i < skinnedMesh.geometry.attributes.position.count; i++) {
					if (skinnedMesh.geometry.attributes.position.count % mod == 0) {
						const r = getVertexPosition(skinnedMesh, i).multiply(new Vector3(0.01, 0.01, 0.01));
						vertexPositionArray[i / mod] = r.toArray();
					}
				}
				for (let i = 0; i < targetArray.length; i++) {
					// positionArray[i] = skinnedMesh
					// 	.boneTransform(i, targetArray[i])
					// 	.multiply(new Vector3(0.025, 0.025, 0.025))
					// 	.toArray();

					if (i == 300) {
						// console.log(targetArray[i]);
					}
				}
			}
		}
	});
</script>

<!-- <T.Mesh {position} material={cm} geometry={cg} bind:ref={debugMesh} scale={[50, 50, 50]} /> -->

{#if viking}
	<Three type={viking} {position} bind:ref={vikingThree} scale={1} />
{/if}

<T.Group rotation={[0, 0, 0]} position={[1, 0, 0]}>
	<!-- <InstancedMesh material={cm} geometry={cg}>
		{#each vertexPositionArray as position, i}
			<Instance
				position={{
					x: position[0],
					y: position[1],
					z: position[2]
				}}
			/>
		{/each}
	</InstancedMesh> -->
</T.Group>

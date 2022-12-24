<script lang="ts">
	import { T, OrbitControls, useFrame, useThrelte } from '@threlte/core';
	import { BoxGeometry, DoubleSide, MeshStandardMaterial } from 'three';
	import { DEG2RAD } from 'three/src/math/MathUtils';
	import CSM from 'three-csm';
	import * as THREE from 'three';

	const columns = 10;
	const rows = 2;

	const ctx = useThrelte();
	const { camera, scene, renderer } = ctx;

	renderer.shadowMap.enabled = true;
	renderer.shadowMap.type = THREE.PCFSoftShadowMap;

	//@ts-ignore
	// THREE.CSM = CSM;

	//@ts-ignore
	const csm = new CSM({
		maxFar: 100,
		cascades: 8,
		shadowMapSize: 4096,
		lightDirection: new THREE.Vector3(2, -1, 3).normalize(),
		camera: $camera,
		parent: scene,
		shadowBias: 0,
		fade: true,
		mode: 'practical'
	});

	const planeMaterial = new MeshStandardMaterial({ color: 'red' });
	const columnMaterial = new MeshStandardMaterial({ color: 'white' });
	csm.setupMaterial(planeMaterial);
	csm.setupMaterial(columnMaterial);

	let t = 0;

	useFrame(({ clock }) => {
		//
		t = clock.elapsedTime;
		csm.update(camera.matrix);
	});
</script>

<T.PerspectiveCamera position={[60, 25, 15]} fov={30} let:ref makeDefault>
	<OrbitControls enableZoom={true} target={{ y: 0.5 }} autoRotate autoRotateSpeed={0.0} />
</T.PerspectiveCamera>

<!-- <T.DirectionalLight position={[3, 10, 10]} intensity={0.5} castShadow /> -->
<!-- <T.DirectionalLight position={[-3, 10, -10]} intensity={0.2} castShadow /> -->
<T.AmbientLight intensity={0.2} />

<T.Mesh receiveShadow rotation={[-DEG2RAD * 90, 0, 0]} material={planeMaterial}>
	<T.CircleGeometry args={[40, 72]} />
</T.Mesh>

{#each { length: columns } as i, x}
	{#each { length: rows } as j, y}
		<T.Mesh
			position={[x * 3 + Math.cos(t * y), 1.5 + Math.sin(t + x + y) * 0.1, y * 4 - rows]}
			castShadow
			receiveShadow
			material={columnMaterial}
		>
			<T.SphereGeometry args={[1, 5, 1]} />
		</T.Mesh>
	{/each}
{/each}

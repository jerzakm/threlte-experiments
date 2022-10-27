<script lang="ts">
	import { Mesh, OrbitControls, PerspectiveCamera, useFrame } from '@threlte/core';
	import { Environment } from '@threlte/extras';
	import { get } from 'svelte/store';
	import { BoxGeometry, MeshStandardMaterial, Vector3 } from 'three';

	export let elementToFollow: HTMLElement | undefined;

	let pos = new Vector3();

	let rotation = 0;

	useFrame(({ camera }) => {
		if (elementToFollow) {
			const boundingRect = elementToFollow.getBoundingClientRect();

			// normalize client pos
			const x = (boundingRect.x / window.innerWidth) * 2 - 1;
			const y = -(boundingRect.y / window.innerHeight) * 2 + 1;
			// https://threejs.org/docs/#api/en/math/Vector3.unproject
			const cam = get(camera);
			const vector = new Vector3(x, y, 1);
			vector.unproject(cam);

			const direction = vector.sub(cam.position).normalize();
			const distance = -cam.position.z / direction.z;
			pos = cam.position.clone().add(direction.multiplyScalar(distance));

			rotation += 0.01;
		}
	});
</script>

<PerspectiveCamera position={{ x: 5, y: 0, z: 15 }} fov={60} near={1} far={20000}>
	<OrbitControls autoRotate={false} enableZoom={true} target={{ x: 50, y: 20, z: 0 }} />
</PerspectiveCamera>

<Environment path="/03_env/" files="spaichingen_hill_1k.hdr" />

<Mesh
	material={new MeshStandardMaterial({ color: 0xffffff })}
	geometry={new BoxGeometry(2, 2, 2)}
	rotation={{ x: rotation, y: Math.sin(rotation) }}
/>

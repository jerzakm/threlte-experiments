<script lang="ts">
	import { Group, useFrame } from '@threlte/core';
	import { get } from 'svelte/store';
	import { Camera, Object3D, Vector3, Group as ThreeGroup } from 'three';

	function inHandPositionCalc(camera: Camera, card: Object3D, i: number, cardsCount: number) {
		const dist = 10 - i * 0.01;
		const cwd = new Vector3();

		camera.getWorldDirection(cwd);

		cwd.multiplyScalar(dist);
		cwd.add(camera.position);

		// card.position.set(cwd.x + i * 0.3, cwd.y - 2.5 - Math.abs(i / cardsNumber - 0.5) * 0.5, cwd.z);
		card.position.set(cwd.x, cwd.y, cwd.z);
		card.setRotationFromQuaternion(camera.quaternion);
		card.rotateZ(-0.025 * (i - Math.round(cardsCount * 0.5)));
		card.translateX(i * (cardsCount - 45) ** 2 * 0.0003 - 2);

		card.translateY(-1.7);
	}

	let inhandGroup: ThreeGroup;

	useFrame(({ camera }) => {
		if (inhandGroup) {
			for (let i = 0; i < inhandGroup.children.length; i++) {
				inHandPositionCalc(get(camera), inhandGroup.children[i], i, inhandGroup.children.length);
			}
		}
	});
</script>

<Group bind:group={inhandGroup}>
	<slot />
</Group>

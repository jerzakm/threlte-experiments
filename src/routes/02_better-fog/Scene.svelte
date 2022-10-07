<script lang="ts">
	import {
		AmbientLight,
		DirectionalLight,
		Group,
		Mesh,
		OrbitControls,
		PerspectiveCamera,
		useFrame
	} from '@threlte/core';
	import {
		BackSide,
		BoxGeometry,
		ConeGeometry,
		MeshStandardMaterial,
		PlaneGeometry,
		SphereGeometry
	} from 'three';
	import { DEG2RAD } from 'three/src/math/MathUtils';
	import { registerMaterial } from './betterFog';
	import BetterFog from './BetterFog.svelte';

	let rotation = 0;

	const trunkMat = new MeshStandardMaterial({ color: 0x808080 });
	const leavesMat = new MeshStandardMaterial({ color: 0x80ff80 });
	const trunkGeo = new BoxGeometry(1, 1, 1);
	const leavesGeo = new ConeGeometry(1, 1, 32);

	const skyMaterial = new MeshStandardMaterial({ color: 0x808080, side: BackSide });
	const groundMaterial = new MeshStandardMaterial({ color: 0x121212 });
	skyMaterial.onBeforeCompile = registerMaterial;
	groundMaterial.onBeforeCompile = registerMaterial;
	trunkMat.onBeforeCompile = registerMaterial;
	leavesMat.onBeforeCompile = registerMaterial;

	useFrame(({ clock }) => {
		rotation += 0.002;
	});
</script>

<BetterFog density={0.0001} opacity={0.8} speed={0.1} />

<PerspectiveCamera position={{ x: 75, y: 20, z: 0 }} fov={60} near={1} far={20000}>
	<OrbitControls autoRotate={false} enableZoom={true} target={{ x: 0, y: 20, z: 0 }} />
</PerspectiveCamera>
<Group rotation={{ y: rotation }} />

<!-- sky -->
<Mesh geometry={new SphereGeometry(10000, 32, 32)} material={skyMaterial} />

<!-- objects -->
{#each { length: 45 } as i, x}
	{#each { length: 45 } as j, y}
		{@const scale = (Math.random() + 1.0) * 100.0}
		{@const posX = 7000.0 * (Math.random() * 2.0 - 1.0)}
		{@const posY = 7000.0 * (Math.random() * 2.0 - 1.0)}
		<Mesh
			material={trunkMat}
			geometry={trunkGeo}
			scale={{ x: 50, y: scale, z: 50 }}
			position={{
				x: posX,
				y: scale / 2.0,
				z: posY
			}}
		/>
	{/each}
{/each}

<!-- ground -->
<Mesh
	receiveShadow
	material={groundMaterial}
	geometry={new PlaneGeometry(20000, 20000, 300, 300)}
	rotation={{ x: DEG2RAD * -90 }}
/>

<DirectionalLight
	shadow
	position={{ x: 20, y: 100, z: 10 }}
	color={0xffffff}
	intensity={1}
	target={{ x: 0, y: 0, z: 0 }}
/>
<AmbientLight intensity={0.5} color={0x101010} />

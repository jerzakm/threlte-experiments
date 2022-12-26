<script lang="ts">
	import { OrbitControls, T, useFrame } from '@threlte/core';
	import { Environment, Grid } from '@threlte/extras';
	import { Collider, Debug, World } from '@threlte/rapier';
	import { DoubleSide } from 'three';
	import Viking from './Viking.svelte';

	let buttons: { [key: string]: boolean } = {};
	window.addEventListener('keydown', (e) => {
		buttons[e.key] = true;
		buttons = buttons;
	});
	window.addEventListener('keyup', (e) => {
		buttons[e.key] = false;
		buttons = buttons;
	});

	useFrame(({ clock, composer }) => {
		const impulseVector = {
			x: 0,
			y: 0,
			z: 0
		};
		const impulseStrength = 2 ** (2 + 1);

		if (buttons.s) {
			impulseVector.z += impulseStrength;
		}
		if (buttons.w) {
			impulseVector.z -= impulseStrength;
		}

		if (buttons.d) {
			impulseVector.x += impulseStrength;
		}
		if (buttons.a) {
			impulseVector.x -= impulseStrength;
		}
	});
</script>

<T.PerspectiveCamera let:ref position={[5, 3, 0]} fov={30} far={99999} makeDefault>
	<OrbitControls enableZoom={true} target={{ x: 0, y: 0.33, z: 0 }} />
</T.PerspectiveCamera>

<Environment files="03_env/belfast_sunset_puresky_4k.hdr" isBackground />
<Grid sectionColor={'black'} sectionSize={10} />

<World
	gravity={{
		x: 0,
		y: -20,
		z: 0
	}}
>
	<!-- World borders -->
	<Collider shape={'cuboid'} args={[20, 0.5, 20]} position={{ x: 0, y: -1, z: 0 }} />

	<Viking />

	<!-- {#if terrainPhysicsGeometry}
		<Collider
			shape={'trimesh'}
			args={[terrainPhysicsGeometry.attributes.position.array, terrainPhysicsGeometry.index.array]}
			bind:collider={terrainCollider}
		/>
		{#each balls as ball}
			<RigidBody position={ball.startingPosition} type="dynamic" bind:rigidBody={ball.rigidBody}>
				<AutoColliders shape={'ball'} restitution={0.9}>
					<T.Mesh castShadow receiveShadow>
						<T.SphereGeometry args={[ball.size, 15, 15]} />
						<T.MeshStandardMaterial color={'blue'} />
					</T.Mesh>
				</AutoColliders>
			</RigidBody>
		{/each}
	{/if} -->

	{#if true}
		<Debug depthTest={true} depthWrite={true} side={DoubleSide} />
	{/if}
</World>

<T.DirectionalLight position={[40, 50, 50]} intensity={0.2} castShadow />
<T.DirectionalLight position={[200, 80, 200]} intensity={0.2} castShadow />
<T.AmbientLight intensity={0.2} />

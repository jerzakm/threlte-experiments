<script lang="ts">
	import { OrbitControls, T, useFrame } from '@threlte/core';
	import { decodeTerrainFromTile, genMartiniTerrain } from '$lib/martiniTerrain';
	import { Environment } from '@threlte/extras';
	import type { BufferGeometry } from 'three';
	import { AutoColliders, Collider, Debug, World, RigidBody, Attractor } from '@threlte/rapier';
	import Postprocessing from './Postprocessing.svelte';
	import SnowTerrain from './SnowTerrain.svelte';
	import { DoubleSide } from 'three';
	import type { RigidBody as RapierRigidBody } from '@dimforge/rapier3d-compat';

	interface Ball {
		startingPosition: { x: number; y: number; z: number };
		size: number;
		rigidBody?: RapierRigidBody;
	}

	let balls: Ball[] = [
		{
			startingPosition: { x: 200, y: 50, z: 80 },
			size: 5,
			rigidBody: undefined
		}
	];

	let testBall = balls[0];

	let buttons: { [key: string]: boolean } = {};

	window.addEventListener('keydown', (e) => {
		buttons[e.key] = true;
		buttons = buttons;
	});

	window.addEventListener('keyup', (e) => {
		buttons[e.key] = false;
		buttons = buttons;
	});

	let spawnTimer = 0;
	let elapsedTime = 0;

	let lookAt = { x: testBall.startingPosition.x, y: 0.5, z: testBall.startingPosition.z };

	useFrame(({ clock, composer }) => {
		if (balls[0].rigidBody) {
			lookAt = balls[0].rigidBody.translation();
		}
		elapsedTime = clock.elapsedTime;
		const impulseVector = {
			x: 0,
			y: 0,
			z: 0
		};

		const impulseStrength = 2 ** (testBall.size + 1);

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
		if (testBall.rigidBody) {
			testBall.rigidBody.applyImpulse(impulseVector, true);
		}

		spawnTimer += clock.getDelta() * 1000;

		if (balls.length < 16 && spawnTimer > 0.2) {
			balls.push({
				startingPosition: { x: 20 + Math.random() * 200, y: 50, z: 20 + Math.random() * 200 },
				size: 4,
				rigidBody: undefined
			});
			balls = balls;

			spawnTimer = 0;
		}
	});

	let terrainGeometry: BufferGeometry;
	let terrainPhysicsGeometry: BufferGeometry;

	let terrain: Float32Array;

	const img = new Image(); // Create new img element
	img.src = 'fuji_terraintile.png';
	img.addEventListener('load', (e) => {
		terrain = decodeTerrainFromTile(img);
		terrainPhysicsGeometry = genMartiniTerrain(terrain, img.width, 50);
		terrainGeometry = genMartiniTerrain(terrain, img.width, 10);
	});

	let terrainCollider: any;
</script>

<T.PerspectiveCamera
	let:ref
	position={[150 + lookAt.x * 0.25, 75, 150 + lookAt.z * 0.25]}
	fov={30}
	far={99999}
	makeDefault
>
	<OrbitControls enableZoom={true} target={lookAt} />
</T.PerspectiveCamera>

<!-- <Environment files="03_env/belfast_sunset_puresky_4k.hdr" isBackground /> -->

<World
	gravity={{
		x: 0,
		y: -20,
		z: 0
	}}
>
	<!-- World borders -->
	<Collider shape={'cuboid'} args={[128, 300, 5]} position={{ x: 128, y: 150, z: 0 }} />

	<Collider shape={'cuboid'} args={[300, 10, 300]} position={{ x: 0, y: 150, z: 0 }} />
	<Collider shape={'cuboid'} args={[128, 300, 5]} position={{ x: 128, y: 150, z: 256 }} />
	<Collider shape={'cuboid'} args={[5, 300, 128]} position={{ x: 0, y: 150, z: 128 }} />
	<Collider shape={'cuboid'} args={[5, 300, 128]} position={{ x: 256, y: 150, z: 128 }} />
	{#if terrainPhysicsGeometry}
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
	{/if}

	<!-- <Attractor
		range={256 * Math.sin(elapsedTime * 0.25)}
		strength={-500 * Math.sin(elapsedTime * 0.125)}
		position={{ x: 128, y: 200, z: 128 }}
	/> -->

	<Attractor range={380} strength={-3000} position={{ x: 600, y: 0, z: 128 }} />
	<Attractor range={380} strength={-3000} position={{ x: -600 + 256, y: 0, z: 128 }} />
	<Attractor range={380} strength={-3000} position={{ x: 128, y: 0, z: 600 }} />
	<Attractor range={380} strength={-3000} position={{ x: 128, y: 0, z: -600 + 256 }} />

	{#if false}
		<Debug depthTest={true} depthWrite={true} side={DoubleSide} />
	{/if}

	{#if terrainGeometry}
		<SnowTerrain {terrainGeometry} {testBall} {balls} {terrainCollider} />
	{/if}
</World>

<T.DirectionalLight position={[40, 50, 50]} intensity={0.2} castShadow />
<T.DirectionalLight position={[200, 80, 200]} intensity={0.2} castShadow />
<T.AmbientLight intensity={0.2} />

<Postprocessing />

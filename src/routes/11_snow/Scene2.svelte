<script lang="ts">
	import { OrbitControls, T, useFrame } from '@threlte/core';

	import { decodeTerrainFromTile, genMartiniTerrain } from '$lib/martiniTerrain';
	import { Environment } from '@threlte/extras';
	import type { BufferGeometry } from 'three';

	import { AutoColliders, Collider, RigidBody, World } from '@threlte/rapier';
	import Postprocessing from './Postprocessing.svelte';
	import SnowTerrain from './SnowTerrain.svelte';

	let balls = [
		{
			x: 200,
			y: 35,
			z: 80
		}
	];

	let testBall;

	let buttons: { [key: string]: boolean } = {};

	window.addEventListener('keydown', (e) => {
		buttons[e.key] = true;
		buttons = buttons;
	});

	window.addEventListener('keyup', (e) => {
		buttons[e.key] = false;
		buttons = buttons;
	});

	let bt = { x: 0, y: 0, z: 0 };

	let t = 0;

	useFrame(({ clock, composer }) => {
		t += clock.getDelta() * 1000;

		if (balls.length < 1) {
			balls.push({
				x: 200,
				y: 80,
				z: 80
			});
			balls = balls;
		}

		const impulseVector = {
			x: 0,
			y: 0,
			z: 0
		};

		const impulseStrength = 100;

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
		if (testBall) {
			testBall.applyImpulse(impulseVector, true);
		}
	});

	let terrainGeometry: BufferGeometry;
	let terrainPhysicsGeometry: BufferGeometry;

	const img = new Image(); // Create new img element
	img.src = 'fuji_terraintile.png';
	img.addEventListener('load', (e) => {
		const terrain = decodeTerrainFromTile(img);
		terrainPhysicsGeometry = genMartiniTerrain(terrain, img.width, 50);
		terrainGeometry = genMartiniTerrain(terrain, img.width, 10);

		console.log(terrainGeometry.attributes.uv.array.length);
	});
</script>

<T.PerspectiveCamera
	let:ref
	position={[200 + bt.x / 2, 100, 200 + bt.z / 2]}
	fov={20}
	far={99999}
	makeDefault
>
	<OrbitControls enableZoom={true} target={{ x: 0 + bt.x, y: 0.5, z: bt.z }} />
</T.PerspectiveCamera>

<T.PerspectiveCamera position={[200, 50, 200]} fov={30} far={99999}>
	<OrbitControls enableZoom={true} autoRotate autoRotateSpeed={0.0} />
</T.PerspectiveCamera>

<Environment files="03_env/belfast_sunset_puresky_4k.hdr" isBackground />

<World
	gravity={{
		x: 0,
		y: -20,
		z: 0
	}}
>
	{#if terrainPhysicsGeometry}
		<Collider
			shape={'trimesh'}
			args={[terrainPhysicsGeometry.attributes.position.array, terrainPhysicsGeometry.index.array]}
		/>
		{#each balls as ball}
			<RigidBody position={ball} type="dynamic" bind:rigidBody={testBall}>
				<AutoColliders shape={'ball'} restitution={0.6}>
					<T.Mesh castShadow receiveShadow>
						<T.SphereGeometry args={[5, 15, 15]} />
						<T.MeshStandardMaterial color={'blue'} />
					</T.Mesh>
				</AutoColliders>
			</RigidBody>
		{/each}
	{/if}

	<!-- <Debug depthTest={true} depthWrite={true} side={DoubleSide} /> -->
</World>

<T.DirectionalLight position={[40, 50, 50]} intensity={0.2} castShadow />
<T.DirectionalLight position={[200, 80, 200]} intensity={0.2} castShadow />
<T.AmbientLight intensity={0.2} />

<Postprocessing />

{#if terrainGeometry}
	<SnowTerrain {terrainGeometry} {testBall} />
{/if}

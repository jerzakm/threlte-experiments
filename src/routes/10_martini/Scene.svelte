<script lang="ts">
	import { decodeTerrainFromTile, genMartiniTerrain } from '$lib/martiniTerrain';
	import { OrbitControls, T, useFrame, useThrelte } from '@threlte/core';
	import { AutoColliders, Collider, RigidBody, World } from '@threlte/rapier';
	import { BufferAttribute, BufferGeometry, Color, DoubleSide, MeshStandardMaterial } from 'three';

	import { PCFSoftShadowMap, Vector3 } from 'three';
	import CSM from 'three-csm';

	let balls = [];

	let terrainGeometry: BufferGeometry;
	let terrainPhysicsGeometry: BufferGeometry;

	const img = new Image(); // Create new img element
	// img.src = 'fuji_terrainmap.png';
	img.src = 'fuji_terraintile.png';
	img.addEventListener('load', (e) => {
		const terrain = decodeTerrainFromTile(img);
		terrainPhysicsGeometry = genMartiniTerrain(terrain, img.width, 50);
		terrainGeometry = genMartiniTerrain(terrain, img.width, 0);
		console.log(terrainPhysicsGeometry);
	});

	const ctx = useThrelte();
	const { camera, scene, renderer } = ctx;

	const planeMaterial = new MeshStandardMaterial({
		color: new Color('black').convertLinearToSRGB(),
		side: DoubleSide,
		wireframe: false,
		transparent: true,
		opacity: 1
	});
	const ballMaterial = new MeshStandardMaterial({ color: 'orange' });
	balls.push({
		x: 150 * Math.random() + 50,
		y: 5 * 20 * Math.random(),
		z: 150 * Math.random() + 50
	});

	renderer.shadowMap.enabled = true;
	renderer.shadowMap.type = PCFSoftShadowMap;

	const csm = new CSM({
		maxFar: 100,
		cascades: 1,
		shadowMapSize: 4096,
		lightDirection: new Vector3(2, -1, 3).normalize(),
		camera: $camera,
		parent: scene,
		shadowBias: 0,
		fade: true,
		mode: 'practical'
	});

	// csm.setupMaterial(planeMaterial);
	// csm.setupMaterial(ballMaterial);

	let t = 0;

	useFrame(({ clock }) => {
		//
		t += clock.getDelta() * 10000;

		if (t > 0.2) {
			// console.log('ballspawn');
			t = 0;
			balls.push({
				x: 150 * Math.random() + 10,
				y: 30,
				z: 150 * Math.random() + 10
			});
			balls = balls;
		}
		csm.update(camera.matrix);
	});
</script>

<T.PerspectiveCamera position={[300, 100, 300]} fov={30} let:ref makeDefault>
	<OrbitControls
		enableZoom={true}
		target={{ x: 100, y: 0.5, z: 100 }}
		autoRotate
		autoRotateSpeed={0.0}
	/>
</T.PerspectiveCamera>

<T.DirectionalLight position={[3, 10, 10]} intensity={0.5} castShadow />
<T.DirectionalLight position={[-3, 10, -10]} intensity={0.2} castShadow />
<T.AmbientLight intensity={0.2} />

<World>
	{#if terrainGeometry}
		<T.Mesh receiveShadow material={planeMaterial} geometry={terrainGeometry} />
		<Collider
			shape={'trimesh'}
			args={[terrainPhysicsGeometry.attributes.position.array, terrainPhysicsGeometry.index.array]}
		/>

		{#each balls as ball}
			<RigidBody position={ball} type="dynamic">
				<AutoColliders shape={'trimesh'} restitution={0.6}>
					<T.Mesh castShadow receiveShadow material={ballMaterial}>
						<T.SphereGeometry args={[1 + Math.random() * 3, 10, 10]} />
					</T.Mesh>
				</AutoColliders>
			</RigidBody>
		{/each}
	{/if}

	<!-- <Debug depthTest={true} depthWrite={true} side={DoubleSide} /> -->
</World>

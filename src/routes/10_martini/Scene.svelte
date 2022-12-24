<script lang="ts">
	import { OrbitControls, T, useFrame, useThrelte } from '@threlte/core';
	import { Color, MeshStandardMaterial } from 'three';
	import { DEG2RAD } from 'three/src/math/MathUtils';
	import {
		AutoColliders,
		Collider,
		CollisionGroups,
		Debug,
		RigidBody,
		World
	} from '@threlte/rapier';
	import { default as Martini } from '@mapbox/martini';
	import { BufferGeometry } from 'three';
	import { BufferAttribute } from 'three';
	import { DoubleSide } from 'three';
	import { Environment } from '@threlte/extras';

	import CSM from 'three-csm';
	import { Vector3 } from 'three';
	import { PCFSoftShadowMap } from 'three';

	const decodeTerrainFromTile = (tileImg: HTMLImageElement) => {
		// ! todo move all this logic to worker thread
		const tileSize = tileImg.width;

		// 1. Draw terrain on an offscreen canvas
		const textureCanvas = new OffscreenCanvas(tileSize, tileSize);
		textureCanvas.height = screen.height;
		textureCanvas.width = screen.width;
		const ctx = textureCanvas.getContext('2d');

		if (!ctx) {
			return;
		}
		ctx.drawImage(tileImg, 0, 0);
		const data = ctx.getImageData(0, 0, tileSize, tileSize).data;

		const gridSize = tileSize + 1;

		const terrain = new Float32Array(gridSize * gridSize);

		// 2. Decode terrain values from rgb terrain tile
		for (let y = 0; y < tileSize; y++) {
			for (let x = 0; x < tileSize; x++) {
				const k = (y * tileSize + x) * 4;
				const r = data[k + 0];
				const g = data[k + 1];
				const b = data[k + 2];
				const a = data[k + 3];
				terrain[y * gridSize + x] = (r * 256 * 256 + g * 256.0 + b) / 10.0 - 10000.0;
			}
		}
		// 2.1 backfill right and bottom borders
		for (let x = 0; x < gridSize - 1; x++) {
			terrain[gridSize * (gridSize - 1) + x] = terrain[gridSize * (gridSize - 2) + x];
		}
		for (let y = 0; y < gridSize; y++) {
			terrain[gridSize * y + gridSize - 1] = terrain[gridSize * y + gridSize - 2];
		}

		return terrain;
	};

	const genMartiniTerrain = (terrain: Float32Array, size: number, terrainError: 10) => {
		const martiniInstance = new Martini(size + 1);

		const tile = martiniInstance.createTile(terrain);

		//! todo terrain error as param
		const meshMartini = tile.getMesh(terrainError);

		const geometry = new BufferGeometry();

		const vertices = [];
		for (let i = 0; i < meshMartini.vertices.length / 2; i++) {
			let x = meshMartini.vertices[i * 2],
				y = meshMartini.vertices[i * 2 + 1];
			vertices.push(x);
			vertices.push(terrain[y * size + x] / 100);
			vertices.push(y);
		}

		geometry.setIndex(new BufferAttribute(meshMartini.triangles, 1));
		geometry.setAttribute('position', new BufferAttribute(new Float32Array(vertices), 3));

		geometry.computeVertexNormals();
		geometry.computeBoundingBox();
		geometry.normalizeNormals();

		return geometry;
	};

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

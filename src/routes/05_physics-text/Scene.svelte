<script lang="ts">
	import {
		Mesh,
		OrbitControls,
		PerspectiveCamera,
		AmbientLight,
		DirectionalLight
	} from '@threlte/core';
	import { BoxGeometry, MeshStandardMaterial, PlaneGeometry, SphereGeometry, Vector3 } from 'three';
	import { AutoColliders, Debug, RigidBody, World } from '@threlte/rapier';

	import { FontLoader } from 'three/examples/jsm/loaders/FontLoader';
	import { TextGeometry } from 'three/examples/jsm/geometries/TextGeometry';
	import Ground from './Ground.svelte';
	import { Environment } from '@threlte/extras';

	let letterGeometries: Record<string, TextGeometry> = {};

	let letters: { letter: string; offset: number }[] = [];

	const palette = [
		0xbe4a2f, 0xd77643, 0xead4aa, 0xe4a672, 0xb86f50, 0x733e39, 0x3e2731, 0xa22633, 0xe43b44,
		0xf77622, 0xfeae34, 0xfee761, 0x63c74d, 0x3e8948, 0x265c42, 0x193c3e, 0x124e89, 0x0099db,
		0x2ce8f5, 0xffffff, 0xc0cbdc, 0x8b9bb4, 0x5a6988, 0x3a4466, 0x262b44, 0x181425, 0xff0044,
		0x68386c, 0xb55088, 0xf6757a, 0xe8b796, 0xc28569
	];

	function debounce<T extends Function>(cb: T, wait = 20) {
		let h: any = 0;
		let callable = (...args: any) => {
			clearTimeout(h);
			h = setTimeout(() => cb(...args), wait);
		};
		return <T>(<any>callable);
	}

	const materials = palette.map((color) => {
		return new MeshStandardMaterial({
			color: color,
			wireframe: false
		});
	});

	const loader = new FontLoader();
	loader.load('fonts/optimer_bold.typeface.json', function (response) {
		let letterQueue: string[] = [];

		const g = debounce(() => {
			console.log('bounce');
			let totalOffset = 0;
			for (let i = 0; i < letterQueue.length; i++) {
				letters.push({ letter: letterQueue[i], offset: totalOffset * 1 });

				totalOffset +=
					letterGeometries[letterQueue[i]].boundingBox?.getSize(new Vector3(0, 0, 0)).x + 0.09;
			}

			letterQueue = [];
			letters = letters;
		}, 200);

		window.addEventListener('keydown', (e) => {
			let key = e.key == ' ' ? '_' : e.key;

			const allowedLetters = key.match(/^[A-Za-z]+$/);

			if (!letterGeometries[key]) {
				const textGeo = new TextGeometry(key, {
					font: response,
					size: 1,
					height: 0.1,
					curveSegments: 5,
					bevelThickness: 0.01,
					bevelSize: 0.1,
					bevelEnabled: false,
					bevelSegments: 5
				});

				textGeo.computeBoundingBox();

				letterGeometries[key] = textGeo;
			}

			if (allowedLetters && allowedLetters[0].length == 1) letterQueue.push(key);

			g();
		});
	});
</script>

<World>
	<PerspectiveCamera
		position={{ x: 5, y: 7, z: 9 }}
		fov={60}
		near={1}
		far={20000}
		lookAt={{ x: 0, y: 0, z: 0 }}
	>
		<!-- <OrbitControls autoRotate={false} enableZoom={true} target={{ x: 0, y: 0, z: 0 }} /> -->
	</PerspectiveCamera>

	<!-- <Debug /> -->

	<Ground color={palette[0]} />

	{#each letters as { letter, offset }, i}
		<RigidBody
			type="dynamic"
			position={{
				x: offset,
				y: 5,
				z: 0
			}}
			gravityScale={2}
		>
			<AutoColliders shape={'convexHull'}>
				<Mesh
					geometry={letterGeometries[letter]}
					material={materials[1 + Math.floor(Math.random() * (palette.length - 2))]}
					castShadow
					receiveShadow
				/>
			</AutoColliders>
		</RigidBody>
	{/each}

	<AmbientLight color={0xffffff} intensity={0.5} />

	<!-- <DirectionalLight position={{ x: 15, y: 10, z: 5 }} shadow intensity={0.3} /> -->
	<DirectionalLight position={{ x: -7, y: 10, z: 5 }} shadow intensity={0.7} />
</World>

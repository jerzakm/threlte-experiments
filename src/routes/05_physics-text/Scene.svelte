<script lang="ts">
	import {
		Mesh,
		OrbitControls,
		PerspectiveCamera,
		AmbientLight,
		DirectionalLight,
		Pass
	} from '@threlte/core';
	import {
		BoxGeometry,
		MeshStandardMaterial,
		PlaneGeometry,
		SphereGeometry,
		Vector2,
		Vector3
	} from 'three';
	import { AutoColliders, Debug, RigidBody, World } from '@threlte/rapier';

	import { FontLoader } from 'three/examples/jsm/loaders/FontLoader';
	import { TextGeometry } from 'three/examples/jsm/geometries/TextGeometry';
	import Ground from './Ground.svelte';
	import { Environment } from '@threlte/extras';

	import { UnrealBloomPass } from 'three/examples/jsm/postprocessing/UnrealBloomPass.js';

	let letterGeometries: Record<string, TextGeometry> = {};

	let letters: { letter: string; offset: number }[] = [];

	const endesga32 = [
		0xbe4a2f, 0xd77643, 0xead4aa, 0xe4a672, 0xb86f50, 0x733e39, 0x3e2731, 0xa22633, 0xe43b44,
		0xf77622, 0xfeae34, 0xfee761, 0x63c74d, 0x3e8948, 0x265c42, 0x193c3e, 0x124e89, 0x0099db,
		0x2ce8f5, 0xffffff, 0xc0cbdc, 0x8b9bb4, 0x5a6988, 0x3a4466, 0x262b44, 0x181425, 0xff0044,
		0x68386c, 0xb55088, 0xf6757a, 0xe8b796, 0xc28569
	];

	const sunrise = [0x090d21, 0xa71442, 0xff5d18, 0xffddc9];

	const mindustryCanvas = [
		0x362944, 0xc45d9f, 0xe39aac, 0xf0dab1, 0x6461c2, 0x2ba9b4, 0x93d4b5, 0xf0f6e8
	];

	const halloweenCandy = [
		0x001122, 0x221155, 0x771188, 0xcc2222, 0xcc8811, 0x44cc44, 0xddee55, 0xeeddff
	];

	const mapleBar36 = [
		0xe58a2e, 0x252527, 0x515152, 0x757575, 0xb5b5b5, 0xe3e4e2, 0x4e222c, 0x602f35, 0x743e3e,
		0x915955, 0xdc5e28, 0xe8774a, 0xe69c6b, 0xe8b882, 0xecd3a7, 0x717b0a, 0x9d9b10, 0xb9a418,
		0x531471, 0x76196d, 0x8c2265, 0xb3326c, 0xc54966, 0x337c13, 0x4b961d, 0x6bad25, 0xa0c530,
		0xd1e04d, 0x70103e, 0x8b182c, 0xb42e13, 0xe58a2e, 0xebac2d, 0x2b1aad, 0x263bc5, 0x2d69d2,
		0x468fd2
	];

	const palette = endesga32;

	const bloomPass = new UnrealBloomPass(
		new Vector2(window.innerWidth, window.innerHeight),
		1.5,
		0.4,
		0.85
	);
	bloomPass.threshold = 0.0;
	bloomPass.strength = 0.1;
	bloomPass.radius = 0.3;

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
			wireframe: false,
			metalness: 0.0,
			roughness: 1
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

			for (const letter of letters) {
				letter.offset -= totalOffset * 0.5;
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

<!-- <Environment path="/03_env/" files="spaichingen_hill_1k.hdr" /> -->

<!-- <Pass pass={bloomPass} /> -->

<World>
	<PerspectiveCamera
		position={{ x: 4, y: 6, z: 8 }}
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

	<DirectionalLight position={{ x: 15, y: 10, z: 5 }} shadow intensity={0.8} />
	<!-- <DirectionalLight position={{ x: -7, y: 10, z: 5 }} shadow intensity={0.2} /> -->
</World>

<script>
	import {
		AmbientLight,
		Canvas,
		DirectionalLight,
		Mesh,
		OrbitControls,
		PerspectiveCamera
	} from '@threlte/core';
	import { CircleGeometry, DoubleSide, MeshStandardMaterial } from 'three';
	import { DEG2RAD } from 'three/src/math/MathUtils';
	import Card from './Card.svelte';
</script>

<div>
	<Canvas>
		<PerspectiveCamera position={{ x: 0, y: 3, z: 5 }} fov={24}>
			<OrbitControls
				maxPolarAngle={DEG2RAD * 80}
				autoRotate={false}
				enableZoom={true}
				target={{ y: 0.5 }}
			/>
		</PerspectiveCamera>

		<DirectionalLight shadow position={{ x: 3, y: 10, z: 10 }} />
		<DirectionalLight position={{ x: -3, y: 10, z: -10 }} intensity={0.2} />
		<AmbientLight intensity={0.2} />

		<!-- Cube -->
		<Card />

		<!-- Floor -->
		<Mesh
			receiveShadow
			rotation={{ x: -90 * (Math.PI / 180) }}
			geometry={new CircleGeometry(3, 72)}
			material={new MeshStandardMaterial({ side: DoubleSide, color: 'rgb(40,40,40)' })}
		/>
	</Canvas>
</div>

<style>
	div {
		height: 100%;
		width: 100%;
	}
</style>

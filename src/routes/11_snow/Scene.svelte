<script lang="ts">
	import { OrbitControls, T, useFrame, useThrelte } from '@threlte/core';
	import { Grid } from '@threlte/extras';
	import { Mesh, OrthographicCamera, PlaneGeometry, SphereGeometry } from 'three';
	import { WebGLRenderTarget } from 'three';
	import { Scene } from 'three';
	import { MeshBasicMaterial, Raycaster, Vector3 } from 'three';
	import { DoubleSide, ShaderMaterial } from 'three';
	import { DEG2RAD } from 'three/src/math/MathUtils';
	import { default as fragmentShader } from './snowFrag.glsl?raw';
	import { default as vertexShader } from './snowVert.glsl?raw';

	const { camera, renderer, scene } = useThrelte();
	let trailSphere: Mesh;

	const trailScene = new Scene();
	const trailA = new WebGLRenderTarget(window.innerWidth, window.innerHeight);
	const trailB = new WebGLRenderTarget(window.innerWidth, window.innerHeight);

	const trailBg = new Mesh(
		new PlaneGeometry(10, 10),
		new MeshBasicMaterial({ color: 'red', side: DoubleSide })
	);
	// trailBg.position.z = -100;

	const cSize = 200;

	const trailCamera = new OrthographicCamera(
		renderer?.domElement.width / -cSize,
		renderer?.domElement.width / cSize,
		renderer?.domElement.height / cSize,
		renderer?.domElement.height / -cSize,
		-10000,
		10000
	);

	const trailMesh = new Mesh(new SphereGeometry(0.2), new MeshBasicMaterial({ color: 'white' }));
	trailCamera.position.set(0, 0, 10);
	trailScene.add(trailBg);
	trailScene.add(trailCamera);
	trailScene.add(trailMesh);

	const snowMaterialHelper = new ShaderMaterial({
		fragmentShader,
		vertexShader,
		side: DoubleSide,
		uniforms: {
			trailMaker: {
				value: new Vector3(0, 0, 0.5)
			}
		}
	});

	const snowMaterial = new ShaderMaterial({
		fragmentShader,
		vertexShader,
		side: DoubleSide,
		uniforms: {
			trailMaker: {
				value: new Vector3(0, 0, 0.5)
			},
			trailA: {
				value: trailA
			},
			trailB: {
				value: trailB
			}
		}
	});

	let t = 0;

	let spherePos = new Vector3();

	let sphere: Mesh;
	let plane: Mesh;

	let bufferToggle = false;

	useFrame(({ clock, renderer }) => {
		trailMesh.position.set(trailSphere.position.x, trailSphere.position.z, trailSphere.position.y);
		if (!renderer) return;
		renderer.autoClear = false;

		t = clock.elapsedTime;
		// snowMaterial.uniforms.trailMaker.value.set(trailSphere.position.x, trailSphere.position.z, 0);

		if (t < 1) {
			//
		}
		renderer.setRenderTarget(trailA);
		renderer.clear();
		// if (bufferToggle) {

		// } else {
		// 	renderer.setRenderTarget(trailB);
		// }

		bufferToggle = !bufferToggle;

		renderer?.render(trailScene, trailCamera);
		renderer.setRenderTarget(trailA);
		// renderer?.render(scene, $camera);

		renderer?.setRenderTarget(null);

		// renderer.clear();
		// renderer?.render(trailScene, trailCamera);
	});
</script>

<!-- <T.PerspectiveCamera position={[0, 19, 11]} fov={30} let:ref>
	<OrbitControls
		enableZoom={true}
		target={{ x: 0, y: 0.5, z: 0 }}
		autoRotate
		autoRotateSpeed={0.0}
	/>
</T.PerspectiveCamera> -->

<T.DirectionalLight position={[3, 10, 10]} intensity={0.5} castShadow />
<T.DirectionalLight position={[-3, 10, -10]} intensity={0.2} castShadow />
<T.AmbientLight intensity={0.2} />

<!-- <Grid
	cellSize={0.5}
	cellThickness={1.2}
	position={[0, 0.01, 0]}
	cellColor={'black'}
	sectionSize={0}
/> -->

<T.Mesh position={[3 * Math.sin(t), spherePos.y + 0.1, 3 * Math.cos(t)]} bind:ref={trailSphere}>
	<T.SphereGeometry args={[0.2]} />
	<T.MeshBasicMaterial color="yellow" />
</T.Mesh>

<T.Mesh material={snowMaterial} position={[0, 0, -100]} bind:ref={plane}>
	<T.PlaneGeometry args={[100, 100, 1, 1]} />
</T.Mesh>

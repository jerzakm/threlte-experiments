<script lang="ts">
	import { Canvas, Mesh, OrbitControls, PerspectiveCamera, useFrame } from '@threlte/core';
	import Scene from './Scene.svelte';

	let elementToFollow;
</script>

<wrapper class="relative h-full ">
	<section class="absolute flex flex-col items-center w-full gap-16 pt-96" style="height:300vh;">
		<div class="max-w-lg" bind:this={elementToFollow}>
			<h1 class="text-4xl font-bold">This rotating box will follow the dom position</h1>
			<p>
				Lorem ipsum, dolor sit amet consectetur adipisicing elit. Possimus totam impedit
				necessitatibus, modi soluta deserunt nihil commodi! Numquam expedita blanditiis,
				voluptatibus quisquam reprehenderit quod minima, ea animi ad nobis delectus!
			</p>
		</div>
	</section>
	<Canvas>
		<Scene {elementToFollow} />
	</Canvas>
</wrapper>

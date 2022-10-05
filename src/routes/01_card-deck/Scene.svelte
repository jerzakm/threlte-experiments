<script lang="ts">
	import { AmbientLight, DirectionalLight, OrbitControls, PerspectiveCamera } from '@threlte/core';
	import { DEG2RAD } from 'three/src/math/MathUtils';
	import Card from './Card.svelte';
	import InHand from './InHand.svelte';

	const inHandCount = 12;
	const tableCount = 25;

	const cardsInHand: any[] = [];
	const cardOnTable: any[] = [];

	for (let i = 0; i < inHandCount; i++) {
		cardsInHand.push({});
	}
	for (let i = 0; i < tableCount; i++) {
		cardOnTable.push({
			flipped: false
		});
	}
</script>

<PerspectiveCamera position={{ x: 0, y: 15, z: 15 }} fov={24}>
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

<!-- Cards in hand, rendered right in front of the camera -->
<InHand>
	{#each cardsInHand as card, i}
		<Card inHand={true} />
	{/each}
</InHand>

<!-- Cards on the table -->
{#each cardOnTable as card, i}
	<Card
		position={{
			x: Math.cos(DEG2RAD * ((360 / tableCount) * i)) * 5,
			y: 0.01,
			z: Math.sin(DEG2RAD * ((360 / tableCount) * i)) * 5
		}}
		rotation={{
			y: 0,
			x: -DEG2RAD * 90,
			z: 0
		}}
		flipped={card.flipped}
		on:click={() => (card.flipped = !card.flipped)}
	/>
{/each}

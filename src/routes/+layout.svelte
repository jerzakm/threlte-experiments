<script lang="ts">
	import '../app.postcss';
	import '../styles/global.css';

	import { page } from '$app/stores';
	import { routes } from '$lib/routes';

	console.log();
</script>

<nav class="drawer drawer-mobile">
	<input id="my-drawer-2" type="checkbox" class="drawer-toggle" />
	<main class="drawer-content flex flex-col ">
		<slot />
		<label
			for="my-drawer-2"
			class="absolute m-4 top-0 right-0 btn btn-primary drawer-button lg:hidden">Menu</label
		>
		<a
			class="btn gap-2 absolute bottom-0 right-0 m-4"
			href={`https://github.com/jerzakm/threlte-experiments/tree/main/src/routes${$page.url.pathname}`}
		>
			<svg
				class="fill-white w-6"
				version="1.1"
				id="Layer_1"
				xmlns="http://www.w3.org/2000/svg"
				xmlns:xlink="http://www.w3.org/1999/xlink"
				x="0px"
				y="0px"
				viewBox="0 0 122.88 101.57"
				style="enable-background:new 0 0 122.88 101.57"
				xml:space="preserve"
				><g
					><path
						d="M44.97,12.84h-17.2L0,49.37L27.77,85.9h17.2L17.2,49.37L44.97,12.84L44.97,12.84z M77.91,12.84h17.2l27.77,36.53 L95.11,85.9h-17.2l27.77-36.53L77.91,12.84L77.91,12.84z M70.17,0.04l5.96,1.39c0.94,0.22,1.52,1.16,1.31,2.1l-22.5,96.69 c-0.22,0.93-1.16,1.52-2.1,1.31l-5.95-1.39c-0.94-0.22-1.52-1.16-1.31-2.1l22.5-96.69C68.3,0.42,69.24-0.17,70.17,0.04L70.17,0.04 L70.17,0.04z"
					/></g
				></svg
			>

			Code
		</a>
	</main>
	<nav class="drawer-side">
		<label for="my-drawer-2" class="drawer-overlay" />
		<ul class="menu p-4 overflow-y-auto w-80 bg-base-100 text-base-content ">
			<h1 class="font-bold text-lg">Stuff made with Threlte:</h1>
			<a href="https://github.com/jerzakm/threlte-experiments" class=" hover:text-blue-600 mb-4"
				>Github source</a
			>
			{#each routes as { name, href }, i}
				<li>
					<a class={`${href == $page.url.pathname ? 'active' : ''}`} {href}>
						{i + 1} - <b>{name}</b>
					</a>
				</li>
			{/each}
		</ul>
	</nav>
</nav>

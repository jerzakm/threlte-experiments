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
	</main>
	<nav class="drawer-side">
		<label for="my-drawer-2" class="drawer-overlay" />
		<ul class="menu p-4 overflow-y-auto w-80 bg-base-100 text-base-content">
			<h1 class="font-bold text-lg mb-2">Stuff made with Threlte:</h1>
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

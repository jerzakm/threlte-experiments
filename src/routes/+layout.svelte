<script lang="ts">
	import '../app.postcss';
	import '../styles/global.css';
</script>

<nav class="drawer drawer-mobile">
	<input id="my-drawer-2" type="checkbox" class="drawer-toggle" />
	<main class="drawer-content flex flex-col items-center justify-center">
		<!-- Page content here -->
		<slot />
		<label
			for="my-drawer-2"
			class="absolute m-4 top-0 right-0 btn btn-primary drawer-button lg:hidden">Menu</label
		>
	</main>
	<nav class="drawer-side">
		<label for="my-drawer-2" class="drawer-overlay" />
		<ul class="menu p-4 overflow-y-auto w-80 bg-base-100 text-base-content">
			<!-- Sidebar content here -->
			<li><a>Sidebar Item 1</a></li>
			<li><a>Sidebar Item 2</a></li>
		</ul>
	</nav>
</nav>

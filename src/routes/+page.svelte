<script lang="ts">
	import { routes } from '$lib/routes';
</script>

<section class="flex flex-col items-center">
	<div class="flex flex-wrap gap-4 px-8 py-2">
		{#each routes as route, i}
			<div class="card bg-base-100 shadow-xl">
				<div class="card-body">
					<h2 class="card-title">{route.name}</h2>
					<p>desc</p>
					<div class="card-actions justify-end">
						<a href={route.href} class="btn btn-primary">Live</a>
					</div>
				</div>
			</div>
		{/each}
	</div>
</section>

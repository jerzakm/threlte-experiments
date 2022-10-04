import { routes } from '$lib/routes';
import { error, redirect } from '@sveltejs/kit';

/** @type {import('./$types').LayoutServerLoad} */
export function load() {
	throw redirect(302, routes[0].href);
}

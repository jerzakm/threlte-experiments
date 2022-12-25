import { default as Martini } from '@mapbox/martini';
import { BufferAttribute, BufferGeometry } from 'three';

export const decodeTerrainFromTile = (tileImg: HTMLImageElement) => {
	// ! todo move all this logic to worker thread
	const tileSize = tileImg.width;

	// 1. Draw terrain on an offscreen canvas
	const textureCanvas = new OffscreenCanvas(tileSize, tileSize);
	textureCanvas.height = screen.height;
	textureCanvas.width = screen.width;
	const ctx = textureCanvas.getContext('2d');

	if (!ctx) {
		return;
	}
	ctx.drawImage(tileImg, 0, 0);
	const data = ctx.getImageData(0, 0, tileSize, tileSize).data;

	const gridSize = tileSize + 1;

	const terrain = new Float32Array(gridSize * gridSize);

	// 2. Decode terrain values from rgb terrain tile
	for (let y = 0; y < tileSize; y++) {
		for (let x = 0; x < tileSize; x++) {
			const k = (y * tileSize + x) * 4;
			const r = data[k + 0];
			const g = data[k + 1];
			const b = data[k + 2];
			const a = data[k + 3];
			terrain[y * gridSize + x] = (r * 256 * 256 + g * 256.0 + b) / 10.0 - 10000.0;
		}
	}
	// 2.1 backfill right and bottom borders
	for (let x = 0; x < gridSize - 1; x++) {
		terrain[gridSize * (gridSize - 1) + x] = terrain[gridSize * (gridSize - 2) + x];
	}
	for (let y = 0; y < gridSize; y++) {
		terrain[gridSize * y + gridSize - 1] = terrain[gridSize * y + gridSize - 2];
	}

	return terrain;
};

export const genMartiniTerrain = (terrain: Float32Array, size: number, terrainError: 10) => {
	const martiniInstance = new Martini(size + 1);

	const tile = martiniInstance.createTile(terrain);

	const mesh = tile.getMesh(terrainError);
	const mv = tile.getMesh(0).vertices.length;

	const geometry = new BufferGeometry();

	const vertices = new Float32Array((mv / 2) * 3);
	const uv = new Float32Array(mv);

	for (let i = 0; i < mesh.vertices.length / 2; i++) {
		let x = mesh.vertices[i * 2],
			y = mesh.vertices[i * 2 + 1];
		// vertices.push(x);
		// vertices.push(terrain[y * size + x] / 100);
		// vertices.push(y);
		vertices[3 * i + 0] = x;
		vertices[3 * i + 1] = terrain[y * size + x] / 100;
		// vertices[3 * i + 2] = data[y * gridSize + x] / tileSize;
		vertices[3 * i + 2] = y;
		uv[2 * i + 0] = x / size;
		uv[2 * i + 1] = y / size;
	}

	geometry.setIndex(new BufferAttribute(mesh.triangles, 1));
	geometry.setAttribute('position', new BufferAttribute(vertices, 3));
	geometry.setAttribute('uv', new BufferAttribute(uv, 2));

	geometry.computeVertexNormals();
	geometry.computeBoundingBox();
	geometry.normalizeNormals();
	geometry.attributes.uv.needsUpdate = true;
	geometry.attributes.position.needsUpdate = true;

	return geometry;
};

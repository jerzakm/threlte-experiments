export const fogMaterials: any[] = [];

export const registerMaterial = (s: any) => {
	fogMaterials.push(s);
	s.uniforms.fogTime = { value: 0.0 };
};

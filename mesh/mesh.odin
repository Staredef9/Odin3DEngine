package mesh

Vector2_t :: [2]f32
Vector3_t :: [3]f32
Face_t :: [3]int
Texture_indices_t :: [3]int
Normal_indices_t :: [3]int



mesh_t :: struct {
	vertices : [dynamic]Vector3_t,
	faces : [dynamic]Face_t,
	tex_indices : [dynamic]Texture_indices_t,
	norm_indices : [dynamic]Normal_indices_t,
	rotation : Vector3_t,
}
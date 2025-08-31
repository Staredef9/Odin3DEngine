package game_main

import "core:fmt"
import "core:mem"
import "core:math"
import "base:runtime"
import sdl "vendor:sdl2"


/*CONSTANTS and globals */
RENDER_FLAGS :: sdl.RENDERER_SOFTWARE

WINDOW_WIDTH :: 1080
WINDOW_HEIGHT :: 720

FPS :: 60
FRAME_TARGET_TIME :: (1000 / FPS)

N_MESH_VERTICES :: 8
N_MESH_FACES :: (6 * 2)

window_width : i32
window_height : i32
	
window : ^sdl.Window 
renderer : ^sdl.Renderer

colorBufferTexture : ^sdl.Texture

color : [4]u8 = {0, 0, 0, 255}

colorBuffer : [dynamic]u32

err : runtime.Allocator_Error


cubeRotation : [3]f32

previous_frame_time : u32

/*    ARRAY OF POINTS     */

N_POINTS :: 9 * 9 * 9

cube_points : [N_POINTS][3]f32

projected_points : [N_POINTS][2]f32


/*Camera and Field of Views*/
fov_factor :: 500
fov_orto :: 60

camera_position : [3]f32 = {0, 0, -5}

/* Geometries */

Vector2_t :: [2]f32
Vector3_t :: [3]f32
Face_t :: [3]int

triangle_t  :: struct {
	vertices : [3]Vector2_t
}

mesh_vertices : [N_MESH_VERTICES]Vector3_t = {
	{-1, -1, -1},
	{-1, 1, -1},
	{1,  1,  -1},
	{1,  -1,  -1},
	{1,  1, 1},
	{1,  -1,  1},
	{-1,  1, 1},
	{-1,  -1,  1}
}

mesh_faces : [N_MESH_FACES]Face_t = {
	//front
	{1, 2, 3},
	{1, 3, 4},
	//right
	{4, 3, 5}, 
	{4, 5, 6},
	//back
	{6, 5, 7}, 
	{6, 7, 8},
	//left
	{8, 7, 2},
	{8, 2, 1},
	//top
	{2, 7, 5},
	{2, 5, 3},
	//bottom
	{6, 8, 1},
	{6, 1, 4}
}

triangles_to_render : [N_MESH_FACES]triangle_t




mesh_t :: struct {
	vertices : [dynamic]Vector3_t,
	faces : [dynamic]Face_t,
	rotation : Vector3_t,
}


My_mesh : mesh_t

/*window procedures */

initialize_window :: proc()->b32{


	if sdl.Init(sdl.INIT_EVERYTHING) != 0
	{
		fmt.println("error init SDL")
		return false
	}

	display_mode : sdl.DisplayMode

	sdl.GetCurrentDisplayMode(0, &display_mode)
	window_width = display_mode.w 
	window_height = display_mode.h 

	window = sdl.CreateWindow("Hello sdl", 0, 0, window_width, window_height,sdl.WINDOW_BORDERLESS)

	if window == nil {
		fmt.println("errror initializing window")
		return false
	}

	renderer = sdl.CreateRenderer(window, -1, RENDER_FLAGS)


	if renderer == nil {
		fmt.println("error initializing the renderer ")
		return false
	}

	sdl.SetWindowFullscreen(window, sdl.WINDOW_FULLSCREEN)

	return true
}


/*COLOR BUFFER */


setup :: proc () -> b32{

	fmt.println(window_width)
	fmt.println(window_height)

	colorBuffer = make([dynamic]u32, window_height * window_width)


	if len(colorBuffer) == 0 {
		fmt.println("error allocating Color Buffer")
		return false
	}
	
	colorBufferTexture = sdl.CreateTexture(renderer, sdl.PixelFormatEnum.ARGB8888, sdl.TextureAccess.STREAMING, window_width, window_height)

	if colorBufferTexture == nil{
		fmt.println("error allocating texture", sdl.GetError())
		return false
	}


	/*
		point_count := 0

		for x : f32 = -1 ; x <= 1; x+= 0.25 {
			for y : f32 = -1; y <= 1; y += 0.25{
				for z :f32 = -1; z <= 1; z += 0.25{
					new_point: [3]f32 = {x, y, z}
					cube_points[point_count] = new_point
					point_count += 1
				}
			}
		}
		*/

	return true
}



render_color_buffer :: proc() {

	err := sdl.UpdateTexture(colorBufferTexture, nil, raw_data(colorBuffer), window_width * size_of(u32))

	if err != 0 {
		fmt.println("error updating texture", sdl.GetError())

		return
	}

	sdl.RenderCopy(renderer, colorBufferTexture, nil, nil)

}



clear_color_buffer :: proc(color : u32, typed_buffer : ^[dynamic]u32){

	localColor := color 
	a := u8((localColor >> 24) & 0xFF)
	r := u8((localColor >> 16) & 0xFF)
	g := u8((localColor >> 8) & 0xFF)
	b := u8(localColor  & 0xFF)

	for y := 0; y < int(window_height); y+=1{
		for x := 0; x < int(window_width); x+=1{
			typed_buffer[(window_width * i32(y)) + i32(x)] = color
			/* u32(a) << 24 | u32(r) << 16 | u32(g) << 8 | u32(b)
				r += u8(0)
				g += u8(0)
				b += u8(255)
			*/
		}
	}

}


/*Drawing procedures */



draw_pixel :: proc(x : i32, y : i32, color: u32){

	if i32(x) >= 0 && i32(x) < window_width && i32(y) <= window_height && i32(y) >= 0 {
		colorBuffer[(window_width * i32(y)) + i32(x)] = color
	}
}



draw_line :: proc (x0 : i32, y0 : i32, x1 : i32, y1 : i32, color : u32){

	delta_x := (x1 - x0)
	delta_y := (y1 - y0)

	side_length : i32
	
	if math.abs(delta_x) >= math.abs(delta_y){
		side_length = math.abs(delta_x)
	} else if math.abs(delta_y) >= math.abs(delta_x){
		side_length = math.abs(delta_y)
	}

	x_increment : f32 = f32(delta_x) / f32(side_length)
	y_increment :f32 = f32(delta_y) / f32(side_length)

	current_x := f32(x0)
	current_y := f32(y0)
	for i := 0; i <= int(side_length); i += 1{

			draw_pixel(i32(math.round(current_x)), i32(math.round(current_y)), color)

			current_x += x_increment
			current_y += y_increment
	}

}


draw_triangle :: proc(x0 : i32, y0 : i32, x1 : i32, y1 : i32,  x2 : i32, y2 : i32, color : u32){

		draw_line(x0, y0, x1, y1, color)
		draw_line(x1, y1, x2, y2, color)
		draw_line(x2, y2, x0, y0, color)



}


draw_grid :: proc(){

	//cambia il color buffer per ogni row and column multipla di 10 
	//aggiungi in RENDER 
	for y:= 0; y < int(window_height); y += 1{
		for x := 0; x < int(window_width); x += 1{
			
				if y % 40 == 0 && x % 40 == 0{
					colorBuffer[(window_width * i32(y)) + i32(x)] = 0xFFFFFFFF
				}

		}
	}

}



draw_rect :: proc ( x: int, y : int, width: int, height: int, color: u32) {

	for j := 0; j < height; j += 1{
		for k := 0; k < width; k += 1{
			current_x := i32(k + x)
			current_y := i32(y) + i32(j)
			draw_pixel(i32(current_x), i32(current_y), color)
			//colorBuffer[(window_width * (i32(y)+i32(j))) + i32(k + x)] = color
		}
	}
}


project :: proc (point : Vector3_t) -> (result : Vector2_t) {

		vec_out :Vector2_t
		vec_out.x = (point.x * fov_factor) / point.z
		vec_out.y = (point.y * fov_factor) / point.z

		return vec_out

}

ortographic_projection :: proc(){

	for i := 0; i < N_POINTS; i += 1 {
			point : [3]f32 = cube_points[i]

			projected_point : [2]f32 
			projected_point.x = point.x * fov_orto
			projected_point.y = point.y * fov_orto

			projected_points[i] = projected_point
		}

	for number := 0; number < N_POINTS; number += 1{
	
	 	draw_rect(int(projected_points[number].x) + int(window_width / 2), int(projected_points[number].y) + int(window_height / 2), 4, 4, 0xFFFFFF00)
	}
}

isometric_projection :: proc(){

}


perspective_projection :: proc(){


	for i := 0; i < N_POINTS; i += 1 {
			point : [3]f32 = cube_points[i]
			point.z -= camera_position.z

			projected_point : [2]f32 
			projected_point.x = (point.x * fov_factor) / point.z
			projected_point.y = (point.y * fov_factor) / point.z

			projected_points[i] = projected_point
		}



	for number := 0; number < N_POINTS; number += 1{

			//scale 

			//translate 
		//hot_point := projected_point[number]


	 	draw_rect(int(projected_points[number].x) + int(window_width / 2), int(projected_points[number].y) + int(window_height / 2), 4, 4, 0xFFFFFF00)
	}

}




/* 3D rotations */


vec3_rotate_z :: proc ( v : [3]f32, angle : f32) -> (result : [3]f32 ){
	rotated_vector : [3]f32 = {


		v.x * math.cos(angle) - v.y * math.sin(angle),
		v.x * math.sin(angle) + v.y * math.cos(angle),
		v.z
	}
	return rotated_vector
}





vec3_rotate_y :: proc ( v : [3]f32, angle : f32) -> (result : [3]f32) {
	rotated_vector : [3]f32 = {


		v.x * math.cos(angle) - v.z * math.sin(angle),
		v.y,
		//TODO applica rotazione a Z 
		v.x * math.sin(angle) + v.z * math.cos(angle)
	}
	return rotated_vector
}


vec3_rotate_x :: proc ( v : [3]f32, angle : f32) -> (result : [3]f32) {
	rotated_vector : [3]f32 = {


		v.x,
		v.y * math.cos(angle) - v.z * math.sin(angle),
		//TODO : applica rotazione a Z
		v.y * math.sin(angle) + v.z * math.cos(angle)
	}
	return rotated_vector
}



/*CORE LOOP */

process_input :: proc(is_running:^b32){
	event : sdl.Event
	sdl.PollEvent(&event)

	#partial switch event.type {
	case sdl.EventType.QUIT:
		is_running^ = false
	case sdl.EventType.KEYDOWN:
		if event.key.keysym.sym == sdl.Keycode.ESCAPE{
		is_running^ = false
	}
		
	}
}



perspective_projection_update :: proc (){
		previous_frame_time = sdl.GetTicks()

		cubeRotation.x += 0.01
		cubeRotation.y += 0.01
		cubeRotation.z += 0.01
		
		for i := 0; i < N_POINTS; i += 1 {
			point : [3]f32 = cube_points[i]
		
			transformed_point : [3]f32 = vec3_rotate_y(point, cubeRotation.y)
			transformed_point = vec3_rotate_x(transformed_point, cubeRotation.x)
			transformed_point = vec3_rotate_z(transformed_point, cubeRotation.z)

			transformed_point.z -= camera_position.z

			projected_point : [2]f32 
			projected_point.x = (transformed_point.x * fov_factor) / transformed_point.z
			projected_point.y = (transformed_point.y * fov_factor) / transformed_point.z

			projected_points[i] = projected_point
		}

}



update :: proc(){


		//qui per dire posso mettere il segnale del mouse per spostarlo 
		//e spostare i vari componenti ruotare ecc 
		//oppure inserisci una IMGUI e gestisci gli spostamenti tramite immediate mode GUI 

	

		//mentre trasformi il vallore of lo scali 
		//meglio metter ein una funzione diversa 
		//trasla in rendering 

	/*
			for !sdl.TICKS_PASSED(sdl.GetTicks(), previous_frame_time + FRAME_TARGET_TIME){

			}

			previous_frame_time = sdl.GetTicks()
	*/
		time_to_wait := FRAME_TARGET_TIME - (sdl.GetTicks() - previous_frame_time)
		if (time_to_wait > 0 && time_to_wait <= FRAME_TARGET_TIME){
			sdl.Delay(time_to_wait)
		}




		cubeRotation.x += 0.01
		cubeRotation.y += 0.01
		cubeRotation.z += 0.01
		//perspective_projection_update()


		for i := 0; i < N_MESH_FACES; i += 1{
			

			mesh_face : Face_t = mesh_faces[i]


			face_vertices : [3]Vector3_t


			face_vertices[0] = mesh_vertices[mesh_face.x - 1]
			face_vertices[1] = mesh_vertices[mesh_face.y - 1]
			face_vertices[2] = mesh_vertices[mesh_face.z - 1]


			projected_triangle : triangle_t


			//loop i 3 vertici della faccia e applica le trasformazioni 
			for j := 0; j < 3; j += 1{
				transformed_vertex : Vector3_t = face_vertices[j]
				transformed_vertex = vec3_rotate_x(transformed_vertex, cubeRotation.x)
				transformed_vertex = vec3_rotate_y(transformed_vertex, cubeRotation.y)
				transformed_vertex = vec3_rotate_z(transformed_vertex, cubeRotation.z)

				transformed_vertex.z -= camera_position.z

				projected_point : Vector2_t = project(transformed_vertex)


				projected_point.x += f32(window_width/2)
				projected_point.y += f32(window_height/2)

				projected_triangle.vertices[j] = projected_point


			}

			triangles_to_render[i] = projected_triangle


	}
		previous_frame_time = sdl.GetTicks()

}

render :: proc(){


	clear_color_buffer(0xFF000000, &colorBuffer)

	draw_grid()

	for number := 0; number < N_MESH_FACES; number += 1{

	triangle : triangle_t = triangles_to_render[number]

	draw_rect(int(triangle.vertices[0].x), int(triangle.vertices[0].y), 3, 3, 0xFFFFFF00)
	draw_rect(int(triangle.vertices[1].x), int(triangle.vertices[1].y), 3, 3, 0xFFFFFF00)
	draw_rect(int(triangle.vertices[2].x), int(triangle.vertices[2].y), 3, 3, 0xFFFFFF00)

	draw_triangle(	i32(triangle.vertices[0].x), i32(triangle.vertices[0].y),
					i32(triangle.vertices[1].x), i32(triangle.vertices[1].y), 
					i32(triangle.vertices[2].x), i32(triangle.vertices[2].y), 
					0xFFFFFF00 )



	/*
	 	draw_rect(int(projected_points[number].x) + int(window_width / 2), 
	 		int(projected_points[number].y) + int(window_height / 2), 
	 		4, 
	 		4, 
	 		0xFFFFFF00)
	*/

	}

	render_color_buffer()



	sdl.RenderPresent(renderer)


}


main :: proc (){
	fmt.println("hello world!")



	is_running := initialize_window()
	
	if is_running == false
	{
		fmt.println("error initializing window")
	}



	result := setup()

	if result == false {
		fmt.println("error in allocating color Buffer")
		return 
	} 

	fmt.printf("cube points ", N_POINTS)

	for is_running {
		process_input(&is_running)
		update()
		render()
	}


	sdl.DestroyRenderer(renderer)
	sdl.DestroyWindow(window)
	sdl.DestroyTexture(colorBufferTexture)
	free_all(context.temp_allocator)
	sdl.Quit()

}
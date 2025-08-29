package game_main

import "core:fmt"
import "core:mem"
import "core:math"
import "base:runtime"
import sdl "vendor:sdl2"



/*CONSTANTS and globals */
RENDER_FLAGS :: sdl.RENDERER_SOFTWARE

WINDOW_WIDTH :: 1920
WINDOW_HEIGHT :: 1080

window_width : i32
window_height : i32
	
window : ^sdl.Window 
renderer : ^sdl.Renderer

colorBufferTexture : ^sdl.Texture

color : [4]u8 = {0, 0, 0, 255}

colorBuffer : [dynamic]u32

err : runtime.Allocator_Error


cubeRotation : [3]f32



/*    ARRAY OF POINTS     */
N_POINTS :: 9 * 9 * 9

cube_points : [N_POINTS][3]f32

projected_points : [N_POINTS][2]f32


fov_factor :: 640
fov_orto :: 60


camera_position : [3]f32 = {0, 0, -5}





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



draw_pixel :: proc(x : int, y : int, color: u32){

	if i32(x) >= 0 && i32(x) < window_width && i32(y) <= window_height && i32(y) >= 0 {
		colorBuffer[(window_width * i32(y)) + i32(x)] = color
	}
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
			draw_pixel(int(current_x), int(current_y), color)
			//colorBuffer[(window_width * (i32(y)+i32(j))) + i32(k + x)] = color
		}
	}


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

			//scale 

			//translate 
		//hot_point := projected_point[number]
	
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


		
		cubeRotation.x += 0.01
		cubeRotation.y += 0.01
		cubeRotation.z += 0.01
		
		for i := 0; i < N_POINTS; i += 1 {
			point : [3]f32 = cube_points[i]
		
			transformed_point : [3]f32 = vec3_rotate_y(point, cubeRotation.y)
			//transformed_point = vec3_rotate_z(point, cubeRotation.z)
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


		//ortographic Projection 
		/*
		for i := 0; i < N_POINTS; i += 1 {
			point : [3]f32 = cube_points[i]

			projected_point : [2]f32 
			projected_point.x = point.x * fov_factor
			projected_point.y = point.y * fov_factor

			projected_points[i] = projected_point
		}
		*/

		perspective_projection_update()


/*

		for i := 0; i < N_POINTS; i += 1 {
			point : [3]f32 = cube_points[i]
			point.z -= camera_position.z

			projected_point : [2]f32 
			projected_point.x = (point.x * fov_factor) / point.z
			projected_point.y = (point.y * fov_factor) / point.z

			projected_points[i] = projected_point
		}
*/
}

render :: proc(){

	
	//sdl.SetRenderDrawColor(renderer, color.r, color.g, color.b , color.a)
	//sdl.RenderClear(renderer)


	//aggiungi draw grid??

	clear_color_buffer(0xFF000000, &colorBuffer)

	draw_grid()
	//draw_rect(50, 50, 200, 200, 0xFFFF0000)

	//draw_cube_flat()
	//ortographic_projection()
	//perspective_projection()




		for number := 0; number < N_POINTS; number += 1{

			//scale 

			//translate 
		//hot_point := projected_point[number]
	
	 	draw_rect(int(projected_points[number].x) + int(window_width / 2), int(projected_points[number].y) + int(window_height / 2), 4, 4, 0xFFFFFF00)
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
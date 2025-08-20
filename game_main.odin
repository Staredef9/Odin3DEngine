package game_main

import "core:fmt"

import sdl "vendor:sdl2"




/* WINDOW RELATED */
RENDER_FLAGS :: sdl.RENDERER_SOFTWARE


	
window : ^sdl.Window 
renderer : ^sdl.Renderer

initialize_window :: proc()->b32{

	if sdl.Init(sdl.INIT_EVERYTHING) != 0
	{
		fmt.println("error init SDL")
		return false
	}

	window = sdl.CreateWindow("Hello sdl", 300, 300, 1920, 1080,sdl.WINDOW_BORDERLESS)

	if window == nil {
		fmt.println("errror initializing window")
		return false
	}




	renderer = sdl.CreateRenderer(window, -1, RENDER_FLAGS)


	if renderer == nil {
		fmt.println("error initializing the renderer ")
		return false
	}



	return true
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


update :: proc(){

}

render :: proc(){
		
}


main :: proc (){
	fmt.println("hello world!")

	is_running := initialize_window()
	
	if is_running == false
	{
		fmt.println("error initializing window")
	}

	for is_running {
		process_input(&is_running)
		update()
		render()
	}





}
package imui

import "core:log"
import rl "vendor:raylib"
import "core:strings"
import "core:unicode/utf8"

main :: proc () {
	context.logger = log.create_console_logger()

	log.info("test")

	rl.InitWindow(640, 480, "imui")

	rl.SetTargetFPS(60)

	text_buffer : [4096]byte
	text_len : int

	for !rl.WindowShouldClose() {

		free_all(context.temp_allocator)

		{
			rl.BeginDrawing()
			defer rl.EndDrawing()

			rl.ClearBackground(rl.RAYWHITE)

			pos := rl.Rectangle {
				f32(rl.GetScreenWidth()) - 20, 0, 
				20                           , f32(rl.GetScreenHeight())
			}

			if clicked, rect := Button("x", pos); clicked {
				log.infof("clicked %v", rect)
			}

			_, written, rect := TextInput(text_buffer[:], text_len, true)
			text_len += written
			log.infof("clicked %v", rect)
		}
	}
}

TextInput :: proc (
	buffer    : []byte,
	offset    := 0,
	is_active := false,
	pos_rect  := rl.Rectangle{},
	allocator := context.temp_allocator,
	) -> (clicked: bool, written: int, input_rect: rl.Rectangle) {

	font_size : i32 = 22
	text_margin : i32 = 2

	if is_active {
		n := offset
		for {
			s := rl.GetCharPressed()
			if s == 0 do break
			bytes, size := utf8.encode_rune(s)
			if n + size <= len(buffer) {
				copy(buffer[n:], bytes[:size])
				n += size
				written += 1
			}
		}
	}

	ctext := strings.clone_to_cstring(string(buffer[:]), allocator)
	text_size := rl.MeasureText(ctext, font_size)
	input_rect = {
		pos_rect.x, pos_rect.y, 
		f32(text_size + (2 * text_margin)),
		f32(font_size + (2 * text_margin))
	}
	rl.DrawRectangleRec(rl.Rectangle(input_rect), rl.GRAY)
	rl.DrawText(
		ctext, 
		i32(pos_rect.x), 
		i32(pos_rect.y), 
		font_size, rl.BLACK,
		)


	// detect input
	mouse_position := rl.GetMousePosition()
	if rl.CheckCollisionPointRec(mouse_position, rl.Rectangle(input_rect)) &&
		rl.IsMouseButtonPressed(.LEFT) {
		clicked = true
	}

	return
}

Button :: proc (
	text      := "", 
	pos_rect  := rl.Rectangle{},
	fill_rect := false,
	allocator := context.temp_allocator,
	) -> (clicked: bool, button_rect: rl.Rectangle) {

	font_size : i32 = 22
	text_margin : i32 = 2
	ctext := strings.clone_to_cstring(text, allocator)
	text_size := rl.MeasureText(ctext, font_size)
	
	// compute size
	if fill_rect {
		button_rect = pos_rect
	} else {
		button_rect = {
			pos_rect.x, pos_rect.y, 
			f32(text_size + (2 * text_margin)),
			f32(font_size + (2 * text_margin))
		}	
	}

	// clamping
	if pos_rect.width > 0 && button_rect.width > pos_rect.width {
		button_rect.width = pos_rect.width
	}
	if pos_rect.height > 0 && button_rect.height > pos_rect.height {
		button_rect.height = pos_rect.height
	}
	
	// draw
	rl.DrawRectangleRec(rl.Rectangle(button_rect), rl.LIGHTGRAY)
	rl.DrawText(
		ctext, 
		i32(button_rect.x + (button_rect.width /2) - (f32(text_size)/2)), 
		i32(button_rect.y + (button_rect.height/2) - (f32(font_size)/2)), 
		font_size, rl.BLACK
		)

	// detect input
	mouse_position := rl.GetMousePosition()
	if rl.CheckCollisionPointRec(mouse_position, rl.Rectangle(button_rect)) &&
		rl.IsMouseButtonPressed(.LEFT) {
		clicked = true
	}
	return
}

Label :: proc (
	text      := "", 
	pos_rect  := rl.Rectangle{},
	fill_rect := false,
	allocator := context.temp_allocator,
	) -> (label_rect: rl.Rectangle) {

	font_size : i32 = 22
	text_margin : i32 = 2
	ctext := strings.clone_to_cstring(text, allocator)
	text_size := rl.MeasureText(ctext, font_size)
	
	// compute size
	if fill_rect {
		label_rect = pos_rect
	} else {
		label_rect = {
			pos_rect.x, pos_rect.y, 
			f32(text_size + (2 * text_margin)),
			f32(font_size + (2 * text_margin))
		}	
	}

	// clamping
	if pos_rect.width > 0 && label_rect.width > pos_rect.width {
		label_rect.width = pos_rect.width
	}
	if pos_rect.height > 0 && label_rect.height > pos_rect.height {
		label_rect.height = pos_rect.height
	}
	
	// draw
	//rl.DrawRectangleRec(rl.Rectangle(label_rect), rl.LIME)
	rl.DrawText(
		ctext, 
		i32(label_rect.x + (label_rect.width /2) - (f32(text_size)/2)), 
		i32(label_rect.y + (label_rect.height/2) - (f32(font_size)/2)), 
		font_size, rl.BLACK
		)

	return
}
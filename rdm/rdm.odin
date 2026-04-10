package rdm

import "core:log"
import rl "vendor:raylib"
import "core:strings"
import "core:unicode/utf8"
import "core:math"

GRAVITY :: 9.81

to_newton :: proc (kg: f32) -> f32 {
	return kg * GRAVITY
}

to_mass :: proc (N: f32) -> f32 {
	return N / GRAVITY
}

Beam :: struct {
	EI: f32,
	points: []rl.Vector2,
	length: f32,
	step: f32,
}

new_beam :: proc (EI: f32, resolution: int, length: f32) -> Beam {
	return {
		EI = EI,
		points = make([]rl.Vector2, resolution),
		length = length,
		step = length / f32(resolution),
	}
}

delete_beam :: proc (beam: Beam) {
	delete(beam.points)
}

Force :: struct {
	load: rl.Vector2,
	position: rl.Vector2,
}

solve :: proc(beam: ^Beam, force: Force) {
	step := beam.step
	EI   := beam.EI
	a    := force.position.x

	for i in 0..<len(beam.points) {
		pos_x := f32(i) * step
		f: f32

		if pos_x <= a {
		  f = (force.load.y * pos_x * pos_x / (6 * EI)) * (3 * a - pos_x)
		} else {
		  f = (force.load.y * a * a / (6 * EI)) * (3 * pos_x - a)
		}

		beam.points[i] += {0, f}
	}
}

apply_length_correction :: proc(beam: ^Beam) {
	step := beam.step
	beam.points[0].x = 0

	for i in 1..<len(beam.points) {
		dy := beam.points[i].y - beam.points[i-1].y
		dx := math.sqrt(max(step * step - dy * dy, 0))
		beam.points[i].x = beam.points[i-1].x + dx
	}
}

main :: proc () {
	context.logger = log.create_console_logger()

	rl.InitWindow(800, 600, "rdm")

	rl.SetTargetFPS(60)

	text_buffer : [4096]byte
	text_len : int

	for !rl.WindowShouldClose() {

		free_all(context.temp_allocator)

		{
			rl.BeginDrawing()
			defer rl.EndDrawing()
			rl.ClearBackground(rl.RAYWHITE)
			
			start_point := rl.Vector2{10, 200}

			s := math.sin(f32(rl.GetTime()))

			beam := new_beam(10000000, 500, 700)
			defer delete_beam(beam)

			force1 := Force{
				{0  , -300 * s},
				{200,        0},
			}

			force2 := Force{
				{0  , 100 * s},
				{400,       0},
			}

			solve(&beam, force1)
			solve(&beam, force2)
			apply_length_correction(&beam)

			rl.DrawCircleLinesV(start_point, beam.length, rl.BLACK)
			
			step := beam.step
			for i in 0..<len(beam.points) {
				pos := beam.points[i] + start_point
				rl.DrawCircleV(pos, 1, rl.RED)

				if beam.points[i].x > force1.position.x && beam.points[i].x < force1.position.x + step {
					rl.DrawLineV(pos, force1.load + pos, rl.BLUE)
				}

				if beam.points[i].x > force2.position.x && beam.points[i].x < force2.position.x + step {
					rl.DrawLineV(pos, force2.load + pos, rl.BLUE)
				}
			}
		}
	}
}


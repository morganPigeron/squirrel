package rdm

import "core:log"
import rl "vendor:raylib"
import "core:strings"
import "core:unicode/utf8"
import "core:math"

solve :: proc(branch: []rl.Vector2, branch_length: f32, force, force_position: rl.Vector2) {
	step := branch_length / f32(len(branch))
	EI: f32 = 10000000
	a := force_position.x

	for i in 0..<len(branch) {
		pos_x := f32(i) * step
		f: f32

		if pos_x <= a {
		  f = (force.y * pos_x * pos_x / (6 * EI)) * (3 * a - pos_x)
		} else {
		  f = (force.y * a * a / (6 * EI)) * (3 * pos_x - a)
		}

		branch[i] += {0, f}
	}
}

apply_length_correction :: proc(branch: []rl.Vector2, branch_length: f32) {
	step := branch_length / f32(len(branch))
	branch[0].x = 0

	for i in 1..<len(branch) {
		dy := branch[i].y - branch[i-1].y
		dx := math.sqrt(max(step * step - dy * dy, 0))

		branch[i].x = branch[i-1].x + dx
	}
}

main :: proc () {
	context.logger = log.create_console_logger()

	log.info("test")

	rl.InitWindow(800, 600, "imui")

	rl.SetTargetFPS(60)

	text_buffer : [4096]byte
	text_len : int

	for !rl.WindowShouldClose() {

		free_all(context.temp_allocator)

		{
			rl.BeginDrawing()
			defer rl.EndDrawing()
			rl.ClearBackground(rl.RAYWHITE)
			
			branch : [500]rl.Vector2
			branch_length :f32= 700
			start_point := rl.Vector2{10, 200}

			s := math.sin(f32(rl.GetTime()))
			force1 := rl.Vector2{0, -300 * s}
			force1_position := rl.Vector2{200, 0}

			force2 := rl.Vector2{0, 100 * s}
			force2_position := rl.Vector2{400, 0}

			solve(branch[:], branch_length, force1, force1_position)
			solve(branch[:], branch_length, force2, force2_position)
			apply_length_correction(branch[:], branch_length)

			rl.DrawCircleLinesV(start_point, branch_length, rl.BLACK)
			
			step := branch_length / f32(len(branch))
			for i in 0..<len(branch) {
				pos := branch[i] + start_point
				rl.DrawCircleV(pos, 1, rl.RED)

				if branch[i].x > force1_position.x && branch[i].x < force1_position.x + step {
					rl.DrawLineV(pos, force1 + pos, rl.BLUE)
				}

				if branch[i].x > force2_position.x && branch[i].x < force2_position.x + step {
					rl.DrawLineV(pos, force2 + pos, rl.BLUE)
				}
			}
		}
	}
}


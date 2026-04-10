package main

import rl "vendor:raylib"
import "core:math"

draw_tree :: proc (position: rl.Vector3, height, start_radius, end_radius: f32) {

	RESOLUTION :: 20

	// calcul de la déformé de la branche
	// calcul de la déformé du tronc en prenant en compte la branche
	// calcul de la déformé de la branche en prenant en compte le tronc déformé 
	// boucle jusqua deformé seuil 

	// branch
	branch_angle        := f32(30 * rl.DEG2RAD)
	branch_start_radius := start_radius/2
	branch_end_radius   := branch_start_radius/2
	branch_length       :f32 = height/3
	branch_height       :f32 = height/2

	// thales: BC (AC' / AC)
	branch_slope_delta  := (start_radius - end_radius) * (branch_height/height) 
	branch_tronc_radius := start_radius - branch_slope_delta

	// R^2 = (br/2)^2 + x^2
	branch_center_offset:= math.sqrt( math.pow(branch_tronc_radius, 2) - math.pow(branch_start_radius, 2) )

	branch_start_x      := branch_center_offset * math.cos(branch_angle)
	branch_start_y      := branch_center_offset * math.sin(branch_angle)
	branch_start_point  := position + {branch_start_x, branch_height, branch_start_y} 
	branch_origin       := position + {             0, branch_height,              0}
	branch_unit_dir     := rl.Vector3Normalize(branch_start_point - branch_origin) 
	branch_vector       := branch_unit_dir * branch_length + branch_start_point


	// tronc
	rl.DrawCylinderWiresEx(position, {position.x, height, position.y}, start_radius, end_radius, RESOLUTION, rl.BROWN)
	// branch
	rl.DrawCylinderWiresEx(branch_start_point, branch_vector, branch_start_radius, branch_end_radius, RESOLUTION, rl.GREEN)
	{
		rl.DrawLine3D(branch_origin, branch_start_point, rl.RED)
		rl.DrawLine3D(branch_start_point, branch_vector, rl.BLUE)
	}
}
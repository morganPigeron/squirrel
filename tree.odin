package main

import rl "vendor:raylib"
import "core:math"
import "core:log"

import "rdm"

Tree :: struct {
	position: rl.Vector3, 
	height: f32, 
	start_radius: f32, 
	end_radius: f32,
}

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
	rl.DrawCylinderEx(position, {position.x, height, position.y}, start_radius, end_radius, RESOLUTION, rl.BROWN)
	// branch
	rl.DrawCylinderWiresEx(branch_start_point, branch_vector, branch_start_radius, branch_end_radius, RESOLUTION, rl.GREEN)
	{
		rl.DrawLine3D(branch_origin, branch_start_point, rl.RED)
		rl.DrawLine3D(branch_start_point, branch_vector, rl.BLUE)
	}
}

draw_branch_on_tree :: proc (tree: Tree, branch: rdm.Beam, angle_rad: f32) {

	RESOLUTION :: 20

	// calcul de la déformé de la branche
	// calcul de la déformé du tronc en prenant en compte la branche
	// calcul de la déformé de la branche en prenant en compte le tronc déformé 
	// boucle jusqua deformé seuil 

	// branch
	branch_angle        := angle_rad
	branch_start_radius :f32= 0.1
	branch_end_radius   := 0.05
	branch_length       := branch.length
	branch_height       :f32 = tree.height/2

	// thales: BC (AC' / AC)
	branch_slope_delta  := (tree.start_radius - tree.end_radius) * (branch_height/tree.height) 
	branch_tronc_radius := tree.start_radius - branch_slope_delta

	// R^2 = (br/2)^2 + x^2
	branch_center_offset:= math.sqrt( math.pow(branch_tronc_radius, 2) - math.pow(branch_start_radius, 2) )

	branch_start_x      := branch_center_offset * math.cos(branch_angle)
	branch_start_y      := branch_center_offset * math.sin(branch_angle)
	branch_start_point  := tree.position + {branch_start_x, branch_height, branch_start_y} 
	branch_origin       := tree.position + {             0, branch_height,              0}
	branch_unit_dir     := rl.Vector3Normalize(branch_start_point - branch_origin) 
	branch_vector       := branch_unit_dir * branch_length + branch_start_point

	rl.DrawLine3D(branch_origin, branch_vector, rl.PURPLE)

	// tronc
	rl.DrawCylinderWiresEx(
		tree.position, 
		{
			tree.position.x, 
			tree.height, 
			tree.position.y
		}, 
		tree.start_radius, tree.end_radius, RESOLUTION, rl.GREEN)
	// branch
	draw_physic_branch(branch, branch_start_point, branch_unit_dir)
	/*
	rl.DrawCylinderWiresEx(branch_start_point, branch_vector, branch_start_radius, branch_end_radius, RESOLUTION, rl.GREEN)
	{
		rl.DrawLine3D(branch_origin, branch_start_point, rl.RED)
		rl.DrawLine3D(branch_start_point, branch_vector, rl.BLUE)
	}
	*/
}

draw_physic_branch :: proc (beam: rdm.Beam, base: rl.Vector3, dir: rl.Vector3) {

	from := rl.Vector3{1, 0, 0}
	to   := rl.Vector3Normalize(dir)

	axis  := rl.Vector3CrossProduct(from, to)
	angle := rl.Vector3Angle(from, to)

	rot := rl.MatrixRotate(axis, angle)

	for i in 1..<(len(beam.points)) {

		start := rl.Vector3{beam.points[i-1].x, beam.points[i-1].y, 0}
		end   := rl.Vector3{beam.points[i].x,   beam.points[i].y,   0}

		start_rotated := rl.Vector3Transform(start, rot) + base
		end_rotated   := rl.Vector3Transform(end,   rot) + base

		section_start := 0.1 - (f32(i-1) * 0.05 / f32(len(beam.points)))
		section_end   := 0.1 - (f32(i  ) * 0.05 / f32(len(beam.points)))

		rl.DrawCylinderEx(start_rotated, end_rotated, section_start , section_end, 10, rl.BROWN)
	}
}

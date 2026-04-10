package main

import rl "vendor:raylib"
import "core:math"
import "core:log"

import "rdm"

RESOLUTION :: 20

BRANCH_SECTION_START :: 0.03
BRANCH_SECTION_END   :: 0.02

Tree :: struct {
	position: rl.Vector3, 
	height: f32, 
	start_radius: f32, 
	end_radius: f32,
}

draw_tree :: proc (tree: Tree) {
	rl.DrawCylinderWiresEx(
	tree.position, 
	{
		tree.position.x, 
		tree.height, 
		tree.position.y
	}, 
	tree.start_radius, tree.end_radius, RESOLUTION, rl.GREEN)
}

draw_branch_on_tree :: proc (tree: Tree, branch: rdm.Beam, angle_rad, height: f32) {
	// calcul de la déformé de la branche
	// calcul de la déformé du tronc en prenant en compte la branche
	// calcul de la déformé de la branche en prenant en compte le tronc déformé 
	// boucle jusqua deformé seuil 

	// branch
	branch_angle        := angle_rad
	branch_start_radius :f32= BRANCH_SECTION_START
	branch_end_radius   := BRANCH_SECTION_END
	branch_length       := branch.length
	branch_height       := height

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

	// branch
	draw_physic_branch(branch, branch_start_point, branch_unit_dir)
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

		t0 := f32(i-1) / f32(len(beam.points)-1)
		t1 := f32(i  ) / f32(len(beam.points)-1)

		section_start := BRANCH_SECTION_START + t0 * (BRANCH_SECTION_END - BRANCH_SECTION_START)
		section_end   := BRANCH_SECTION_START + t1 * (BRANCH_SECTION_END - BRANCH_SECTION_START)

		rl.DrawCylinderEx(start_rotated, end_rotated, section_start , section_end, 5, rl.BROWN)
	}
}

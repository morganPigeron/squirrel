package main

import rl "vendor:raylib"
import "core:math"

import "rdm"

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

draw_physic_branch :: proc (beam: rdm.Beam, base: rl.Vector3, dir: rl.Vector3) {

	angle := rl.Vector3Angle(dir, {1,0,0})

    for i in 1..<(len(beam.points)) {
        start_point := beam.points[i-1]
        end_point   := beam.points[i]

        start := rl.Vector3 {
            start_point.x,
            start_point.y,
            0,
        }

        end := rl.Vector3 {
            end_point.x,
            end_point.y,
            0,
        }

        start_rotated := rl.Vector3RotateByAxisAngle(start, {0,1,0}, angle) + base
		end_rotated   := rl.Vector3RotateByAxisAngle(end  , {0,1,0}, angle) + base
		
		section_start := 0.1 - (f32(i-1) * 0.05 / f32(len(beam.points)))
		section_end   := 0.1 - (f32(i  ) * 0.05 / f32(len(beam.points)))

        rl.DrawCylinderEx(start_rotated, end_rotated, section_start , section_end, 10, rl.BROWN)
    }
}
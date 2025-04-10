package main

import "core:log"
import "core:fmt"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

paths: map[[6]f32]Land // [.. from, ..to]

from_to :: #force_inline proc (from: [3]f32, to: [3]f32) -> (result: [6]f32) {
    for i in 0..<3 {
        result[i] = from[i]
        result[i+3] = to[i+3]
    }    
    return 
}

Entity :: struct {
    position: [3]f32,
    offset: [3]f32,
    delta_offset: f32,
    texture: rl.Texture,
    scale: f32,
    target: [3]f32,
    is_target_valid: bool,
    is_going_home: bool,
    picked: bool,
}

find_nearest_not_picked :: proc (from: [3]f32, entities: []Entity) -> (index: int) {

    nearest: f32 = max(f32)

    for e,i in entities {
        dist := rl.Vector3DistanceSqrt(from, e.position)
        if dist < nearest && !e.picked {
            nearest = dist
            index = i
        }
    }
    
    return
}

find_around_not_picked :: proc (e: []Entity, position: [3]f32, radius: f32) -> (found_index: int, is_found: bool) {

    for elem, i in e {
        if elem.picked {
            continue
        }
        if rl.Vector3DistanceSqrt(elem.position, position) <= radius {
            found_index = i
            is_found = true
            break
        }
    }
    
    return
}

map_size :: 10
update_smart_entity :: proc (c: rl.Camera, e: ^Entity, f: []Entity) {

    if ( // reached food
        rl.Vector3DistanceSqrt(e.target, e.position) < 0.1 &&
        e.is_target_valid &&
        !e.is_going_home
       ) { 
        found_index, is_found := find_around_not_picked(f, e.position, 0.1)
        if is_found {
            f[found_index].picked = true
            e.is_going_home = true
            e.target = {0,0,0}
        } else {
            //reused code
            found_index := find_nearest_not_picked(e.position, f)
            e.target = f[found_index].position
        }
    } else if ( // reached home
        rl.Vector3DistanceSqrt(e.target, e.position) < 0.1 &&
        e.is_target_valid &&
        e.is_going_home) {
        e.is_target_valid = false
        e.is_going_home = false
    }

    
    if (!e.is_target_valid) {
        found_index := find_nearest_not_picked(e.position, f)
        e.target = f[found_index].position
        e.is_target_valid = true
    }
    
    e.position += rl.Vector3Normalize(e.target - e.position) * rl.GetFrameTime() 
        
}

make_squirrels :: proc () -> (squirrels: []Entity, text: rl.Texture) {
    max_count :: 10
    squirrels = make([]Entity, max_count)
    text = rl.LoadTexture("squirrel.png")
    for &s in squirrels {
        s.texture = text
        s.offset = {0,0,0}
        s.scale = 0.5
        s.position = {rand.float32_range(-5,5)*2, 0, rand.float32_range(-5,5)*2}
    }
    
    return
}

make_foods :: proc () -> (foods: []Entity, food_text: rl.Texture) {
    max_food :: 100
    foods = make([]Entity, max_food)
    food_text = rl.LoadTexture("food.png")
    for &f in foods {
        f.texture = food_text
        f.offset = {0,0.1,0}
        f.scale = 0.5
        f.delta_offset = 0.2
        f.position = {rand.float32_range(-5,5)*2, 0, rand.float32_range(-5,5)*2}
    }
    return
}

update_dumb_entity :: proc (c: rl.Camera, e: ^Entity) {
    max_height :: 0.3
    min_height :: 0
    e.offset.y += (e.delta_offset * rl.GetFrameTime())
    if e.offset.y >= max_height || e.offset.y <= min_height {
        e.delta_offset *= -1 
    }
} 

draw_entity :: proc (c: rl.Camera, e: Entity, debug: bool) {

    if !e.picked {
        rl.DrawBillboardPro(
            c,
            e.texture,
            {0, 0, f32(e.texture.width), f32(e.texture.height)}, //source 
            e.position + e.offset, //position
            {0, 1, 0}, //up
            {1, 1} * e.scale, //size
            {0.5, 0} * e.scale, //origin
            0,
            rl.WHITE
        )

        if debug {
            rl.DrawLine3D(e.position, e.position + {1,0,0},rl.RED)
            rl.DrawLine3D(e.position, e.position + {0,1,0},rl.GREEN)
            rl.DrawLine3D(e.position, e.position + {0,0,1},rl.BLUE)

            rl.DrawLine3D(e.position, e.target, rl.PURPLE)
        }
    }
}

delete_entity :: proc (e: ^Entity) {
    rl.UnloadTexture(e.texture)
}

handle_camera_inputs :: proc (camera: ^rl.Camera) {

    wheel := rl.GetMouseWheelMove() * rl.GetFrameTime() * 10
    if (rl.IsKeyDown(.LEFT_SHIFT)) {
        wheel *= 10
    }
    
    camera.position.y += wheel
    camera.target.y += wheel
    if (camera.position.y < 0) {
        camera.position.y = 0
        camera.target.y -= wheel
    } 

}

main :: proc () {

    context.logger = log.create_console_logger()

    
    rl.SetConfigFlags({.WINDOW_RESIZABLE})  
    rl.InitWindow(1920, 1080, "squirrel")
    defer rl.CloseWindow()

    rl.DisableCursor()

    alphaDiscard := rl.LoadShader(nil, "alphaDiscard.fs")
    
    camera := rl.Camera{}
    camera.position = {5,4,5}
    camera.target = {0,2,0}
    camera.up = {0,1,0}
    camera.fovy = 45
    camera.projection = .PERSPECTIVE

    tree : Entity
    tree.texture = rl.LoadTexture("tree.png")
    tree.scale = 3
    tree.offset = {0,0,0}
    defer delete_entity(&tree)

    squirrels, text := make_squirrels()
    defer {
        rl.UnloadTexture(text)
        delete(squirrels)
    }

    foods, food_text := make_foods()
    defer {
        rl.UnloadTexture(food_text)
        delete(foods)
    }
    
    rl.SetTargetFPS(60)
    
    for !rl.WindowShouldClose() {
        
        if rl.IsCursorHidden() {
            rl.UpdateCamera(&camera, .FIRST_PERSON)
        }
        
        if rl.IsMouseButtonPressed(.RIGHT) {
            if rl.IsCursorHidden() {
                rl.EnableCursor()
            } else {
                rl.DisableCursor()
            }
        }

        handle_camera_inputs(&camera)
        
        for &s in squirrels {
            update_smart_entity(camera, &s, foods)
        }
        for &f in foods {
            update_dumb_entity(camera, &f)
        }
        
        {
            rl.BeginDrawing()
            defer rl.EndDrawing()

            rl.ClearBackground(rl.RAYWHITE)

            {
                rl.BeginMode3D(camera)
                defer rl.EndMode3D()

                rl.BeginShaderMode(alphaDiscard);
                defer rl.EndShaderMode()

                rl.DrawGrid(map_size*2, 1)
                rl.DrawLine3D({0,0,0},{1,0,0},rl.RED)
                rl.DrawLine3D({0,0,0},{0,1,0},rl.GREEN)
                rl.DrawLine3D({0,0,0},{0,0,1},rl.BLUE)

                draw_entity(camera, tree, false)
                for f in foods {
                    draw_entity(camera, f, false)
                }
                for s in squirrels {
                    draw_entity(camera, s, true)
                }
                
            }

            rl.DrawFPS(10,10)
        }
        
    }
}

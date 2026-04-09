package main

import "core:log"
import "core:fmt"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

import "imui"

main :: proc () {

    context.logger = log.create_console_logger()
    
    rl.SetConfigFlags({.WINDOW_RESIZABLE})  
    rl.InitWindow(1920, 1080, "squirrel")
    defer rl.CloseWindow()

    rl.DisableCursor()

    alphaDiscard := rl.LoadShader(nil, "alphaDiscard.fs")
    
    camera := rl.Camera{}
    camera.position = {5,10,5}
    camera.target = {0,0,0}
    camera.up = {0,1,0}
    camera.fovy = 45
    camera.projection = .PERSPECTIVE

    tree: Entity
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
    
    rl.SetTargetFPS(240)
    
    for !rl.WindowShouldClose() {

        free_all(context.temp_allocator)

        if rl.IsCursorHidden() {
            camera_update(&camera)
        }
        
        if rl.IsMouseButtonPressed(.RIGHT) {
            if rl.IsCursorHidden() {
                rl.EnableCursor()
            } else {
                rl.DisableCursor()
            }
        }
        
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

                draw_debug()

                draw_tree({}, 10, 0.3, 0.1)

                //draw_entity(camera, tree, false)
                for f in foods {
                    draw_entity(camera, f, false)
                }
                for s in squirrels {
                    draw_entity(camera, s, true)
                }
                
            }

            rl.DrawFPS(10,10)
            
            rect :rl.Rectangle
            clicked :bool
            @static toggled := false
            if clicked, rect = imui.Button("debug", {10, 40, 0, 0}); clicked {              
                toggled = !toggled     
            }    
            if toggled {
                rect = imui.Label(fmt.tprintf("%v", camera), {10, rect.y + rect.height + 2, 0, 0})
            } 
            
        }
    }
}


camera_update :: proc (camera: ^rl.Camera) { 

    movement : rl.Vector3 = {}
    rotation : rl.Vector3 = {}

    if (rl.IsKeyDown(.W) || rl.IsKeyDown(.UP))    do movement.x += 0.01
    if (rl.IsKeyDown(.S) || rl.IsKeyDown(.DOWN))  do movement.x -= 0.01
    if (rl.IsKeyDown(.D) || rl.IsKeyDown(.RIGHT)) do movement.y += 0.01
    if (rl.IsKeyDown(.A) || rl.IsKeyDown(.LEFT))  do movement.y -= 0.01
    movement.z = rl.GetMouseWheelMove() * -0.5
    
    rotation = rl.GetMouseDelta().xyx * 0.05
    rotation.z = 0
    rl.UpdateCameraPro(camera, movement, rotation, 0)

}

draw_debug :: proc () {
    map_size :: 10
    rl.DrawGrid(map_size*2, 1)
    rl.DrawLine3D({0,0,0},{1,0,0},rl.RED)
    rl.DrawLine3D({0,0,0},{0,1,0},rl.GREEN)
    rl.DrawLine3D({0,0,0},{0,0,1},rl.BLUE)
}
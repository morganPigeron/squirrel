package main

import "core:log"
import "core:fmt"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

Entity :: struct {
    position: [3]f32,
    offset: [3]f32,
    texture: rl.Texture,
    scale: f32,
}

update_entity :: proc (c: rl.Camera, e: ^Entity) {
    e.position +=
        ({rand.float32_range(-1,1), 0, rand.float32_range(-1,1)}) * rl.GetFrameTime()
}

draw_entity :: proc (c: rl.Camera, e: Entity) {
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

    max_count :: 100_000
    squirrels : []Entity = make([]Entity, max_count)
    text := rl.LoadTexture("squirrel.png")
    for &s in squirrels {
        s.texture = text
        s.offset = {0,0,0}
        s.scale = 0.5
        s.position = {rand.float32_range(-10,10), 0, rand.float32_range(-10,10)}
    }
    defer {
        rl.UnloadTexture(text)
        delete(squirrels)
    }

    rl.SetTargetFPS(60)
    
    for !rl.WindowShouldClose() {
        rl.UpdateCamera(&camera, .FIRST_PERSON)

        if rl.IsMouseButtonPressed(.RIGHT) {
            if rl.IsCursorHidden() {
                rl.EnableCursor()
            } else {
                rl.DisableCursor()
            }
        }

        handle_camera_inputs(&camera)
        
        for &s in squirrels {
            update_entity(camera, &s)
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

                rl.DrawGrid(10,1)
                rl.DrawLine3D({0,0,0},{1,0,0},rl.RED)
                rl.DrawLine3D({0,0,0},{0,1,0},rl.GREEN)
                rl.DrawLine3D({0,0,0},{0,0,1},rl.BLUE)

                draw_entity(camera, tree)
                for s in squirrels {
                    draw_entity(camera, s)
                }
                
            }

            rl.DrawFPS(10,10)
        }
        
    }
}

const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const MAX_FRAME_SPEED = 15;
const MIN_FRAME_SPEED = 1;

// duck animation configs
const DUCK_FRAMES = 6; // 4 frames per animation
const DUCK_ROWS = 4; // 4 rows in the sheet
const WALK_ROW = 1; // second row (0-indexed)

pub fn main() void {
    // screen configs
    const screen_height = 450;
    const screen_width = 800;

    rl.InitWindow(screen_width, screen_height, " 🦆 Walking Duck 🦆");
    defer rl.CloseWindow();

    // load the duck sprite sheet texture
    const duck_texture = rl.LoadTexture("src/assets/ducky_3_spritesheet.png");
    defer rl.UnloadTexture(duck_texture);

    // calculate the frame dimensions
    const frame_height = @as(f32, @floatFromInt(duck_texture.height)) / DUCK_ROWS;
    const frame_width = @as(f32, @floatFromInt(duck_texture.width)) / DUCK_FRAMES;

    // duck position on screen
    var position = rl.Vector2{ .x = 350.0, .y = 280.0 };

    // animation frame rectangle (source rectangle from spritesheet)
    var frame_rectangle = rl.Rectangle{
        .x = 0.0,
        .y = frame_height * WALK_ROW, // start at the walking row
        .width = frame_width,
        .height = frame_height,
    };

    // variables for animation
    var current_frame: i32 = 0;
    var frame_counter: i32 = 0;
    var frame_speed: i32 = 8; // animation speed (frames per second)

    // movement variables
    var moving_right = true;
    const duck_speed: f32 = 2.0;

    // set target fps with raylib
    rl.SetTargetFPS(60);

    // main game loop
    while (!rl.WindowShouldClose()) {
        // Update section
        //--------------------------------------------------------------------------------------------------------------\\
        frame_counter += 1;

        if (frame_counter >= (@divTrunc(60, frame_speed))) {
            frame_counter = 0;
            current_frame += 1;

            // loop back to first frame when reaching the end
            if (current_frame >= DUCK_FRAMES) {
                current_frame = 0;
            }

            // update frame rectangle x position
            frame_rectangle.x = @as(f32, @floatFromInt(current_frame)) * frame_width;
        }

        // control animation speed with arrow keys
        if (rl.IsKeyPressed(rl.KEY_RIGHT)) {
            frame_speed += 1;
        } else if (rl.IsKeyPressed(rl.KEY_LEFT)) {
            frame_speed -= 1;
        }

        // clamp frame speed
        if (frame_speed > MAX_FRAME_SPEED) frame_speed = MAX_FRAME_SPEED;
        if (frame_speed < MIN_FRAME_SPEED) frame_speed = MIN_FRAME_SPEED;

        // move the duck horizontally and bounce off screen edges
        if (moving_right) {
            position.x += duck_speed;
            if (position.x > @as(f32, @floatFromInt(screen_width)) - frame_width * 2.0) {
                moving_right = false;
            }
        } else {
            position.x -= duck_speed;
            if (position.x < 0) {
                moving_right = true;
            }
        }

        // manual control with WASD keys
        if (rl.IsKeyDown(rl.KEY_W)) position.y -= 3.0;
        if (rl.IsKeyDown(rl.KEY_S)) position.y += 3.0;
        if (rl.IsKeyDown(rl.KEY_A)) position.x -= 3.0;
        if (rl.IsKeyDown(rl.KEY_D)) position.x += 3.0;

        //--------------------------------------------------------------------------------------------------------------\\

        // Draw Section
        //--------------------------------------------------------------------------------------------------------------\\
        rl.BeginDrawing();
        defer rl.EndDrawing();

        rl.ClearBackground(rl.SKYBLUE);

        // draw the full sprite sheet for reference (smaller scale)
        const reference_scale = 0.5;
        rl.DrawTextureEx(duck_texture, rl.Vector2{ .x = 15, .y = 40 }, 0.0, reference_scale, rl.WHITE);

        // draw frame outline on reference sprite sheet
        rl.DrawRectangleLines(15 + @as(i32, @intFromFloat(frame_rectangle.x * reference_scale)), 40 + @as(i32, @intFromFloat(frame_rectangle.y * reference_scale)), @as(i32, @intFromFloat(frame_width * reference_scale)), @as(i32, @intFromFloat(frame_height * reference_scale)), rl.LIME);

        // Draw the animated duck (current frame)
        const scale = 2.0; // double the size of the duck
        var dest_rectangle = rl.Rectangle{
            .x = position.x,
            .y = position.y,
            .width = frame_width * scale,
            .height = frame_height * scale,
        };

        // flip horizontally when moving left
        if (!moving_right) {
            dest_rectangle.width = -dest_rectangle.width;
        }

        rl.DrawTexturePro(
            duck_texture,
            frame_rectangle,
            dest_rectangle,
            rl.Vector2{ .x = 0, .y = 0 },
            0.0,
            rl.WHITE,
        );

        // Draw the UI text
        rl.DrawText("Duck Walking Animation (4 frames)", 10, 10, 20, rl.DARKGRAY);
        rl.DrawText(rl.TextFormat("Frame Speed: %i fps (Current: %i/4)", frame_speed, current_frame + 1), 10, screen_height - 60, 10, rl.DARKGRAY);
        rl.DrawText("Use LEFT/RIGHT arrows to change animation speed", 10, screen_height - 40, 10, rl.DARKGRAY);
        rl.DrawText("Use WASD to move duck manually", 10, screen_height - 20, 10, rl.DARKGRAY);
        //--------------------------------------------------------------------------------------------------------------\\
    }
}

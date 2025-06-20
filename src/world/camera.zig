const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const constants = @import("../utils/constants.zig");

pub const Camera = struct {
  camera: rl.Camera2D,

    pub fn init() Camera{
        return Camera{
            .camera = rl.Camera2D{
                .target = rl.Vector2{ .x = 0.0, .y = 0.0 },
                .offset = rl.Vector2{
                    .x = @as(f32, @floatFromInt(constants.SCREEN_WIDTH)) / 2,
                    .y = @as(f32, @floatFromInt(constants.SCREEN_HEIGHT)) / 2, 
                },
                .rotation = 0.0,
                .zoom = 1.0,
            }
        };
    }

    pub fn update(self: *Camera, duck_x_pos: f32, duck_y_pos: f32) void {
        self.camera.target = rl.Vector2{ .x = duck_x_pos + 20.0, .y = duck_y_pos + 20.0, };
    }
};
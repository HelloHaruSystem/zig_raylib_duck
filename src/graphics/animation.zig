const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});
const constants = @import("../utils/constants.zig");

pub const Animation = struct {
    texture: rl.Texture2D,
    frame_width: f32,
    frame_height: f32,
    current_frame: i32,
    frame_counter: i32,
    frame_speed: i32,
    current_row: i32,
    idle_frame_count: i32,
    walk_frame_count: i32,
    row_count: i32,

    pub fn init(texture: rl.Texture2D, idle_frame_count: i32, walk_frame_count: i32, row_count: i32) Animation {
        // use the larger frame count for calculating frame width to ensure it works
        const max_frame_count = @max(idle_frame_count, walk_frame_count);

        return Animation{
            .texture = texture,
            .frame_width = @as(f32, @floatFromInt(texture.width)) / @as(f32, @floatFromInt(max_frame_count)),
            .frame_height = @as(f32, @floatFromInt(texture.height)) / @as(f32, @floatFromInt(row_count)),
            .current_frame = 0,
            .frame_counter = 0,
            .frame_speed = constants.DEFAULT_FRAME_SPEED,
            .current_row = constants.IDLE_ROW, // start with idle animation
            .idle_frame_count = idle_frame_count,
            .walk_frame_count = walk_frame_count,
            .row_count = row_count,
        };
    }

    fn getCurrentFrameCount(self: *Animation) i32 {
        return switch (self.current_row) {
            constants.IDLE_ROW => self.idle_frame_count,
            constants.WALK_ROW => self.walk_frame_count,
            else => self.idle_frame_count // default to idle frame count
        };
    }

    pub fn update(self: *Animation) void {
        self.frame_counter += 1;

        if (self.frame_counter >= (@divTrunc(60, self.frame_speed))) {
            self.frame_counter = 0;
            self.current_frame += 1;

            // loop back to first frame when reaching the end
            const current_frame_count = self.getCurrentFrameCount();
            if (self.current_frame >= current_frame_count) {
                self.current_frame = 0;
            }
        }
    }

    pub fn getSourceRectangle(self: *Animation) rl.Rectangle {
        return rl.Rectangle{
            .x = @as(f32, @floatFromInt(self.current_frame)) * self.frame_width,
            .y = @as(f32, @floatFromInt(self.current_row)) * self.frame_height,
            .width = self.frame_width,
            .height = self.frame_height,
        };
    }

    pub fn changeSpeed(self: *Animation, delta: i32) void {
        self.frame_speed += delta;
        if (self.frame_speed > constants.MAX_FRAME_SPEED) self.frame_speed = constants.MAX_FRAME_SPEED;
        if (self.frame_speed < constants.MIN_FRAME_SPEED) self.frame_speed = constants.MIN_FRAME_SPEED;
    }

    pub fn setRow(self: *Animation, row: i32) void {
        if (row >= 0 and row < self.row_count) {
            self.current_row = row;

            // reset frame when changing rows to avoid out-of-bounds!
            const current_frame_count = self.getCurrentFrameCount();
            if (self.current_frame >= current_frame_count) {
                self.current_frame = 0;
            }
        }
    }

    pub fn resetFrame(self: *Animation) void {
        self.current_frame = 0;
        self.frame_counter = 0;
    }

    pub fn draw(self: *Animation, position: rl.Vector2, scale: f32, flip_horizontal: bool) void {
        const source_rectangle = self.getSourceRectangle();

        // flip the source rectangle width if we want to flip horizontall
        var final_source = source_rectangle;
        if (flip_horizontal) {
            final_source.width = -final_source.width;
        }

        const destination_rectangle = rl.Rectangle{
            .x = position.x,
            .y = position.y,
            .width = self.frame_width * scale,
            .height = self.frame_height * scale,
        };

        rl.DrawTexturePro(
            self.texture,
            final_source,
            destination_rectangle,
            rl.Vector2{ .x = 0, .y = 0 },
            0.0,
            rl.WHITE,
        );
    }

    pub fn drawReference(self: *Animation, position: rl.Vector2, scale: f32) void {
        // Draw the full sprite sheet for reference
        rl.DrawTextureEx(self.texture, position, 0.0, scale, rl.WHITE);

        // Draw frame outline on reference sprite sheet
        const source_rectangle = self.getSourceRectangle();
        rl.DrawRectangleLines(
            @as(i32, @intFromFloat(position.x + source_rectangle.x * scale)),
            @as(i32, @intFromFloat(position.y + source_rectangle.y * scale)),
            @as(i32, @intFromFloat(self.frame_width * scale)),
            @as(i32, @intFromFloat(self.frame_height * scale)),
            rl.LIME,
        );
    }
};

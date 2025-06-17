const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const Animation = @import("../graphics/animation.zig").Animation;
const Input = @import("input.zig").Input;
const constants = @import("../utils/constants.zig");

pub const Duck = struct {
    position: rl.Vector2,
    animation: Animation,

    pub fn init(texture: rl.Texture2D) Duck {
        return Duck{
            .position = rl.Vector2{ .x = 350.0, .y = 280.0 },
            .animation = Animation.init(texture, constants.DUCK_FRAMES, constants.DUCK_ROWS),
        };
    }

    pub fn update(self: *Duck, input: Input) void {
        // handle animation speed
        if (input.speed_up) {
            self.animation.changeSpeed(1);
        } else if (input.speed_down) {
            self.animation.changeSpeed(-1);
        }

        // handle movement with boundary checking
        const movement = input.getMovementVector();
        const new_x = self.position.x + movement.x * constants.DUCK_SPEED;
        const new_y = self.position.y + movement.y * constants.DUCK_SPEED;

        // boundary checking
        const max_x = @as(f32, @floatFromInt(constants.SCREEN_WIDTH)) - self.animation.frame_width * constants.SPRITE_SCALE;
        const max_y = @as(f32, @floatFromInt(constants.SCREEN_HEIGHT)) - self.animation.frame_height * constants.SPRITE_SCALE;

        if (new_x >= 0 and new_x <= max_x) {
            self.position.x = new_x;
        }

        if (new_y >= 0 and new_y <= max_y) {
            self.position.y = new_y;
        }

        // update animation
        self.animation.update();
    }

    pub fn draw(self: *Duck) void {
        self.animation.draw(self.position, constants.SPRITE_SCALE);
    }

    pub fn drawReference(self: *Duck) void {
        // TODO: move reference position to constants
        const reference_position = rl.Vector2{ .x = 15, .y = 40 };
        self.animation.drawReference(reference_position, constants.REFERENCE_SCALE);
    }

    pub fn getCurrentFrame(self: *Duck) i32 {
        return self.animation.current_frame + 1;
    }

    pub fn getCurrentSpeed(self: *Duck) i32 {
        return self.animation.frame_speed;
    }
};

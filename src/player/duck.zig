const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const Animation = @import("../graphics/animation.zig").Animation;
const InputModule = @import("input.zig");
const Input = InputModule.Input;
const MovementVector = Input.MovementVector;
const constants = @import("../utils/constants.zig");
const Tilemap = @import("../world/tilemap.zig").Tilemap;

pub const Duck = struct {
    position: rl.Vector2,
    animation: Animation,
    is_moving: bool,
    facing_left: bool,

    pub fn init(texture: rl.Texture2D) Duck {
        return Duck{
            .position = rl.Vector2{ .x = 350.0, .y = 280.0 },
            .animation = Animation.init(texture, constants.DUCK_IDLE_FRAMES, constants.DUCK_WALK_FRAMES, constants.DUCK_ROWS),
            .is_moving = false,
            .facing_left = false,
        };
    }

    pub fn update(self: *Duck, input: Input, tilemap: *const Tilemap) void {
        // handle animation speed
        if (input.speed_up) {
            self.animation.changeSpeed(1);
        } else if (input.speed_down) {
            self.animation.changeSpeed(-1);
        }

        // check if duck is trying to move
        const movement = input.getMovementVector();
        const was_moving = self.is_moving;
        self.is_moving = input.hasMovement();

        // update facing direction based on horizontal movement?
        if (movement.x < 0) {
            self.facing_left = true;        // moving left
        } else if (movement.x > 0) {
            self.facing_left = false;       // moving right
        }
        // in case of only vertical moving keep current facing direction


        // switch animation based on movement state
        if (self.is_moving) {
            self.animation.setRow(constants.WALK_ROW);
        } else {
            self.animation.setRow(constants.IDLE_ROW);
        }

        // handle movement with boundary checking (if duck is moving)
        if (self.is_moving) {
            // Get current tile friction
            const current_friction = self.getCurrentTileFriction(tilemap);

            // Apply friction to movement speed
            const effective_speed = constants.DUCK_SPEED * current_friction;

            const new_x = self.position.x + movement.x * effective_speed;
            const new_y = self.position.y + movement.y * effective_speed;

            // get duck dimensions
            const duck_width = self.animation.frame_width * constants.SPRITE_SCALE;
            const duck_height = self.animation.frame_height * constants.SPRITE_SCALE;

            // screen boundary checking
            const max_x = @as(f32, @floatFromInt(constants.SCREEN_WIDTH)) - duck_width;
            const max_y = @as(f32, @floatFromInt(constants.SCREEN_HEIGHT)) - duck_height;

            // check x movement
            if (new_x >= 0 and new_x <= max_x) {
                // check collision with tilemap for x movement
                if (!self.checkCollision(new_x, self.position.y, duck_width, duck_height, tilemap)) {
                    self.position.x = new_x;
                }
            }

            // check y movement
            if (new_y >= 0 and new_y <= max_y) {
                if (!self.checkCollision(self.position.x, new_y, duck_width, duck_height, tilemap)) {
                    self.position.y = new_y;
                }
            }
        }

        // reset frame when switching between idle and walking for smooths transitions (nice)
        if (was_moving != self.is_moving) {
            self.animation.resetFrame();
        }

        // update animation
        self.animation.update();
    }

    fn checkCollision(_: *Duck, x: f32, y: f32, width: f32, height: f32, tilemap: *const Tilemap) bool {
        // check the four corners of the duck
        // corners is an array of arrays, where each inner array has a size of 2([2]f32)
        const corners = [_][2]f32{
            .{ x, y },                 // top left
            .{ x + width, y },         // top right
            .{ x, y + height },        // bottom left
            .{ x + width, y + width }  // bottom right
        };

        for (corners) |corner| {
            if (tilemap.is_solid_at_world_pos(corner[0], corner[1])) {
                return true; // detected collision
            }
        }

        return false; // no collision
    }

    pub fn draw(self: *Duck) void {
        self.animation.draw(self.position, constants.SPRITE_SCALE, self.facing_left);
    }

    pub fn drawReference(self: *Duck) void {
        // TODO: move reference position to constants
        const reference_position = rl.Vector2{ .x = 15, .y = 40 };
        self.animation.drawReference(reference_position, constants.REFERENCE_SCALE);
    }

    pub fn getCurrentFrame(self: *Duck) i32 {
        return self.animation.current_frame + 1;
    }

    pub fn getFrameSpeed(self: *Duck) i32 {
        return self.animation.frame_speed;
    }

    fn getCurrentTileFriction(self: *Duck, tilemap: *const Tilemap) f32 {
        // get duck center position
        const duck_width = self.animation.frame_width * constants.SPRITE_SCALE;
        const duck_height = self.animation.frame_height * constants.SPRITE_SCALE;
        const center_x = self.position.x + duck_width / 2.0;
        const center_y = self.position.y + duck_height / 2.0;

        // get the tile at the center position
        if (tilemap.get_tile_at_world_pos(center_x, center_y)) |tile| {
            return tile.friction;
        }
        // else return default
        return 1.0;
    }
};

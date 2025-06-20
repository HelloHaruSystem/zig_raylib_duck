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
            .position = rl.Vector2{
                .x = @as(f32, @floatFromInt(constants.TILE_SIZE * 1)),
                .y = @as(f32, @floatFromInt(constants.TILE_SIZE * 1)),
            },
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

            // NOTE Deprecated
            // Only check collision with tilemap - no rectangular boundaries!
            // The tilemap collision system handles all the complex shapes automatically
            // screen boundary checking
            // const max_x = @as(f32, @floatFromInt(tilemap.width * tilemap.tile_size)) - duck_width;
            // const max_y = @as(f32, @floatFromInt(tilemap.height * tilemap.tile_size)) - duck_height;

            // check x movement
            if (!self.checkCollision(new_x, self.position.y, duck_width, duck_height, tilemap)) {
                self.position.x = new_x;
            }

            // check y movement
            if (!self.checkCollision(self.position.x, new_y, duck_width, duck_height, tilemap)) {
                self.position.y = new_y;
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
        // add a small margin to make collision be ore forgiving

        // shrink the collision box by margin on all sides
        const collision_x = x + constants.COLLISION_MARGIN;
        const collision_y = y + constants.COLLISION_MARGIN;
        const collision_width = width - (constants.COLLISION_MARGIN * 2.0);        
        const collision_height = height - (constants.COLLISION_MARGIN * 2.0);         

        // check and make sure we don't have negative dimensions
        if (collision_width <= 0 or collision_height <= 0) {
            return false; // if margin is too big, just movement no collision
        }       
        
        // check the four corners of the duck
        // corners is an array of arrays, where each inner array has a size of 2([2]f32)
        const corners = [_][2]f32{
            .{ collision_x, collision_y },                 // top left
            .{ collision_x + collision_width, collision_y },         // top right
            .{ collision_x, collision_y + collision_height },        // bottom left
            .{ collision_x + collision_width, collision_y + collision_height }  // bottom right
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

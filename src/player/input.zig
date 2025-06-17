const rl = @cImport({
    @cInclude("raylib.h");
});

pub const Input = struct {
    move_up: bool,
    move_down: bool,
    move_left: bool,
    move_right: bool,
    speed_up: bool,
    speed_down: bool,

    pub fn update() Input {
        return Input{
            .move_up = rl.IsKeyPressed(rl.KEY_W),
            .move_down = rl.IsKeyPressed(rl.Key_S),
            .move_left = rl.IsKeyPressed(rl.KEY_A),
            .move_right = rl.IsKeyPressed(rl.KEY_D),
            .speed_up = rl.IsKeyPressed(rl.KEY_RIGHT),
            .speed_down = rl.IsKeyPressed(rl.KEY_LEFT),
        };
    }

    pub fn hasMovement(self: Input) bool {
        return self.move_up or self.move_down or self.move_left or self.move_right;
    }

    pub fn getMovementVector(self: Input) struct { x: f32, y: f32 } {
        var movement = struct { x: f32, y: f32 }{ .x = 0.0, .y = 0.0 };

        if (self.move_up) movement.y -= 1.0;
        if (self.move_down) movement.y += 1.0;
        if (self.move_left) movement.x -= 1.0;
        if (self.move_right) movement.x += 1.0;

        return movement;
    }
};

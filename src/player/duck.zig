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
};

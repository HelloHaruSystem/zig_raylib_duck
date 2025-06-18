const std = @import("std");

pub const tile_kind = enum {
    grass,
    solid,
    water,
    // add more in the future (example one_way, slope and so on)
};

pub const Tile = struct {
    kind: tile_kind,
    sprite: u16,
    friction: f32 = 1.0,

    // optionals
    on_touch: ?*fn () void = null,
    on_step: ?*fn () void = null,
};

pub const tile_def = [_]Tile{
    .{ .kind = .grass, .sprite = 0, },
    .{ .kind = .solid, .sprite = 1, },
    .{ .kind = .water, .sprite = 2, .friction = 0.5 } 
    // add more in the future as tile_kinds increase
};

fn water_splash() void {
    // splash
    std.debug.print("🌊 Splash function has been called 🌊", .{});
}

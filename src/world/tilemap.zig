const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const constants = @import("../utils/constants.zig");
const tile_module = @import("../utils/tiles.zig");
const Tile = tile_module.Tile;
const tile_def = tile_module.tile_def;
const tile_kind = tile_module.tile_kind;

pub const Tilemap = struct {
    width: u32,
    height: u32,
    tile_size: u32,
    tiles: []u8,
    allocator: std.mem.Allocator,

    // init for procedural generation incase of fallback needed when error loading map data
    pub fn init(allocator: std.mem.Allocator, width: u32, height: u32, tile_size: u32) !Tilemap {
        const tile_count = width * height;
        const tiles = try allocator.alloc(u8, tile_count);
        
        // Test pattern for testing!
        //TODO: move to assets
        for (0..height) |row| {
            for (0..width) |column| {
                const index = row * width + column;

                // create the test pattern
                if (row == 0 or row == height - 1 or column == 0 or column == width - 1) {
                    tiles[index] = 1; // solid border
                } else if ((row + column) % 7 == 0) {
                    tiles[index] = 2; // water
                } else {
                    tiles[index] = 0; // grass
                }
            }
        }

        return Tilemap{
            .width = width,
            .height = height,
            .tile_size = tile_size,
            .tiles = tiles,
            .allocator = allocator,
        };
    }

    pub fn initFromData(allocator: std.mem.Allocator, width: u32, height: u32, tile_size: u32, tile_data: []const u8) !Tilemap {
        if (tile_data.len != width * height) {
            return error.InvalidTileData;
        }

        const tiles = try allocator.dupe(u8, tile_data);

        return Tilemap{
            .width = width,
            .height = height,
            .tile_size = tile_size,
            .tiles = tiles,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Tilemap) void {
        self.allocator.free(self.tiles);
    }

    pub fn get_tile(self: *const Tilemap, x: u32, y: u32) ?Tile {
        if (x >= self.width or y >= self.height) return null;

        const index = y * self.width + x;
        const tile_def_index = self.tiles[index];

        if (tile_def_index >= tile_def.len) return null;
        return tile_def[tile_def_index];
    }

    pub fn get_tile_at_world_pos(self: *const Tilemap, world_x: f32, world_y: f32) ?Tile {
        const tile_x = @as(u32, @intFromFloat(world_x / @as(f32, @floatFromInt(self.tile_size))));
        const tile_y = @as(u32, @intFromFloat(world_y / @as(f32, @floatFromInt(self.tile_size))));
        return self.get_tile(tile_x, tile_y);
    }

    pub fn is_solid(self: *const Tilemap, x: u32, y: u32) bool {
        const tile = self.get_tile(x, y);
        if (tile) |t| {
            return t.solid;
        }
        return false;
    }

    pub fn is_solid_at_world_pos(self: *const Tilemap, world_x: f32, world_y: f32) bool {
        const tile_x = @as(u32, @intFromFloat(world_x / @as(f32, @floatFromInt(self.tile_size))));
        const tile_y = @as(u32, @intFromFloat(world_y / @as(f32, @floatFromInt(self.tile_size))));
        return self.is_solid(tile_x, tile_y);
    }

    pub fn draw(self: *const Tilemap) void {
        for (0..self.height) |row| {
            for (0..self.width) |column| {
                const index = row * self.width + column;
                const tile_def_index = self.tiles[index];

                if (tile_def_index >= tile_def.len) continue;

                const tile = tile_def[tile_def_index];
                const x = @as(f32, @floatFromInt(column * self.tile_size));
                const y = @as(f32, @floatFromInt(row * self.tile_size));

                // simple colored rectangles for different tile styles
                // use proper sprites in the future
                const color = switch (tile.kind) {
                    tile_kind.grass => rl.GREEN,
                    tile_kind.wall => rl.BROWN,
                    tile_kind.water => rl.BLUE,
                };

                rl.DrawRectangle(
                    @as(i32, @intFromFloat(x)),
                    @as(i32, @intFromFloat(y)),
                    @as(i32, @intFromFloat(@as(f32, @floatFromInt(self.tile_size)))),
                    @as(i32, @intFromFloat(@as(f32, @floatFromInt(self.tile_size)))),
                    color,
                );

                // Draw tile border for visibility
                // TODO: remove in the future
                rl.DrawRectangleLines(
                    @as(i32, @intFromFloat(x)),
                    @as(i32, @intFromFloat(y)),
                    @as(i32, @intFromFloat(@as(f32, @floatFromInt(self.tile_size)))),
                    @as(i32, @intFromFloat(@as(f32, @floatFromInt(self.tile_size)))),
                    rl.DARKGRAY,
                );
            }
        }
    }
};
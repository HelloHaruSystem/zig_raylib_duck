const std = @import("std");
const Tilemap = @import("../world/tilemap.zig").Tilemap;
const paths = @import("paths.zig");

// error set
pub const MapLoadError = error{
    FileNotFound,
    InvalidFormat,
    InvalidDimensions,
    InvalidTileData,
};

pub const MapData = struct{
    width: u32,
    height: u32,
    tiles: []u8,
    spawn_x: u32,
    spawn_y: u32,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *MapData) void {
        self.allocator.free(self.tiles);
    }
};

pub const MapLoader = struct {
    // load by map name not extension (.map)
    pub fn loadMapByName(allocator: std.mem.Allocator, map_name: []const u8) !MapData {
        const map_path = try paths.getMapFile(allocator, map_name);
        defer allocator.free(map_path);

        return loadFromFile(allocator, map_path);
    }

    // load specific level (level1)
    pub fn loadLevel(allocator: std.mem.Allocator, level_number: u32) !MapData {
        const level_name = try std.fmt.allocPrint(allocator, "level{}", .{level_number});
        defer allocator.free(level_name);

        return loadMapByName(allocator, level_name);
    }

    pub fn loadFromFile(allocator: std.mem.Allocator, file_path: []const u8) !MapData {
        const file = std.fs.cwd().openFile(file_path, .{}) catch |err| switch (err) {
            error.FileNotFound => return MapLoadError.FileNotFound,
            else => return err,
        };
        defer file.close();

        const file_size = try file.getEndPos();
        const contents = try allocator.alloc(u8, file_size);
        defer allocator.free(contents);

        _ = try file.readAll(contents);

        return parseMapData(allocator, contents);
    }

    fn parseMapData(allocator: std.mem.Allocator, contents: []const u8) !MapData {
        var width: u32 = 0;
        var height: u32 = 0;
        var spawn_x: u32 = 0;
        var spawn_y: u32 = 0;
        var parsing_data = false;
        var tiles = std.ArrayList(u8).init(allocator);
        defer tiles.deinit();

        var lines = std.mem.splitSequence(u8, contents, "\n");
        while (lines.next()) |line| {
            const trimmed = std.mem.trim(u8, line, " \t\r\n");

            // skip empty lines and comments
            if (trimmed.len == 0 or trimmed[0] == '#') continue;

            if (std.mem.startsWith(u8, trimmed, "WIDTH=")) {
                const width_str = trimmed[6..];
                // if the format is wrong be sure to return InvalidFormat error for simpler debugging
                width = std.fmt.parseInt(u32, width_str, 10) catch return MapLoadError.InvalidFormat;
            } 
            else if (std.mem.startsWith(u8, trimmed, "HEIGHT=")) {
                const height_str = trimmed[7..];
                height = std.fmt.parseInt(u32, height_str, 10) catch return MapLoadError.InvalidFormat;
            } 
            else if (std.mem.startsWith(u8, trimmed, "SPAWN_X=")) {
                const spawn_x_str = trimmed[8..];
                spawn_x = std.fmt.parseInt(u32, spawn_x_str, 10) catch return MapLoadError.InvalidFormat;
            }
            else if (std.mem.startsWith(u8, trimmed, "SPAWN_Y=")) {
                const spawn_y_str = trimmed[8..];
                spawn_y = std.fmt.parseInt(u32, spawn_y_str, 10) catch return MapLoadError.InvalidFormat;
            }
            else if (std.mem.eql(u8, trimmed, "DATA=")) {
                parsing_data = true;
            } 
            else if (parsing_data) {
                // now we parse the tile data row
                // be sure to return proper errors
                if (trimmed.len != width) return MapLoadError.InvalidTileData;

                for (trimmed) |char| {
                    const tile_id: u8 = switch (char) {
                        '0' => 0, // grass
                        '1' => 1, // wall
                        '2' => 2, // water
                        else => return MapLoadError.InvalidTileData,
                    };
                    try tiles.append(tile_id);
                }
            }
        }

        if (tiles.items.len != width * height) {
            return MapLoadError.InvalidTileData;
        }

        return MapData{
            .width = width,
            .height = height,
            .spawn_x = spawn_x,
            .spawn_y = spawn_y,
            .tiles = try tiles.toOwnedSlice(),
            .allocator = allocator,
        };
    }
    
    pub fn createTileMapFromData(allocator: std.mem.Allocator, map_data: MapData, tile_size: u32) !Tilemap {
        const tilemap = Tilemap{
            .width = map_data.width,
            .height = map_data.height,
            .tile_size = tile_size,
            .tiles = try allocator.dupe(u8, map_data.tiles),
            .allocator = allocator,
        };

        return tilemap;
    }
};
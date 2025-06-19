const std = @import("std");
const builtin = @import("builtin");

pub fn getAssetPath(allocator: std.mem.Allocator, relative_path: []const u8) ![]u8 {
    const separator = if (builtin.os.tag == .windows) "\\" else "/";
    return std.fmt.allocPrint(allocator, "assets{s}{s}", .{ separator, relative_path });
}

pub fn getSpriteSheet(allocator: std.mem.Allocator, filename: []const u8) ![]u8 {
    const separator = if (builtin.os.tag == .windows) "\\" else "/";
    return std.fmt.allocPrint(allocator, "assets{s}sprites{s}{s}", .{ separator, separator, filename });
}

pub fn getMapPath(allocator: std.mem.Allocator, filename: []const u8) ![]u8 {
    const separator = if (builtin.os.tag == .windows) "\\" else "/";
    return std.fmt.allocPrint(allocator, "assets{s}maps{s}{s}", .{ separator, separator, filename });
}

pub fn getMapFile(allocator: std.mem.Allocator, map_name: []const u8) ![]u8 {
    const filename = try std.fmt.allocPrint(allocator, "{s}.map", .{map_name});
    defer allocator.free(filename);
    return getMapPath(allocator, filename);
}

// for current duck sprite
pub fn getDuckSpritePath(allocator: std.mem.Allocator) ![]u8 {
    return getSpriteSheet(allocator, "ducky_3_spritesheet.png");
}

// common map path's
pub fn get_level_1_path(allocator: std.mem.Allocator) ![]u8 {
    return getMapFile(allocator, "level1");
}

pub fn get_test_map_path(allocator: std.mem.Allocator) ![]u8 {
    return getMapFile(allocator, "test");
}
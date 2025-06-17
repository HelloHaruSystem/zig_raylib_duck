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

// for current duck sprite
pub fn getDuckSpritePath(allocator: std.mem.Allocator) ![]u8 {
    return getSpriteSheet(allocator, "ducky_3_spritesheet.png");
}

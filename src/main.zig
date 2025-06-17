const std = @import("std");
const Game = @import("game.zig").Game;

pub fn main() !void {
    // setup allocator
    const gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // initialize the game then run!
    var game = Game.init(allocator) catch |err| {
        std.debug.print("Failed to initialize game: {}\n", .{err});
        return;
    };
    defer game.deinit();

    std.debug.print("Starting Duck Game! 🦆\n", .{});
    game.run();
    std.debug.print("Game endedn. Thanks for playing! Quack 🦆\n", .{});
}

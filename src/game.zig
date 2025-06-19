const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const Duck = @import("player/duck.zig").Duck;
const Input = @import("player/input.zig").Input;
const TileMap = @import("world/tilemap.zig").Tilemap;
const MapLoader = @import("utils/map_loader.zig").MapLoader;
const constants = @import("utils/constants.zig");
const paths = @import("utils/paths.zig");

pub const Game = struct {
    duck: Duck,
    duck_texture: rl.Texture2D,
    tilemap: TileMap,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !Game {
        // Initialize window
        rl.InitWindow(constants.SCREEN_WIDTH, constants.SCREEN_HEIGHT, "🦆 Walking Duck 🦆");
        rl.SetTargetFPS(60);

        // load duck texture with cross-platform path!
        const duck_path = try paths.getDuckSpritePath(allocator);
        defer allocator.free(duck_path);

        const duck_texture = rl.LoadTexture(@ptrCast(duck_path));

        // check if texture is loaded correctly
        if (duck_texture.id == 0) {
            std.debug.print("ERROR: Failed to load duck sprite at path: {s}\n", .{duck_path});
            return error.TextureLoadFailed;
        }

        std.debug.print("Duck texture loaded successfully! Size: {}x{}\n", .{ duck_texture.width, duck_texture.height });

        // try to load tilemap from file, fallback to default genned
        const tilemap = loadTilemap(allocator) catch |err| blk: {
            std.debug.print("Failed to load map file ({}), using default map", .{err});
            break :blk try TileMap.init(allocator, constants.VISIBLE_TILES_WIDTH, constants.VISIBLE_TILES_HEIGHT, constants.TILE_SIZE);
        };

        return Game{
            .duck = Duck.init(duck_texture),
            .duck_texture = duck_texture,
            .tilemap = tilemap,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Game) void {
        self.tilemap.deinit();
        rl.UnloadTexture(self.duck_texture);
        rl.CloseWindow();
    }

    pub fn run(self: *Game) void {
        while (!rl.WindowShouldClose()) {
            self.update();
            self.draw();
        }
    }

    fn update(self: *Game) void {
        const input = Input.update();
        self.duck.update(input, &self.tilemap);
    }

    fn draw(self: *Game) void {
        rl.BeginDrawing();
        defer rl.EndDrawing();

        rl.ClearBackground(rl.SKYBLUE);

        // draw tilemap first (background)
        self.tilemap.draw();

        // draw the reference sprite sheet
        self.duck.drawReference();

        // draw the animated duck
        self.duck.draw();

        //draw UI
        self.drawUI();
    }

    fn drawUI(self: *Game) void {
        const current_frame = self.duck.getCurrentFrame();
        const frame_speed = self.duck.getFrameSpeed();

        rl.DrawText("Duck Animation (Idle: 4 frames, Walk: 6 frames) - WASD Control", 10, 10, 20, rl.DARKGRAY);
        rl.DrawText(rl.TextFormat("Frame Speed: %i fps (Current: %i)", frame_speed, current_frame), 10, constants.SCREEN_HEIGHT - 80, 10, rl.DARKGRAY);
        rl.DrawText("Use LEFT/RIGHT arrows to change animation speed", 10, constants.SCREEN_HEIGHT - 60, 10, rl.DARKGRAY);
        rl.DrawText("Use WASD to move duck", 10, constants.SCREEN_HEIGHT - 40, 10, rl.DARKGRAY);
        rl.DrawText("Green=Grass, Brown=Solid, Blue=Water", 10, constants.SCREEN_HEIGHT - 20, 10, rl.DARKGRAY);
    }

    fn loadTilemap(allocator: std.mem.Allocator) !TileMap {
        
        if (loadSpecificMap(allocator, "test")) |tilemap| {
            std.debug.print("Loaded test map\n", .{});
            return tilemap;
        } else |err| {
            std.debug.print("Failed to load test.map: {}\n", .{err});
        }
        
        // Fallback to procedural generation
        std.debug.print("Using procedural generation as final fallback\n", .{});
        return error.NoMapFound;
    }

    fn loadSpecificMap(allocator: std.mem.Allocator, map_name: []const u8) !TileMap {
        var map_data = try MapLoader.loadMapByName(allocator, map_name);
        defer map_data.deinit();

        std.debug.print("Map '{s}' loaded successfully. Size: {}x{}\n", .{map_name, map_data.width, map_data.height});

        return TileMap.initFromData(allocator, map_data.width, map_data.height, constants.TILE_SIZE, map_data.tiles);
    }
};

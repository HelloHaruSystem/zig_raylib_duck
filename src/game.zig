const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const Duck = @import("player/duck.zig").Duck;
const Input = @import("player/input.zig").Input;
const TileMap = @import("world/tilemap.zig").Tilemap;
const Camera = @import("world/camera.zig").Camera;
const MapLoader = @import("utils/map_loader.zig").MapLoader;
const constants = @import("utils/constants.zig");
const paths = @import("utils/paths.zig");

pub const Game = struct {
    duck: Duck,
    duck_texture: rl.Texture2D,
    tilemap: TileMap,
    camera: Camera,
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

        // spawn points starts at default (1, 1)
        // but will be passed in with the loadTileMap function to get that maps spawn points
        var spawn_x: f32 = @as(f32, @floatFromInt(1 * constants.TILE_SIZE));
        var spawn_y: f32 = @as(f32, @floatFromInt(1 * constants.TILE_SIZE));

        // try to load tilemap from file, fallback to default genned
        const tilemap = loadTilemap(allocator, &spawn_x, &spawn_y) catch |err| blk: {
            std.debug.print("Failed to load map file ({}), using default map", .{err});
            break :blk try TileMap.init(allocator, constants.VISIBLE_TILES_WIDTH, constants.VISIBLE_TILES_HEIGHT, constants.TILE_SIZE);
        };

        // init camera
        const camera_2d: Camera = Camera.init();

        // create duck with spawn positions from the map files (or default)
        var duck = Duck.init(duck_texture);
        duck.position.x = spawn_x;
        duck.position.y = spawn_y;

        return Game{
            .duck = duck,
            .duck_texture = duck_texture,
            .tilemap = tilemap,
            .camera = camera_2d,
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
        self.camera.update(self.duck.position.x, self.duck.position.y);
    }

    fn draw(self: *Game) void {
        rl.BeginDrawing();
        defer rl.EndDrawing();

        rl.ClearBackground(rl.SKYBLUE);

        // begin camera then draw world objects (these will be affected by camera)
        rl.BeginMode2D(self.camera.camera);

        // draw tilemap first (background)
        self.tilemap.draw();

        // draw the animated duck
        self.duck.draw();

        // then end camera UI elements should go after
        rl.EndMode2D();

        // draw the reference sprite sheet
        self.duck.drawReference();

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

    fn loadTilemap(allocator: std.mem.Allocator, spawn_x: *f32, spawn_y: *f32) !TileMap {
        if (loadSpecificMap(allocator, "test2", spawn_x, spawn_y)) |tilemap| {
            std.debug.print("Loaded test map\n", .{});
            return tilemap;
        } else |err| {
            std.debug.print("Failed to load test.map: {}\n", .{err});
        }
        
        // Fallback to procedural generation
        std.debug.print("Using procedural generation as final fallback\n", .{});
        return error.NoMapFound;
    }

    fn loadSpecificMap(allocator: std.mem.Allocator, map_name: []const u8, spawn_x: *f32, spawn_y: *f32) !TileMap {
        var map_data = try MapLoader.loadMapByName(allocator, map_name);
        defer map_data.deinit();

        std.debug.print("Map '{s}' loaded successfully. Size: {}x{}, Spawn: ({}, {})\n", .{map_name, map_data.width, map_data.height, map_data.spawn_x, map_data.spawn_y});
        
        // convert tile coordinates to world coordinates
        spawn_x.* = @as(f32, @floatFromInt(map_data.spawn_x * constants.TILE_SIZE));
        spawn_y.* = @as(f32, @floatFromInt(map_data.spawn_y * constants.TILE_SIZE));

        return TileMap.initFromData(allocator, map_data.width, map_data.height, constants.TILE_SIZE, map_data.tiles);
    }
};

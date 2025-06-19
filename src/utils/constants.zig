const std = @import("std");

// animation constants
pub const MAX_FRAME_SPEED = 15;
pub const MIN_FRAME_SPEED = 1;
pub const DEFAULT_FRAME_SPEED = 8;

// duck sprite animation constants
pub const DUCK_ROWS = 4;            // 4 rows in the sheet
pub const DUCK_IDLE_FRAMES = 4;     // frames per animation
pub const DUCK_WALK_FRAMES = 6;     //  frames per animation
pub const IDLE_ROW = 2;             // third row (0-indexed)
pub const WALK_ROW = 1;             // second row (0-indexed)
// scaling constants
pub const SPRITE_SCALE: f32 = 1.5;

// tile constants
pub const BASE_TILE_SIZE: f32 = 32;
pub const TILE_SIZE: u32 = @as(u32, @intFromFloat(BASE_TILE_SIZE * SPRITE_SCALE)); 

// Visible tiles
// TODO: change when camera is added!
pub const VISIBLE_TILES_WIDTH = @divTrunc(SCREEN_WIDTH, TILE_SIZE);   // 16 tiles
pub const VISIBLE_TILES_HEIGHT = @divTrunc(SCREEN_HEIGHT, TILE_SIZE); // 9 tiles

// screen constants
pub const SCREEN_WIDTH = 800;
pub const SCREEN_HEIGHT = 450;

// movement constants
pub const DUCK_SPEED: f32 = 3;                  // if sprite_scale is equal to 3 set it to 3.0 (REDUCED PROPORTIONALLY (3.0 * 1.5/2.0) == 2.25)

// display constants
pub const REFERENCE_SCALE: f32 = 0.5;

// tilemap constants
pub const TILEMAP_WIDTH = @divTrunc(SCREEN_WIDTH, TILE_SIZE);
pub const TILEMAP_HEIGHT = @divTrunc(SCREEN_HEIGHT, TILE_SIZE);

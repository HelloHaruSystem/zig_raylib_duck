const std = @import("std");

// animation constants
pub const MAX_FRAME_SPEED = 15;
pub const MIN_FRAME_SPEED = 1;
pub const DEFAULT_FRAME_SPEED = 8;

// duck sprite animation constants
pub const DUCK_FRAMES = 6; // 4 frames per animation
pub const DUCK_ROWS = 4; // 4 rows in the sheet
pub const WALK_ROW = 1; // second row (0-indexed)
// duck scale
pub const SPRITE_SCALE: f32 = 2.0;

// screen constants
pub const SCREEN_WIDTH = 800;
pub const SCREEN_HEIGHT = 450;

// movement constants
pub const DUCK_SPEED: f32 = 3.0;

// display constants
pub const REFERENCE_SCALE: f32 = 0.5;

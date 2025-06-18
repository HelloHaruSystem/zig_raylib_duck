# Duck Game Documentation 🦆

A 2D animated duck game built with Zig and Raylib featuring sprite animation, tilemap collision detection, and smooth movement controls.

## Table of Contents
- [Overview](#overview)
- [Project Structure](#project-structure)
- [Core Systems](#core-systems)
- [File-by-File Analysis](#file-by-file-analysis)
- [Game Flow](#game-flow)
- [Building and Running](#building-and-running)
- [Technical Details](#technical-details)

## Overview

This is a 2D tile-based game where players control an animated duck that can walk around a world with different tile types. The game features:

- **Sprite Animation**: Duck has idle and walking animations with adjustable speed
- **Tilemap System**: Grid-based world with different tile types (grass, walls, water)
- **Collision Detection**: Duck cannot walk through solid tiles
- **Smooth Movement**: WASD controls with boundary checking
- **Cross-Platform**: Builds for Windows, Linux, and macOS

## Project Structure

```
src/
├── main.zig              # Entry point
├── game.zig              # Main game logic and state
├── player/
│   ├── duck.zig          # Duck entity with animation and movement
│   └── input.zig         # Input handling system
├── graphics/
│   └── animation.zig     # Sprite animation system
├── world/
│   └── tilemap.zig       # Tilemap rendering and collision
└── utils/
    ├── constants.zig     # Game constants and configuration
    ├── paths.zig         # Cross-platform asset path handling
    └── tiles.zig         # Tile definitions and properties
```

## Core Systems

### 1. Animation System
- **Frame-based animation** with configurable speeds
- **Multi-row sprite sheets** supporting different animation types
- **Horizontal flipping** for directional sprites
- **Reference display** showing the current frame on the sprite sheet

### 2. Input System
- **WASD movement** with vector-based input
- **Speed controls** using arrow keys
- **Movement state detection** for animation switching

### 3. Tilemap System
- **Grid-based world** with 32x32 pixel tiles
- **Tile properties** including solidity and friction
- **World-to-tile coordinate conversion**
- **Collision detection** at tile boundaries

### 4. Entity System
- **Duck entity** with position, animation, and movement state
- **Collision checking** using bounding box detection
- **Boundary constraints** keeping duck within screen bounds

## File-by-File Analysis

### main.zig
**Purpose**: Application entry point and memory management

```zig
pub fn main() !void {
    // Setup allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Initialize and run game
    var game = Game.init(allocator) catch |err| {
        std.debug.print("Failed to initialize game: {}\n", .{err});
        return;
    };
    defer game.deinit();

    game.run();
}
```

**Key Features**:
- Uses `GeneralPurposeAllocator` for memory management
- Proper error handling with detailed error messages
- Ensures cleanup with `defer` statements
- Simple, clean entry point

### game.zig
**Purpose**: Main game state management and rendering coordination

**Key Components**:
- **Game struct**: Holds all game state (duck, tilemap, textures)
- **Initialization**: Sets up window, loads textures, creates tilemap
- **Game loop**: Handles update/draw cycle
- **UI rendering**: Displays game information and controls

**Critical Functions**:
```zig
pub fn init(allocator: std.mem.Allocator) !Game {
    // Window setup
    rl.InitWindow(constants.SCREEN_WIDTH, constants.SCREEN_HEIGHT, "🦆 Walking Duck 🦆");
    rl.SetTargetFPS(60);
    
    // Texture loading with error checking
    const duck_texture = rl.LoadTexture(@ptrCast(duck_path));
    if (duck_texture.id == 0) {
        return error.TextureLoadFailed;
    }
}
```

**Rendering Order**:
1. Clear background to sky blue
2. Draw tilemap (background layer)
3. Draw reference sprite sheet
4. Draw animated duck
5. Draw UI overlay

### player/duck.zig
**Purpose**: Duck entity with animation, movement, and collision

**Key Features**:
- **Position tracking**: 2D coordinates for duck location
- **Animation state**: Current animation row (idle/walk) and facing direction
- **Movement processing**: Handles input and applies movement with collision checking
- **Boundary checking**: Prevents duck from leaving screen bounds

**Collision Detection**:
```zig
fn checkCollision(_: *Duck, x: f32, y: f32, width: f32, height: f32, tilemap: *const Tilemap) bool {
    const corners = [_][2]f32{
        .{ x, y },                 // top left
        .{ x + width, y },         // top right
        .{ x, y + height },        // bottom left
        .{ x + width, y + width }  // bottom right (Note: should be y + height)
    };

    for (corners) |corner| {
        if (tilemap.is_solid_at_world_pos(corner[0], corner[1])) {
            return true;
        }
    }
    return false;
}
```

**Movement Logic**:
1. Check for speed adjustment input
2. Get movement vector from input
3. Update facing direction based on horizontal movement
4. Switch animation based on movement state
5. Apply movement with collision and boundary checking
6. Update animation frame

### player/input.zig
**Purpose**: Input handling and movement vector calculation

**Input Mapping**:
- `W/A/S/D`: Movement controls
- `LEFT/RIGHT arrows`: Animation speed adjustment

**Key Functions**:
```zig
pub fn getMovementVector(self: Input) MovementVector {
    var movement = MovementVector{ .x = 0.0, .y = 0.0 };
    
    if (self.move_up) movement.y -= 1.0;
    if (self.move_down) movement.y += 1.0;
    if (self.move_left) movement.x -= 1.0;
    if (self.move_right) movement.x += 1.0;
    
    return movement;
}
```

**Features**:
- **Digital input**: Simple on/off key states
- **Vector-based movement**: Allows diagonal movement
- **Separate speed controls**: Frame speed independent of movement

### graphics/animation.zig
**Purpose**: Sprite sheet animation system

**Animation Features**:
- **Multi-row sprite sheets**: Different animations on different rows
- **Variable frame counts**: Idle (4 frames) vs Walk (6 frames)
- **Adjustable speed**: 1-15 FPS animation speed
- **Horizontal flipping**: For directional sprites

**Frame Calculation**:
```zig
pub fn getSourceRectangle(self: *Animation) rl.Rectangle {
    return rl.Rectangle{
        .x = @as(f32, @floatFromInt(self.current_frame)) * self.frame_width,
        .y = @as(f32, @floatFromInt(self.current_row)) * self.frame_height,
        .width = self.frame_width,
        .height = self.frame_height,
    };
}
```

**Animation Update**:
1. Increment frame counter
2. Check if enough time has passed (60 / frame_speed)
3. Advance to next frame
4. Loop back to beginning when reaching frame count limit

### world/tilemap.zig
**Purpose**: Grid-based world with collision detection

**Tilemap Features**:
- **Grid-based layout**: 25x14 tiles at 32x32 pixels each
- **Tile indexing**: 1D array representing 2D grid
- **Coordinate conversion**: World position to tile coordinates
- **Test pattern generation**: Creates borders and scattered water tiles

**Coordinate Conversion**:
```zig
pub fn get_tile_at_world_pos(self: *const Tilemap, world_x: f32, world_y: f32) ?Tile {
    const tile_x = @as(u32, @intFromFloat(world_x / @as(f32, @floatFromInt(self.tile_size))));
    const tile_y = @as(u32, @intFromFloat(world_y / @as(f32, @floatFromInt(self.tile_size))));
    return self.get_tile(tile_x, tile_y);
}
```

**Test Pattern**:
- **Border tiles**: Solid walls around the perimeter
- **Water tiles**: Scattered based on `(row + column) % 7 == 0`
- **Grass tiles**: Default for all other spaces

### utils/tiles.zig
**Purpose**: Tile type definitions and properties

**Tile Properties**:
```zig
pub const Tile = struct {
    kind: tile_kind,
    sprite: u16,
    friction: f32 = 1.0,
    solid: bool = false,
    
    // Optional callbacks
    on_touch: ?*fn () void = null,
    on_step: ?*fn () void = null,
};
```

**Tile Definitions**:
- **Grass**: Basic walkable tile (sprite 0)
- **Wall**: Solid blocking tile (sprite 1)
- **Water**: Reduced friction tile (sprite 2, friction 0.5)

### utils/constants.zig
**Purpose**: Game configuration and constants

**Key Constants**:
```zig
// Screen dimensions
pub const SCREEN_WIDTH = 800;
pub const SCREEN_HEIGHT = 450;

// Animation settings
pub const DUCK_IDLE_FRAMES = 4;
pub const DUCK_WALK_FRAMES = 6;
pub const DEFAULT_FRAME_SPEED = 8;

// Movement and scaling
pub const DUCK_SPEED: f32 = 3.0;
pub const SPRITE_SCALE: f32 = 2.0;
pub const TILE_SIZE = 32;
```

### utils/paths.zig
**Purpose**: Cross-platform asset path handling

**Path Functions**:
- `getAssetPath()`: General asset path construction
- `getSpriteSheet()`: Sprite-specific path construction
- `getDuckSpritePath()`: Hardcoded path for duck sprite

**Cross-Platform Support**:
```zig
const separator = if (builtin.os.tag == .windows) "\\" else "/";
```

## Game Flow

### Initialization Sequence
1. **Memory Setup**: Initialize general purpose allocator
2. **Window Creation**: 800x450 window with 60 FPS target
3. **Asset Loading**: Load duck sprite sheet with error checking
4. **Tilemap Creation**: Generate test tilemap pattern
5. **Duck Initialization**: Create duck entity with loaded texture

### Main Game Loop
```zig
while (!rl.WindowShouldClose()) {
    self.update();  // Process input and update game state
    self.draw();    // Render everything to screen
}
```

### Update Cycle
1. **Input Processing**: Read keyboard state
2. **Duck Update**: Apply movement, handle collisions, update animation
3. **Animation Update**: Advance animation frames based on timing

### Render Cycle
1. **Background**: Clear to sky blue
2. **Tilemap**: Draw colored rectangles for each tile
3. **Reference**: Show sprite sheet with current frame highlighted
4. **Duck**: Draw animated duck at current position
5. **UI**: Display controls and current state information

## Building and Running

### Dependencies
- **Zig 0.14.1+**: Modern Zig compiler
- **Raylib 5.5.0**: Graphics and input library
- **Platform libraries**: OpenGL, windowing system libraries

### Build Commands
```bash
# Default build (current platform)
zig build

# Run directly
zig build run

# Windows cross-compilation
zig build -Dtarget=x86_64-windows

# Run tests
zig build test
```

### Build Configuration
The `build.zig` file handles:
- **Cross-platform compilation** for Windows, Linux, macOS
- **Library linking** for graphics and system libraries
- **Raylib integration** with proper configuration
- **Test setup** with same library dependencies

### Asset Requirements
- **Duck sprite sheet**: `assets/sprites/ducky_3_spritesheet.png`
- **Sprite format**: 4 idle frames, 6 walk frames, arranged in rows
- **File structure**: Must match paths defined in `paths.zig`

## Technical Details

### Memory Management
- **Allocator-based**: Uses Zig's allocator pattern throughout
- **RAII**: Proper cleanup with `defer` statements
- **Error handling**: Explicit error propagation with `!` syntax

### Performance Considerations
- **Fixed timestep**: 60 FPS target with frame-based animation
- **Efficient collision**: Only checks tile boundaries, not full collision
- **Minimal allocations**: Most data structures use stack allocation

### Code Style
- **Zig conventions**: snake_case for functions, PascalCase for types
- **Error handling**: Explicit error types and propagation
- **Memory safety**: No manual memory management in game logic
- **Modularity**: Clear separation of concerns across files

### Potential Improvements
1. **Sprite loading**: Could load multiple sprite sheets
2. **Sound system**: Add audio for footsteps and interactions
3. **Level loading**: Load tilemaps from external files
4. **Particle effects**: Add water splashes or dust clouds
5. **Game states**: Menu system and multiple levels
6. **Better collision**: Implement proper AABB collision with sub-tile precision

This documentation provides a complete overview of the duck game's architecture, systems, and implementation details. The code demonstrates good Zig practices with proper error handling, memory management, and modular design.
# 🦆 Complete Duck Game Architecture Explanation

## 📋 Table of Contents
1. [Project Structure Overview](#project-structure)
2. [Data Flow & Program Execution](#data-flow)
3. [Module Breakdown](#modules)
4. [Memory Management & Pointers](#memory-pointers)
5. [Build System & Cross-Platform](#build-system)
6. [Key Concepts](#key-concepts)

---

## 🏗️ Project Structure Overview {#project-structure}

```
duck_game/
├── src/
│   ├── main.zig           # Entry point - starts everything
│   ├── game.zig           # Game orchestrator - manages everything
│   ├── player/
│   │   ├── duck.zig       # Duck entity - handles duck logic
│   │   └── input.zig      # Input system - captures keyboard
│   ├── graphics/
│   │   └── animation.zig  # Animation system - handles sprite animation
│   └── utils/
│       ├── constants.zig  # Game constants - numbers & settings
│       └── paths.zig      # File paths - cross-platform file loading
└── assets/
    └── sprites/
        └── ducky_3_spritesheet.png
```

**Why this structure?**
- **Separation of Concerns**: Each file has ONE job
- **Modularity**: Easy to modify one part without breaking others
- **Scalability**: Easy to add new features (enemies, sounds, levels)
- **Maintainability**: Easy to find and fix bugs

---

## 🔄 Data Flow & Program Execution {#data-flow}

### **1. Program Startup (main.zig)**
```zig
pub fn main() !void {
    // 1. Create memory allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    
    // 2. Initialize game (creates window, loads assets)
    var game = Game.init(gpa.allocator());
    
    // 3. Run game loop
    game.run();
    
    // 4. Clean up when done
    game.deinit();
}
```

### **2. Game Initialization (game.zig init)**
```zig
pub fn init(allocator: std.mem.Allocator) !Game {
    // 1. Create window (800x450, 60 FPS)
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Duck Game");
    
    // 2. Load duck sprite texture from assets/sprites/
    const duck_texture = rl.LoadTexture(duck_path);
    
    // 3. Create duck entity with loaded texture
    const duck = Duck.init(duck_texture);
    
    // 4. Return complete game object
    return Game{ .duck = duck, .duck_texture = duck_texture };
}
```

### **3. Game Loop (game.zig run)**
```
┌─────────────────────────────────────────┐
│          GAME LOOP (60 FPS)             │
│                                         │
│  ┌─────────────┐    ┌─────────────┐     │
│  │   UPDATE    │    │    DRAW     │     │
│  │             │    │             │     │
│  │ 1. Get input│    │ 1. Clear    │     │
│  │ 2. Move duck│ -> │ 2. Duck     │     │
│  │ 3. Animate  │    │ 3. UI       │     │
│  │             │    │ 4. Present  │     │
│  └─────────────┘    └─────────────┘     │
│         │                  ^            │
│         │__________________|            │
│                                         │
│  Repeat until window closed (ESC/X)     │
└─────────────────────────────────────────┘
```

### **4. Frame-by-Frame Execution**
```
Frame 1:
├── Input.update() -> captures WASD/arrow keys
├── Duck.update(input) -> moves duck position, updates animation
├── Draw background
├── Draw duck at new position
└── Present to screen

Frame 2:
├── Input.update() -> captures new key states
├── Duck.update(input) -> moves duck again, advances animation frame
├── Draw background
├── Draw duck at newer position
└── Present to screen

... (continues at 60 FPS)
```

---

## 🧩 Module Breakdown {#modules}

### **main.zig - The Entry Point**
```zig
// Job: Start the program and manage memory
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};  // Memory manager
    var game = Game.init(gpa.allocator());              // Create game
    game.run();                                         // Run until exit
    game.deinit();                                      // Clean up
}
```
**Responsibilities:**
- Memory allocation setup
- Error handling for game initialization
- Program lifecycle management

### **game.zig - The Orchestrator**
```zig
// Job: Coordinate all game systems
pub const Game = struct {
    duck: Duck,           // The player character
    duck_texture: Texture, // Sprite sheet image
    allocator: Allocator, // Memory manager
    
    // Game loop: update -> draw -> repeat
    pub fn run() {
        while (!rl.WindowShouldClose()) {
            self.update();  // Update game logic
            self.draw();    // Render everything
        }
    }
}
```
**Responsibilities:**
- Window management (create, destroy)
- Asset loading (textures, sounds)
- Game loop coordination
- System integration (input + duck + animation)

### **input.zig - Input Capture**
```zig
// Job: Convert keyboard state into game actions
pub const Input = struct {
    move_up: bool,    // W key
    move_down: bool,  // S key
    // ... etc
    
    pub fn update() Input {
        return Input{
            .move_up = rl.IsKeyDown(rl.KEY_W),
            // Check all keys at once
        };
    }
}
```
**Responsibilities:**
- Keyboard state polling
- Input abstraction (keys -> movement vectors)
- Input validation and processing

### **duck.zig - Game Entity**
```zig
// Job: Manage duck behavior and state
pub const Duck = struct {
    position: Vector2,    // Where duck is on screen
    animation: Animation, // How duck looks
    
    pub fn update(input: Input) {
        // 1. Handle input -> movement
        const movement = input.getMovementVector();
        self.position.x += movement.x * DUCK_SPEED;
        
        // 2. Update animation
        self.animation.update();
    }
}
```
**Responsibilities:**
- Duck position and movement
- Boundary checking (don't go off screen)
- Animation control
- Input processing into duck actions

### **animation.zig - Visual Animation**
```zig
// Job: Manage sprite sheet animation
pub const Animation = struct {
    current_frame: i32,    // Which frame we're on (0-5)
    frame_counter: i32,    // Timer for frame changes
    frame_speed: i32,      // How fast to animate
    
    pub fn update() {
        frame_counter += 1;  // Count up each frame
        if (frame_counter >= (60 / frame_speed)) {
            current_frame += 1;  // Next sprite frame
            frame_counter = 0;   // Reset timer
        }
    }
}
```
**Responsibilities:**
- Sprite sheet frame selection
- Animation timing
- Visual rendering of sprites

### **constants.zig - Configuration**
```zig
// Job: Store all game settings in one place
pub const SCREEN_WIDTH = 800;
pub const DUCK_SPEED: f32 = 3.0;
pub const DUCK_FRAMES = 6;
// ... etc
```
**Responsibilities:**
- Centralized configuration
- Easy tweaking of game balance
- Avoiding magic numbers in code

### **paths.zig - File System**
```zig
// Job: Handle file paths across different operating systems
pub fn getDuckSpritePath(allocator: Allocator) ![]u8 {
    // Windows: "assets\sprites\duck.png"
    // Linux:   "assets/sprites/duck.png"
    return getSpriteSheet(allocator, "ducky_3_spritesheet.png");
}
```
**Responsibilities:**
- Cross-platform file paths
- Asset location management
- Path string construction

---

## 🧠 Memory Management & Pointers {#memory-pointers}

### **Why `self: Input` vs `self: *Input`?**

This is a **fundamental Zig concept** about when to copy vs when to reference:

```zig
// Method 1: Copy the struct (self: Input)
pub fn hasMovement(self: Input) bool {
    return self.move_up or self.move_down;  // Reading only
}

// Method 2: Reference the struct (self: *Input)
pub fn changePosition(self: *Duck) void {
    self.position.x += 10.0;  // Modifying the original
}
```

**Use `self: Type` (copy) when:**
- ✅ **Reading only** - not changing the struct
- ✅ **Small structs** - cheap to copy
- ✅ **Simple data** - like Input (just booleans)

**Use `self: *Type` (pointer) when:**
- ✅ **Modifying** the struct's data
- ✅ **Large structs** - expensive to copy
- ✅ **Complex state** - like Duck, Animation, Game

### **Input Struct Analysis**
```zig
pub const Input = struct {
    move_up: bool,     // 1 byte
    move_down: bool,   // 1 byte
    move_left: bool,   // 1 byte
    move_right: bool,  // 1 byte
    speed_up: bool,    // 1 byte
    speed_down: bool,  // 1 byte
    // Total: ~6 bytes - very small!
};
```

**Why Input uses copies:**
1. **Small size** - only 6 bytes, cheaper to copy than to dereference a pointer
2. **Read-only** - methods like `hasMovement()` only read the data
3. **Immutable snapshot** - Input represents a moment in time
4. **Functional style** - Input.update() creates a new Input each frame

### **Duck Struct Analysis**
```zig
pub const Duck = struct {
    position: Vector2,      // 8 bytes (2 floats)
    animation: Animation,   // ~50+ bytes (texture refs, counters, etc.)
    // Total: 50+ bytes - larger, and we modify it!
};
```

**Why Duck uses pointers:**
1. **Larger size** - more expensive to copy
2. **Mutable state** - we constantly modify position and animation
3. **Identity** - there's ONE duck, not copies of ducks
4. **Performance** - avoid copying large structs every frame

### **Memory Layout Visualization**
```
STACK MEMORY:
┌─────────────────┐
│ Game {          │
│   duck: Duck    │ ← Actual duck data stored here
│   texture: ...  │
│ }               │
└─────────────────┘

FUNCTION CALLS:
┌─────────────────┐
│ duck.update()   │ ← Passes pointer to duck (&duck)
│   └─ input      │ ← Copies input struct (small)
└─────────────────┘
```

---

## 🏗️ Build System & Cross-Platform {#build-system}

### **Zig Build Process**
```bash
zig build -Dtarget=x86_64-windows
```

**What happens:**
1. **Parse build.zig** - Read build configuration
2. **Compile each .zig file** - Convert to object files
3. **Link with Raylib** - Add graphics library
4. **Generate executable** - Create .exe or binary
5. **Copy to zig-out/bin/** - Place in output directory

### **Cross-Platform Compilation Magic**
```zig
// In paths.zig
const separator = if (builtin.os.tag == .windows) "\\" else "/";
```

**Compile time evaluation:**
- **Linux build**: `separator = "/"`
- **Windows build**: `separator = "\\"`
- **Zero runtime cost** - decided at compile time!

### **Target Platforms**
```bash
# Native (current system)
zig build

# Windows x64
zig build -Dtarget=x86_64-windows

# Linux x64
zig build -Dtarget=x86_64-linux

# macOS
zig build -Dtarget=x86_64-macos
```

---

## 🎯 Key Concepts {#key-concepts}

### **1. Separation of Concerns**
Each module has ONE job:
- **main.zig**: Program lifecycle
- **game.zig**: Game coordination
- **duck.zig**: Duck behavior
- **input.zig**: Keyboard handling
- **animation.zig**: Visual animation
- **constants.zig**: Configuration
- **paths.zig**: File system

### **2. Data Flow Direction**
```
Input → Duck → Animation → Rendering
  ↑                           ↓
  └─── Game Loop Control ←────┘
```

### **3. Ownership & Lifetimes**
```zig
// Game owns the duck
pub const Game = struct {
    duck: Duck,  // Game creates and destroys duck
};

// Duck owns its animation
pub const Duck = struct {
    animation: Animation,  // Duck controls animation lifetime
};
```

### **4. Error Handling**
```zig
// Zig's explicit error handling
var game = Game.init(allocator) catch |err| {
    std.debug.print("Failed: {}\n", .{err});
    return;  // Graceful failure
};
```

### **5. Memory Safety**
- **No null pointers** - Zig prevents null dereference
- **No use-after-free** - Compile-time ownership tracking
- **No buffer overflows** - Bounds checking on arrays
- **Explicit allocation** - Must specify how memory is managed

---

## 🚀 Why This Architecture Scales

### **Adding New Features**
```zig
// Want to add enemies? Create src/enemies/enemy.zig
// Want sound? Create src/audio/sound.zig
// Want levels? Create src/levels/level.zig
```

### **Testing Individual Components**
```zig
// Test duck movement without graphics
const duck = Duck.init(test_texture);
const input = Input{ .move_right = true };
duck.update(input);
// Assert duck moved right
```

### **Performance Optimization**
- **Hot paths identified** - Animation and duck update run 60x/second
- **Memory layout optimized** - Small structs copied, large ones referenced
- **Compile-time optimization** - Constants and paths resolved at build time

---

## 📝 Summary

Your duck game demonstrates **professional game architecture patterns**:

1. **Modular Design** - Clear separation between systems
2. **Data-Driven** - Configuration separated from logic
3. **Cross-Platform** - Builds for multiple operating systems
4. **Memory Efficient** - Smart use of copies vs references
5. **Maintainable** - Easy to find, modify, and extend code
6. **Type Safe** - Zig prevents common programming errors

🦆🎮
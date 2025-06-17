const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const Animation = @import("../")
const Input = @import("input.zig").Input;
const constants = @import("../utils/constants.zig");
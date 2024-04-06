const std = @import("std");
const GameState = @import("gameState.zig").GameState;

export fn init(state: *GameState) void {
    _ = state;
    std.debug.print("init snake\n", .{});
}

export fn update(state: *GameState) void {
    _ = state;
    std.debug.print("update snake\n", .{});
}

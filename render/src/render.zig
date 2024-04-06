const std = @import("std");
const GameState = @import("gameState").GameState;

var count: u32 = 0;

export fn init(state: *GameState) void {
    _ = state;
    std.debug.print("init render\n", .{});
}

export fn update(state: *GameState) void {
    std.debug.print("update render {d}\n", .{count});
   
    count += 1;
    if(count == 10) {
        state.should_exit = true;
    }
}

const std = @import("std");
const GameState = @import("gameState.zig").GameState;
const rl = @import("raylib");

export fn init(state: *GameState) void {
    _ = state;
    std.debug.print("init render\n", .{});

    const screenWidth = 800;
    const screenHeight = 450;

    rl.initWindow(
        screenWidth,
        screenHeight,
        "raylib [core] example - basic window",
    );

    rl.setTargetFPS(60);
}

export fn update(state: *GameState) void {
    std.debug.print("update render {d}\n", .{state.ticks});

    state.ticks += 1;
    state.should_exit = rl.windowShouldClose();

    rl.beginDrawing();
    rl.clearBackground(rl.Color.ray_white);
    rl.drawText(
        "Congrats! You created your first window!",
        100,
        200,
        30,
        rl.Color.blue,
    );
    rl.endDrawing();
}

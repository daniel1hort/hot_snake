const std = @import("std");
const Plugin = @import("plugin.zig").Plugin;
const GameState = @import("gameState.zig").GameState;
const rl = @import("raylib");

const snake = Plugin{
    .lib_path = "zig-out/lib/snake.dll",
    .local_file_path = "./snake.dll",
};
const render = Plugin{
    .lib_path = "zig-out/lib/render.dll",
    .local_file_path = "./render.dll",
};
var plugins = [_]Plugin{ snake, render };

pub fn main() !u8 {
    rl.setTargetFPS(60); //force raylib to be loaded
    var state: GameState = .{};

    for (&plugins) |*plugin| {
        try plugin.load();
    }
    defer {
        for (&plugins) |*plugin| {
            plugin.unload();
        }
    }

    for (&plugins) |plugin| {
        @call(.auto, plugin.init.?, .{&state});
    }

    while (!state.should_exit) {
        for (&plugins) |*plugin| {
            if (plugin.isModified() catch false) {
                plugin.unload();
                try plugin.load();
            }

            @call(.auto, plugin.update.?, .{&state});
        }
    }

    return 0;
}

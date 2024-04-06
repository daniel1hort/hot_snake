const std = @import("std");
const Plugin = @import("plugin.zig").Plugin;
const GameState = @import("gameState.zig").GameState;

const snake = Plugin.init(
    "../snake/zig-out/lib/snake.dll",
    "./snake.dll",
);
const render = Plugin.init(
    "../render/zig-out/lib/render.dll",
    "./render.dll",
);
var plugins = [_]Plugin{ snake, render };

pub fn main() !u8 {
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

    var timer = try std.time.Timer.start();
    while (!state.should_exit) {
        if (timer.read() < std.time.ns_per_s) continue;
        timer.reset();

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

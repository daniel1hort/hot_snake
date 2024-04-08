const std = @import("std");
const GameState = @import("gameState.zig").GameState;
const rl = @import("raylib");
const types = @import("gameState.zig");

fn cString(text: []u8) [:0]u8 {
    return text[0 .. text.len - 1 :0];
}

const fore_color: rl.Color = .{ .a = 255, .r = 43, .g = 51, .b = 26 };
const back_color: rl.Color = .{ .a = 255, .r = 170, .g = 204, .b = 102 };

const screen_width = 1000;
const screen_height = 600;

export fn init(state: *GameState) void {
    _ = state;

    rl.setConfigFlags(.flag_window_topmost);
    rl.initWindow(
        screen_width,
        screen_height,
        "raylib [core] example - basic window",
    );
    rl.setTargetFPS(60);
}

export fn update(state: *GameState) void {
    state.should_exit = rl.windowShouldClose();

    rl.beginDrawing();
    rl.clearBackground(back_color);

    var buffer: [100]u8 = undefined;
    var stream = std.io.fixedBufferStream(&buffer);
    const writer = stream.writer();

    writer.print("Score: {d}\x00", .{state.score}) catch unreachable;
    const score_text = cString(stream.getWritten());
    stream.reset();
    rl.drawText(
        score_text,
        10,
        5,
        40,
        fore_color,
    );
    rl.drawLineEx(
        .{ .x = 0, .y = 50 },
        .{ .x = screen_width, .y = 50 },
        5,
        fore_color,
    );

    const size = 50;
    //drawGrid(size);
    drawSnake(size, state.snake.segments.items);
    drawFood(size, state.food);

    if (state.game_over) {
        drawGameOverOverlay(state.score);
    }

    rl.endDrawing();
}

export fn deinit(state: *GameState) void {
    state.snake.segments.deinit();
    rl.closeWindow();
}

fn drawSnake(size: i32, segments: []types.Point2) void {
    for (segments) |segment| {
        rl.drawRectangleRounded(
            .{
                .x = @floatFromInt(segment.x * size),
                .y = @floatFromInt((segment.y + 1) * size),
                .width = @floatFromInt(size),
                .height = @floatFromInt(size),
            },
            0.5,
            10,
            fore_color,
        );
    }
}

fn drawFood(size: f32, position: types.Point2) void {
    const center: rl.Vector2 = .{
        .x = @as(f32, @floatFromInt(position.x)) * size + size * 0.5,
        .y = @as(f32, @floatFromInt(position.y)) * size + size * 1.5,
    };

    rl.drawCircleV(
        center,
        size * 0.5,
        fore_color,
    );

    rl.drawCircleV(
        center,
        size * 0.17,
        back_color,
    );
}

fn drawGrid(size: u32) void {
    for (1..screen_width / size) |i| {
        rl.drawLineEx(
            .{ .x = @floatFromInt(i * size), .y = 50 },
            .{ .x = @floatFromInt(i * size), .y = @floatFromInt(screen_height) },
            3,
            fore_color,
        );
    }

    for (1..screen_height / size) |i| {
        rl.drawLineEx(
            .{ .x = 0, .y = @floatFromInt(i * size) },
            .{ .x = @floatFromInt(screen_width), .y = @floatFromInt(i * size) },
            3,
            fore_color,
        );
    }
}

fn drawGameOverOverlay(score: u32) void {
    const bounds: rl.Rectangle = .{
        .x = screen_width * 0.2,
        .y = screen_height * 0.2,
        .width = screen_width * 0.6,
        .height = screen_height * 0.6,
    };
    rl.drawRectangleRec(bounds, fore_color);

    const text_size = 50;
    const gap = 25;
    const text_area_height = text_size * 2 + gap;

    var buffer: [100]u8 = undefined;
    var stream = std.io.fixedBufferStream(&buffer);
    const writer = stream.writer();

    writer.print("Game Over\x00", .{}) catch unreachable;
    const header_text = cString(stream.getWritten());
    const header_length = rl.measureText(header_text, text_size);
    rl.drawText(
        header_text,
        @divFloor(screen_width - header_length, 2),
        bounds.y + @divFloor(bounds.height - text_area_height, 2),
        text_size,
        back_color,
    );

    stream.reset();
    writer.print("Your score is {d}\x00", .{score}) catch unreachable;
    const score_text = cString(stream.getWritten());
    const score_length = rl.measureText(score_text, text_size);
    rl.drawText(
        score_text,
        @divFloor(screen_width - score_length, 2),
        bounds.y + text_size + gap + @divFloor(bounds.height - text_area_height, 2),
        text_size,
        back_color,
    );
}

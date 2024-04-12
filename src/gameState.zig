const std = @import("std");

pub const GameState = struct {
    allocator: std.mem.Allocator = undefined,
    timer: std.time.Timer = undefined,
    ticks: u128 = 0,
    ms_last_update: u64 = 0,
    ms_between_updates: u64 = 100,

    should_exit: bool = false,
    snake: Snake = undefined,
    food: Point2 = undefined,
    score: u32 = 0,
    map_size: Point2 = .{.x = 20, .y = 11},
    game_over: bool = false,
};

pub const Snake = struct {
    segments: std.ArrayList(Point2),
    direction: Direction,
    next_directions: []Direction,
};

pub const Point2 = struct {
    x: i32,
    y: i32,
};

pub const Direction = enum {
    none,
    up,
    right,
    down,
    left,
};

pub const directionMap = blk: {
    var array = std.EnumArray(Direction, Point2).initUndefined();
    array.set(.none, .{.x = 0, .y = 0});
    array.set(.up, .{ .x = 0, .y = -1 });
    array.set(.right, .{ .x = 1, .y = 0 });
    array.set(.down, .{ .x = 0, .y = 1 });
    array.set(.left, .{ .x = -1, .y = 0 });
    break :blk array;
};

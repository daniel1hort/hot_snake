const std = @import("std");

pub const GameState = struct {
    allocator: std.mem.Allocator = undefined,
    should_exit: bool = false,
    ticks: u128 = 0,
    snake: Snake = undefined,
    food: Point2 = undefined,
    score: u32 = 0,
};

pub const Snake = struct {
    segments: std.ArrayList(Point2),
    direction: Direction,
};

pub const Point2 = struct {
    x: i32,
    y: i32,
};

pub const Direction = enum {
    up,
    right,
    down,
    left,
};

pub const directionMap = blk: {
    var array = std.EnumArray(Direction, Point2).initUndefined();
    array.set(.up, .{ .x = 0, .y = -1 });
    array.set(.right, .{ .x = 1, .y = 0 });
    array.set(.down, .{ .x = 0, .y = 1 });
    array.set(.left, .{ .x = -1, .y = 0 });
    break :blk array;
};

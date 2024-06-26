const std = @import("std");
const GameState = @import("gameState.zig").GameState;
const types = @import("gameState.zig");
const rl = @import("raylib");

export fn init(state: *GameState) void {
    state.allocator = std.heap.page_allocator;
    state.snake.segments = std.ArrayList(types.Point2).init(state.allocator);
    state.timer = std.time.Timer.start() catch unreachable;
    initGame(state);
}

export fn update(state: *GameState) void {
    const key_pressed = rl.getKeyPressed();
    if (key_pressed == .key_r) {
        initGame(state);
    }

    if (state.game_over)
        return;

    if (shouldUpdate(state)) {
        updateDirection(state);

        const head = state.snake.segments.getLast();
        const dir_off = types.directionMap.get(state.snake.direction);
        const new_head: types.Point2 = .{
            .x = @mod(head.x + dir_off.x, state.map_size.x),
            .y = @mod(head.y + dir_off.y, state.map_size.y),
        };

        if (snakeContains(state.snake.segments.items[1..], new_head)) {
            state.game_over = true;
        } else {
            state.snake.segments.append(new_head) catch unreachable;
        }

        if (std.meta.eql(state.food, new_head)) {
            updateFood(state);
            state.score += 1;
        } else {
            _ = state.snake.segments.orderedRemove(0);
        }
    }

    bufferDirection(state, key_pressed);
}

export fn deinit(state: *GameState) void {
    state.snake.segments.clearAndFree();
    state.snake.segments.deinit();
    state.allocator.free(state.snake.next_directions);
}

fn nextDirection(key: rl.KeyboardKey, previous: types.Direction) types.Direction {
    return switch (key) {
        .key_w, .key_up => if (previous != .down) .up else .none,
        .key_d, .key_right => if (previous != .left) .right else .none,
        .key_s, .key_down => if (previous != .up) .down else .none,
        .key_a, .key_left => if (previous != .right) .left else .none,
        else => .none,
    };
}

fn bufferDirection(state: *GameState, key: rl.KeyboardKey) void {
    const index = for (state.snake.next_directions, 0..) |dir, i| {
        if (dir == .none) break i;
    } else null;

    if (index) |value| {
        const previous = switch (value) {
            0 => state.snake.direction,
            else => state.snake.next_directions[value - 1],
        };
        state.snake.next_directions[value] = nextDirection(key, previous);
    }
}

fn updateDirection(state: *GameState) void {
    if (state.snake.next_directions[0] == .none)
        return;

    state.snake.direction = state.snake.next_directions[0];
    if (state.snake.next_directions.len >= 2) {
        for (0..state.snake.next_directions.len - 1) |index| {
            state.snake.next_directions[index] = state.snake.next_directions[index + 1];
        }
    }
    state.snake.next_directions[state.snake.next_directions.len - 1] = .none;
}

fn shouldUpdate(state: *GameState) bool {
    const ms_elapsed = state.timer.read() / std.time.ns_per_ms;
    const enough_time_elaped = state.ms_last_update / state.ms_between_updates < ms_elapsed / state.ms_between_updates;
    if (enough_time_elaped)
        state.ms_last_update = ms_elapsed;
    return enough_time_elaped;
}

fn updateFood(state: *GameState) void {
    var new_index = rl.getRandomValue(0, state.map_size.x * state.map_size.y - 1);

    for (0..@intCast(state.map_size.x * state.map_size.y)) |_| {
        if (snakeContains(
            state.snake.segments.items,
            index2MapPoint(new_index, state.map_size),
        )) {
            new_index = @mod(new_index + 1, state.map_size.x * state.map_size.y);
        } else {
            break;
        }
    }

    state.food = index2MapPoint(new_index, state.map_size);
}

fn index2MapPoint(index: i32, map_size: types.Point2) types.Point2 {
    const point: types.Point2 = .{
        .x = @mod(index, map_size.x),
        .y = @divFloor(index, map_size.x),
    };
    return point;
}

fn snakeContains(snake: []types.Point2, point: types.Point2) bool {
    for (snake) |segment| {
        if (std.meta.eql(segment, point))
            return true;
    }
    return false;
}

fn initGame(state: *GameState) void {
    state.snake.segments.clearAndFree();
    state.snake.segments.append(.{ .x = 3, .y = 6 }) catch unreachable;
    state.snake.segments.append(.{ .x = 4, .y = 6 }) catch unreachable;
    state.snake.segments.append(.{ .x = 5, .y = 6 }) catch unreachable;
    
    state.allocator.free(state.snake.next_directions);
    state.snake.next_directions = state.allocator.alloc(types.Direction, 2) catch unreachable;
    @memset(state.snake.next_directions, .none);

    state.snake.direction = .right;
    state.food = .{ .x = 15, .y = 6 };
    state.score = 0;
    state.game_over = false;
}

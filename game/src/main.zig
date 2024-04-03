const std = @import("std");

pub fn copyFile(src: []const u8, dest: []const u8) !void {
    var src_file = try std.fs.cwd().openFile(src, .{});
    defer src_file.close();
    var dest_file = try std.fs.cwd().createFile(dest, .{});
    defer dest_file.close();

    const reader = src_file.reader();
    const writer = dest_file.writer();

    const size = 100 * 1024;
    var buffer: [size]u8 = undefined;
    while (reader.read(&buffer)) |count| {
        if (count == 0) break;
        _ = try writer.write(buffer[0..count]);
    } else |_| {}
}

pub const Plugin = struct {
    lib_path: []const u8,
    local_file_path: []const u8,
    dll: ?std.DynLib = null,
    update: ?*const fn () void = null,
    last_modified: i128 = 0,

    pub fn init(lib_path: []const u8, local_file_path: []const u8) Plugin {
        return .{
            .lib_path = lib_path,
            .local_file_path = local_file_path,
        };
    }

    pub fn load(self: *Plugin) !void {
        if (self.dll) |_| {
            return; // already loaded
        }

        try copyFile(self.lib_path, self.local_file_path);
        self.dll = try std.DynLib.open(self.local_file_path);
        self.update = self.dll.?.lookup(*const fn () void, "update") orelse unreachable;
    }

    pub fn unload(self: *Plugin) void {
        if (self.dll) |*dll| {
            dll.close();
            self.dll = null;
            self.update = null;
        }
    }

    pub fn isModified(self: *Plugin) !bool {
        const file = try std.fs.cwd().openFile(self.lib_path, .{});
        defer file.close();
        const stats = try file.stat();
        if (stats.mtime > self.last_modified) {
            self.last_modified = stats.mtime;
            return true;
        }
        return false;
    }
};

pub fn main() !u8 {
    var snake_path = "../snake/zig-out/lib/snake.dll";
    var snake = Plugin.init(snake_path, "./snake.dll");
    try snake.load();
    defer snake.unload();

    var timer = try std.time.Timer.start();
    while (true) {
        if(timer.read() < std.time.ns_per_s) continue;
        timer.reset();

        if (snake.isModified() catch false) {
            snake.unload();
            try snake.load();
        }
        //@call(.auto, snake.update.?, .{});
        snake.update.?();
    }

    return 0;
}

const std = @import("std");
const GameState = @import("gameState.zig").GameState;
var enable_logs = true;

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
    init: ?*const fn (*GameState) void = null,
    update: ?*const fn (*GameState) void = null,
    deinit: ?*const fn (*GameState) void = null,
    last_modified: i128 = 0,

    pub fn load(self: *Plugin) !void {
        if (self.dll) |_| {
            return; // already loaded
        }

        if (self.last_modified == 0)
            _ = try isModified(self);

        if (enable_logs)
            std.log.info("copy file {s} as {s}", .{ self.lib_path, self.local_file_path });

        try copyFile(self.lib_path, self.local_file_path);

        if (enable_logs)
            std.log.info("attempting to load {s}", .{self.local_file_path});

        self.dll = try std.DynLib.open(self.local_file_path);
        self.init = self.dll.?.lookup(*const fn (*GameState) void, "init") orelse unreachable;
        self.update = self.dll.?.lookup(*const fn (*GameState) void, "update") orelse unreachable;
        self.deinit = self.dll.?.lookup(*const fn (*GameState) void, "deinit") orelse unreachable;

        if (enable_logs)
            std.log.info("successfuly loaded {s}", .{self.local_file_path});
    }

    pub fn unload(self: *Plugin) void {
        if (self.dll) |*dll| {
            if (enable_logs)
                std.log.info("unloading {s}", .{self.local_file_path});

            dll.close();
            self.dll = null;
            self.init = null;
            self.update = null;
            self.deinit = null;
        }
    }

    pub fn isModified(self: *Plugin) !bool {
        const file = try std.fs.cwd().openFile(self.lib_path, .{});
        defer file.close();
        const stats = try file.stat();
        if (stats.mtime > self.last_modified) {
            if (enable_logs)
                std.log.info("file changed {s}", .{self.lib_path});

            self.last_modified = stats.mtime;
            return true;
        }
        return false;
    }
};

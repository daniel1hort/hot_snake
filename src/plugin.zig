const std = @import("std");
const GameState = @import("gameState.zig").GameState;

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
    last_modified: i128 = 0,

    pub fn load(self: *Plugin) !void {
        if (self.dll) |_| {
            return; // already loaded
        }

        _ = try isModified(self);

        std.log.info("attempt to load {s}", .{self.local_file_path});

        try copyFile(self.lib_path, self.local_file_path);
        self.dll = try std.DynLib.open(self.local_file_path);
        self.init = self.dll.?.lookup(*const fn (*GameState) void, "init") orelse unreachable;
        self.update = self.dll.?.lookup(*const fn (*GameState) void, "update") orelse unreachable;

        std.log.info("successfuly loaded {s}", .{self.local_file_path});
    }

    pub fn unload(self: *Plugin) void {
        if (self.dll) |*dll| {
            dll.close();
            self.dll = null;
            self.init = null;
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

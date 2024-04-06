const std = @import("std");

pub fn build(b: *std.Build) void {
    const build_exe = b.option(bool, "build_exe", "only build the game shared library") orelse false;

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    b.installFile(
        "raylib/zig-out/lib/raylib.dll",
        "../raylib.dll",
    );

    const raylib_zig = b.createModule(.{
        .source_file = .{ .path = "raylib-zig/lib/raylib-zig.zig" },
    });

    const render_lib = b.addSharedLibrary(.{
        .name = "render",
        .root_source_file = .{ .path = "src/render.zig" },
        .target = target,
        .optimize = optimize,
    });
    render_lib.addModule("raylib", raylib_zig);
    render_lib.addLibraryPath(.{ .path = "raylib/zig-out/lib" });
    render_lib.linkSystemLibrary("raylib");
    //render_lib.linkSystemLibrary("winmm");
    //render_lib.linkSystemLibrary("gdi32");
    //render_lib.linkSystemLibrary("opengl32");
    render_lib.linkLibC();
    b.installArtifact(render_lib);

    const snake_lib = b.addSharedLibrary(.{
        .name = "snake",
        .root_source_file = .{ .path = "src/snake.zig" },
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(snake_lib);

    if (build_exe) {
        const exe = b.addExecutable(.{
            .name = "game",
            .root_source_file = .{ .path = "src/main.zig" },
            .target = target,
            .optimize = optimize,
        });
        exe.addLibraryPath(.{ .path = "raylib/zig-out/lib" });
        exe.linkSystemLibrary("raylib");
        exe.linkSystemLibrary("winmm");
        exe.linkSystemLibrary("gdi32");
        exe.linkSystemLibrary("opengl32");
        exe.linkLibC();
        exe.addModule("raylib", raylib_zig);
        //exe.subsystem = .Windows;
        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
        const run_step = b.step("run", "Run the app");
        run_step.dependOn(&run_cmd.step);

        const unit_tests = b.addTest(.{
            .root_source_file = .{ .path = "src/main.zig" },
            .target = target,
            .optimize = optimize,
        });
        const run_unit_tests = b.addRunArtifact(unit_tests);
        const test_step = b.step("test", "Run unit tests");
        test_step.dependOn(&run_unit_tests.step);
    }
}

const std = @import("std");

fn getch_windows(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    var getch = b.addStaticLibrary(.{ .name = "getch", .target = target, .optimize = optimize });
    getch.addCSourceFiles(.{ .files = &.{"src/getch_windows.c"} });
    getch.addIncludePath(.{ .path = "src" });
    getch.linkLibC();
    getch.installHeader("src/getch_windows.h", "getch.h");
    return getch;
}

fn getch_termios(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    var getch = b.addStaticLibrary(.{ .name = "getch", .target = target, .optimize = optimize });
    getch.addCSourceFiles(.{ .files = &.{"src/getch_termios.c"} });
    getch.addIncludePath(.{ .path = "src" });
    getch.linkLibC();
    getch.installHeader("src/getch_termios.h", "getch.h");
    return getch;
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const getch = switch (target.result.os.tag) {
        .windows => getch_windows(b, target, optimize),
        else => getch_termios(b, target, optimize),
    };

    const lib = b.addStaticLibrary(.{
        .name = "zig-prompts",
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(lib);
    b.installArtifact(getch);

    const exe = b.addExecutable(.{
        .name = "zig-prompts",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    exe.linkLibC();
    exe.linkLibrary(getch);
    exe.linkLibrary(lib);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const lib_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);
}

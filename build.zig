const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // External dependencies
    const mecha = b.dependency("mecha", .{});

    // Common module for shared utilities
    const common = b.addModule("common", .{
        .root_source_file = b.path("src/common/lib.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "mecha", .module = mecha.module("mecha") },
        },
    });

    addDay(b, "day01", target, optimize, common, mecha.module("mecha"));
    addDay(b, "day02", target, optimize, common, mecha.module("mecha"));
    addDay(b, "day03", target, optimize, common, mecha.module("mecha"));
    addDay(b, "day04", target, optimize, common, mecha.module("mecha"));
    addDay(b, "day05", target, optimize, common, mecha.module("mecha"));
    addDay(b, "day06", target, optimize, common, mecha.module("mecha"));
    addDay(b, "day07", target, optimize, common, mecha.module("mecha"));
    addDay(b, "day08", target, optimize, common, mecha.module("mecha"));
    addDay(b, "day09", target, optimize, common, mecha.module("mecha"));
    addDay(b, "day10", target, optimize, common, mecha.module("mecha"));
}

fn addDay(
    b: *std.Build,
    comptime name: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    common: *std.Build.Module,
    mecha: *std.Build.Module,
) void {
    const exe = b.addExecutable(.{
        .name = name,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/" ++ name ++ "/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "common", .module = common },
                .{ .name = "mecha", .module = mecha },
            },
        }),
        .use_llvm = true, // Better debug info for lldb
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step(name, "Run " ++ name);
    run_step.dependOn(&run_cmd.step);

    // Tests
    const exe_tests = b.addTest(.{
        .name = name ++ "-test",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/" ++ name ++ "/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "common", .module = common },
                .{ .name = "mecha", .module = mecha },
            },
        }),
        .use_llvm = true,
    });

    // Install test binary for debugging: zig-out/bin/day01-test
    b.installArtifact(exe_tests);

    const test_step = b.step(name ++ "-test", "Run " ++ name ++ " tests");
    test_step.dependOn(&b.addRunArtifact(exe_tests).step);
}

const std = @import("std");

// const vector = std.build.Pkg{
//     .name = "vector",
//     .source = .{ .path = "vector.zig" },
//     .dependencies = &[_]std.build.Pkg{},
// };

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "ziggin",
        .root_source_file = b.path("ziggin.zig"),
        .target = b.host,
    });

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const vector_mod = b.addModule("vector", .{
        .root_source_file = b.path("vector.zig"),
        .target = target,
        .optimize = optimize,
    });

    const ncurses_mod = b.addModule("ncurses_wrapper", .{
        .root_source_file = b.path("ncurses_wrapper.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.root_module.addImport("vector", vector_mod);
    exe.root_module.addImport("ncurses_wrapper", ncurses_mod);

    exe.linkSystemLibrary("ncurses");
    exe.linkLibC();

    b.installArtifact(exe);
}

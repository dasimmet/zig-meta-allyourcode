const std = @import("std");
const LazyPath = std.Build.LazyPath;
const Toolchain = @This();

CC: LazyPath,
CXX: LazyPath,
CMAKE: LazyPath = .{ .cwd_relative = "cmake" },
MAKE: LazyPath = .{ .cwd_relative = "make" },
// we compile a simple tool to run both cmake and build step after one another,
// and pass arguments for both to it
// otherwise we cannot work with the zig cache, as cmake wants to know the output
// directory of gmake
CMAKE_WRAPPER: LazyPath,
ZIG: []const u8 = "zig",

pub const Options = struct {
    optimize: std.builtin.OptimizeMode = .ReleaseSmall,
};

// populates a Toolchain with the wrapper commands
// from this repository
pub fn zigBuildDefaults(b: *std.Build, opt: Options) *Toolchain {
    const zig_cc = b.addExecutable(.{
        .name = "cc",
        .root_source_file = b.path("src/host/cc.zig"),
        .target = b.graph.host,
        .optimize = opt.optimize,
    });
    const zig_cxx = b.addExecutable(.{
        .name = "cxx",
        .root_source_file = b.path("src/host/cxx.zig"),
        .target = b.graph.host,
        .optimize = opt.optimize,
    });
    const cmake_wrapper = b.addExecutable(.{
        .name = "cmake_make_wrapper",
        .root_source_file = b.path("src/host/cmake_make_wrapper.zig"),
        .target = b.graph.host,
        .optimize = opt.optimize,
    });

    const self = b.allocator.create(Toolchain) catch @panic("OOM");
    self.* = .{
        .CC = zig_cc.getEmittedBin(),
        .CXX = zig_cxx.getEmittedBin(),
        .ZIG = b.graph.zig_exe,
        .CMAKE_WRAPPER = cmake_wrapper.getEmittedBin(),
    };
    return self;
}

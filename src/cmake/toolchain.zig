const std = @import("std");
const LazyPath = std.Build.LazyPath;
const Toolchain = @This();

CC: LazyPath = .{ .cwd_relative = "cc" },
CXX: LazyPath = .{ .cwd_relative = "c++" },
CMAKE: LazyPath = .{ .cwd_relative = "cmake" },
MAKE: LazyPath = .{ .cwd_relative = "make" },
ZIG: []const u8 = "zig",

pub fn zigBuildDefaults(b: *std.Build) *Toolchain {
    const self = b.allocator.create(Toolchain) catch @panic("OOM");
    self.* = .{};
    self.ZIG = b.graph.zig_exe;
    const zig_cc = b.addExecutable(.{
        .name = "cc",
        .root_source_file = b.path("src/host/cc.zig"),
        .target = b.graph.host,
        .optimize = .Debug,
    });
    self.CC = zig_cc.getEmittedBin();
    const zig_cxx = b.addExecutable(.{
        .name = "cxx",
        .root_source_file = b.path("src/host/cxx.zig"),
        .target = b.graph.host,
        .optimize = .Debug,
    });
    self.CXX = zig_cxx.getEmittedBin();
    return self;
}

const std = @import("std");
const LazyPath = std.Build.LazyPath;
const Toolchain = @This();

CC: LazyPath = .{ .cwd_relative = "cc" },
CXX: LazyPath = .{ .cwd_relative = "c++" },
CMAKE: LazyPath = .{ .cwd_relative = "cmake" },
MAKE: LazyPath = .{ .cwd_relative = "make" },

pub fn zigBuildDefaults(self: *Toolchain, b: *std.Build) void {
    const native = b.resolveTargetQuery(.{});
    const zig_cc = b.addExecutable(.{
        .name = "cc",
        .root_source_file = b.path("src/cc.zig"),
        .target = native,
        .optimize = .Debug,
    });
    self.CC = zig_cc.getEmittedBin();
    const zig_cxx = b.addExecutable(.{
        .name = "cxx",
        .root_source_file = b.path("src/cxx.zig"),
        .target = native,
    });
    self.CXX = zig_cxx.getEmittedBin();
}

pub fn zigBuildDefaultsRelative(self: *Toolchain, b: *std.Build) void {
    const native = b.resolveTargetQuery(.{});
    const zig_cc = b.addExecutable(.{
        .name = "cc",
        .root_source_file = .{ .cwd_relative = "src/cc.zig" },
        .target = native,
        .optimize = .Debug,
    });
    self.CC = zig_cc.getEmittedBin();
    const zig_cxx = b.addExecutable(.{
        .name = "cxx",
        .root_source_file = .{ .cwd_relative = "src/cxx.zig" },
        .target = native,
    });
    self.CXX = zig_cxx.getEmittedBin();
}

// meta_allyourcode_example
//
// by Tobias Simetsreiter <dasimmet@gmail.com>
//

const meta_allyourcode = @import("meta_allyourcode");

const std = @import("std");
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const meta_dep = meta_allyourcode.lazy.dependency(
        b,
        "cmake",
        .{
            .target = target,
            .optimize = optimize,
        },
    );
    _ = meta_dep;
}

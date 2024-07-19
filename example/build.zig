// meta_allyourcode_example
//
// by Tobias Simetsreiter <dasimmet@gmail.com>
//

const meta_allyourcode = @import("meta_allyourcode");

const std = @import("std");
pub fn build(b: *std.Build) void {
    // const target = b.standardTargetOptions(.{});
    // const optimize = b.standardOptimizeOption(.{});
    if (b.lazyDependency("sqlite3_cmake", .{})) |sqlite3_dep| {
        const cmakeStep = meta_allyourcode.addCMakeStep(b, .{
            .target = b.graph.host,
            .name = "cmake",
            .source_dir = sqlite3_dep.path(""),
        });
        b.getInstallStep().dependOn(&cmakeStep.step);
    }
}

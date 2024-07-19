// meta_allyourcode_example
//
// by Tobias Simetsreiter <dasimmet@gmail.com>
//

const meta_allyourcode = @import("meta_allyourcode");

const std = @import("std");
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    // const optimize = b.standardOptimizeOption(.{});
    if (b.lazyDependency("sqlite3_cmake", .{})) |sqlite3_dep| {
        const cmakeStep = meta_allyourcode.addCMakeStep(b, .{
            .target = target,
            .name = "cmake",
            .source_dir = sqlite3_dep.path(""),
        });
        cmakeStep.addCmakeDefine("CMAKE_BUILD_TYPE","Release");
        const sqlite3_install = cmakeStep.install(b, "");
        b.getInstallStep().dependOn(&sqlite3_install.step);
    }
}

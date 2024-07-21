// meta_allyourcode_example
//
// by Tobias Simetsreiter <dasimmet@gmail.com>
//

const std = @import("std");
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const meta_import = b.lazyImport(@This(), "meta_allyourcode");

    // const optimize = b.standardOptimizeOption(.{});
    if (b.lazyDependency("sqlite3_cmake", .{})) |sqlite3_dep| {
        if (meta_import) |meta_allyourcode| {
            const cmakeStep = meta_allyourcode.addCMakeStep(b, .{
                .target = target,
                .name = "cmake sqlite3",
                .source_dir = sqlite3_dep.path(""),
                .verbose = b.option(
                    bool,
                    "verbose-cmake",
                    "print cmake ouptut",
                ) orelse false,
                .defines = &.{
                    .{ "CMAKE_BUILD_TYPE", "Release" },
                },
            });
            const sqlite3_install = cmakeStep.install(b, "");
            b.getInstallStep().dependOn(&sqlite3_install.step);
        }
    }
}

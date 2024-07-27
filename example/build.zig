// meta_allyourcode_example
//
// by Tobias Simetsreiter <dasimmet@gmail.com>
//

const std = @import("std");
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const meta_import = b.lazyImport(@This(), "meta_allyourcode");

    // const optimize = b.standardOptimizeOption(.{});
    if (b.lazyDependency("sqlite3_cmake", .{
        .target = target,
        .optimize = optimize,
    })) |sqlite3_dep| {
        if (meta_import) |meta_allyourcode| {
            const cmake_sqlite3_step = meta_allyourcode.addCMakeStep(b, .{
                .target = target,
                .name = "cmake sqlite3",
                .source_dir = sqlite3_dep.path(""),
                .global_cache = true,
                .verbose = b.option(
                    bool,
                    "verbose-cmake",
                    "print cmake ouptut",
                ),
                .defines = &.{
                    .{ "CMAKE_BUILD_TYPE", if (optimize == .Debug) "Debug" else "Release" },
                },
            });
            const sqlite3_install = cmake_sqlite3_step.install(b, "");
            b.getInstallStep().dependOn(&sqlite3_install.step);
        }
    }
}

// meta_allyourcode
//
// by Tobias Simetsreiter <dasimmet@gmail.com>
//

const meta_allyourcode = @This();
const std = @import("std");
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    // _ = target;
    // _ = optimize;
    const dep_option = b.option([]const u8, "dependency", "the dependency to fetch");
    if (dep_option) |d| {
        _ = b.lazyDependency(d, .{});
    } else {
        if (b.lazyDependency("cmake", .{
            .target = target,
            .optimize = optimize,
        })) |cmake_dep| {
            @import("src/cmake.zig").build(cmake_dep.builder);
            b.getInstallStep().dependOn(&b.addInstallArtifact(cmake_dep.artifact("bootstrap"), .{
                .dest_sub_path = "cmake",
            }).step);
        }
    }
}

pub const lazy = struct {
    pub fn dependency(b: *std.Build, name: []const u8, args: anytype) ?*std.Build.Dependency {
        const this_dep = b.dependencyFromBuildZig(meta_allyourcode, .{
            .dependency = name,
        });
        return this_dep.builder.lazyDependency(name, args);
    }
};

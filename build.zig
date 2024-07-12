// meta_allyourcode
//
// by Tobias Simetsreiter <dasimmet@gmail.com>
//

const meta_allyourcode = @This();
const std = @import("std");
const cmake = @import("src/cmake.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    _ = target;
    _ = optimize;
    const dep_option = b.option([]const u8, "dependency", "the dependency to fetch");
    if (dep_option) |d| {
        _ = b.lazyDependency(d, .{});
    } else {
        var cmake_options = cmake.kwSysConfig.defaults{};
        inline for (@typeInfo(cmake.kwSysConfig.defaults).Struct.fields) |f| {
            if (b.option(f.type, f.name, f.name ++ " - cmake")) |opt| {
                @field(cmake_options, f.name) = opt;
            }
        }
        if (b.lazyDependency("cmake", cmake_options)) |cmake_dep| {
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

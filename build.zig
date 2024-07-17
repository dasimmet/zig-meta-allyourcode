// meta_allyourcode
//
// by Tobias Simetsreiter <dasimmet@gmail.com>
//

const meta_allyourcode = @This();
const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const defaults: DefaultBuildOptions = .{
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
    };

    if (b.option(
        []const u8,
        "dependency",
        "use this option to fetch a single named transitive dependency",
    )) |d| {
        _ = b.lazyDependency(d, .{});
    } else {
        addCmakeBuild(b, defaults);
        addLibGitBuild(b, defaults);
    }
    const clean = b.addRemoveDirTree(.{ .cwd_relative = b.cache_root.path.? });
    b.step("clean", "clean").dependOn(&clean.step);
    const clean_glob = b.addRemoveDirTree(.{ .cwd_relative = b.graph.global_cache_root.path.? });
    b.step("clean-glob", "clean").dependOn(&clean_glob.step);
}

pub fn addLibGitBuild(b: *std.Build, defaults: DefaultBuildOptions) void {
    const libgit2 = @import("src/libgit2.zig");
    if (b.lazyDependency("libgit2", defaults)) |dep| {
        libgit2.build(dep.builder);
        const git2_step = b.step("git2", "build the git2 exe");
        inline for (.{ "git2", "libgit2", "git2_util", "pcre" }) |f| {
            const git2_art = b.addInstallArtifact(
                dep.artifact(f),
                .{},
            );
            git2_step.dependOn(&git2_art.step);
        }
        b.getInstallStep().dependOn(git2_step);
    }
}

pub fn addCmakeBuild(b: *std.Build, defaults: DefaultBuildOptions) void {
    const cmake = @import("src/cmake.zig");
    const CMakeOptionsType: type = mergeStructFields(DefaultBuildOptions, cmake.ConfigHeaders.Options);
    var cmake_options: CMakeOptionsType = .{
        .target = defaults.target,
        .optimize = defaults.optimize,
    };
    inline for (@typeInfo(cmake.ConfigHeaders.Options).Struct.fields) |f| {
        if (b.option(f.type, "CMAKE_" ++ f.name, "cmake - " ++ f.name)) |opt| {
            @field(cmake_options, f.name) = opt;
        }
    }

    if (b.lazyDependency("cmake", cmake_options)) |dep| {
        cmake.build(dep.builder);
        const cm_step = b.step("cmake-bs", "build the cmake stage1 exe");
        inline for (.{ "cmake", "uv" }) |f| {
            const cm_art = dep.artifact(f);
            const cm_name = if (cm_art.kind == .lib)
                "cmake_" ++ f ++ ".so"
            else
                "cmake_" ++ f;

            const cm_install = b.addInstallArtifact(cm_art, .{
                .dest_sub_path = cm_name,
            });
            b.getInstallStep().dependOn(&cm_install.step);
            cm_step.dependOn(&cm_install.step);
        }

        var cmake_tc = cmake.Toolchain{};
        cmake_tc.zigBuildDefaults(b);
        cmake_tc.CMAKE = dep.artifact("cmake").getEmittedBin();

        // if (b.lazyDependency("gnumake", .{
        //     .target = cmake_options.target,
        //     .optimize = cmake_options.optimize,
        // })) |gnumake| {
        //     cmake_tc.MAKE = gnumake.artifact("make").getEmittedBin();
        // }

        const cmake_step = cmake.stage2(
            dep.builder,
            cmake_tc,
        );
        const cmake2_install = b.addInstallDirectory(.{
            .source_dir = cmake_step.install_dir,
            .install_dir = .{ .custom = "cmake" },
            .install_subdir = "",
        });
        cmake2_install.step.dependOn(&cmake_step.step);
        b.step("cmake", "run cmake bootstrap stage2 and install").dependOn(&cmake2_install.step);
    }
}

pub fn mergeStructFields(ta: type, tb: type) type {
    const typeinfo_a = @typeInfo(ta);
    const typeinfo_b = @typeInfo(tb);
    const fields_size = typeinfo_a.Struct.fields.len + typeinfo_b.Struct.fields.len;
    var fields: [fields_size]std.builtin.Type.StructField = undefined;
    inline for (typeinfo_a.Struct.fields, 0..) |f, i| {
        fields[i] = f;
    }
    inline for (typeinfo_b.Struct.fields, typeinfo_a.Struct.fields.len..) |f, i| {
        fields[i] = f;
    }
    return @Type(.{ .Struct = .{
        .fields = &fields,
        .layout = .auto,
        .decls = &.{},
        .is_tuple = typeinfo_a.Struct.is_tuple,
    } });
}

pub const DefaultBuildOptions = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
};

pub const lazy = struct {
    pub fn dependency(b: *std.Build, name: []const u8, args: anytype) ?*std.Build.Dependency {
        const this_dep = b.dependencyFromBuildZig(meta_allyourcode, .{
            .dependency = name,
        });
        return this_dep.builder.lazyDependency(name, args);
    }
};

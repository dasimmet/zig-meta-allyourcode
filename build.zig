// meta_allyourcode
//
// by Tobias Simetsreiter <dasimmet@gmail.com>
//

const meta_allyourcode = @This();
const std = @import("std");
const builtin = @import("builtin");
pub const cmake = @import("src/cmake.zig");
pub const libgit2 = @import("src/libgit2.zig");

pub fn build(b: *std.Build) void {
    const defaults: DefaultBuildOptions = .{
        .target = b.standardTargetOptions(.{}),
        .optimize = b.option(
            std.builtin.OptimizeMode,
            "optimize",
            "Prioritize performance, safety, or binary size",
        ) orelse .ReleaseFast,
    };

    if (b.option(
        DependencyBuild,
        "dependency",
        "use this option to fetch a single named transitive dependency",
    )) |d| {
        inline for (DependencyBuild.mapping) |dep_build| {
            if (dep_build[0] == d) dep_build[1](b, defaults);
        }
    } else {
        inline for (DependencyBuild.mapping) |dep_build| {
            dep_build[1](b, defaults);
        }
    }
    const clean = b.addRemoveDirTree(.{ .cwd_relative = b.cache_root.path.? });
    b.step("clean", "clean").dependOn(&clean.step);
}

pub const DependencyBuild = enum {
    cmake,
    libgit2,
    gnumake,

    pub const mapping = .{
        .{ DependencyBuild.cmake, addCmakeBuild },
        .{ DependencyBuild.libgit2, addLibGitBuild },
    };
};

pub fn addLibGitBuild(b: *std.Build, defaults: DefaultBuildOptions) void {
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
            const t: std.Build.ResolvedTarget = cmake_options.target;
            const cm_name = if (cm_art.kind == .lib and cm_art.linkage == .dynamic)
                "cmake_bootstrap_" ++ f ++ t.result.dynamicLibSuffix()
            else if (cm_art.kind == .lib)
                "cmake_bootstrap_" ++ f ++ t.result.staticLibSuffix()
            else
                "cmake_bootstrap_" ++ f ++ t.result.exeFileExt();

            const cm_install = b.addInstallArtifact(cm_art, .{
                .dest_sub_path = cm_name,
            });
            cm_step.dependOn(&cm_install.step);
        }

        const cmake_tc = cmake.Toolchain.zigBuildDefaults(b, cmake_options.optimize);
        cmake_tc.CMAKE = dep.artifact("cmake").getEmittedBin();

        if (b.lazyDependency("gnumake", .{
            .target = cmake_options.target,
            .optimize = cmake_options.optimize,
        })) |gnumake| {
            const gnumake_exe = gnumake.artifact("make");
            b.step("gnumake", "").dependOn(&b.addInstallArtifact(gnumake_exe, .{}).step);
            cmake_tc.MAKE = gnumake_exe.getEmittedBin();
        }

        const cmake_step = cmake.stage2(
            dep.builder,
            cmake_tc,
        );
        _ = cmake_step.getInstallDir();
        const cmake2_install = b.addInstallDirectory(.{
            .source_dir = cmake_step.install_dir,
            .install_dir = .{ .custom = "cmake" },
            .install_subdir = "",
        });
        cmake2_install.step.dependOn(&cmake_step.step);
        b.getInstallStep().dependOn(&cmake2_install.step);
        b.step("cmake", "run cmake bootstrap stage2 and install").dependOn(&cmake2_install.step);
    }
}

pub fn addGnuMakeBuild(b: *std.Build, defaults: DefaultBuildOptions) void {
    if (b.lazyDependency("gnumake", .{
        .target = defaults.target,
        .optimize = defaults.optimize,
    })) |gnumake| {
        const gnumake_exe = gnumake.artifact("make");
        const gm_install = b.addInstallArtifact(
            gnumake_exe,
            .{},
        );
        b.getInstallStep().dependOn(&gm_install.step);
        b.step("gnumake", "install gnumake ").dependOn(&gm_install.step);
    }
}

// will generate a struct type with the fields of ta and tb
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

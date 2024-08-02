// meta_allyourcode
//
// by Tobias Simetsreiter <dasimmet@gmail.com>
//

const meta_allyourcode = @This();
const std = @import("std");
const builtin = @import("builtin");
pub const cmake = @import("src/cmake.zig");
pub const libgit2 = @import("src/libgit2.zig");

pub const DefaultBuildOptions = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    global_cache: bool,
};

pub fn build(b: *std.Build) void {
    const defaults: DefaultBuildOptions = .{
        .target = b.standardTargetOptions(.{}),
        .optimize = b.option(
            std.builtin.OptimizeMode,
            "optimize",
            "Prioritize performance, safety, or binary size",
        ) orelse .ReleaseFast,
        .global_cache = b.option(bool, "global_cache", "set cache to zig global cache dir") orelse false,
    };
    if (defaults.global_cache) {
        b.cache_root = b.graph.global_cache_root;
    }

    if (b.option(
        SubBuild,
        "dependency",
        "use this option to fetch only the required transitive dependencies",
    )) |d| {
        inline for (SubBuild.mapping) |dep_build| {
            if (dep_build[0] == d) dep_build[1](b, defaults);
        }
    } else {
        inline for (SubBuild.mapping) |dep_build| {
            dep_build[1](b, defaults);
        }
    }
    const clean = b.addRemoveDirTree(.{
        .cwd_relative = b.cache_root.path.?,
    });
    b.step("clean", "clean").dependOn(&clean.step);

    const example = std.Build.Step.Run.create(b, "example");
    example.setCwd(b.path("example"));
    example.addArg(b.graph.zig_exe);
    example.addArg("build");
    if (b.verbose) example.addArg("--verbose");

    b.step(
        "example",
        "zig build the example subdirectory",
    ).dependOn(&example.step);
}

pub fn addCMakeStep(b: *std.Build, opt: cmake.CMakeStep.Options) *cmake.CMakeStep {
    const this_dep = b.dependencyFromBuildZig(meta_allyourcode, .{
        .dependency = .cmake,
        .global_cache = opt.global_cache,
    });

    if (opt.global_cache) this_dep.builder.cache_root = b.graph.global_cache_root;
    if (opt.toolchain == null) {
        this_dep.builder.verbose = false;
        const tc = cmake.Toolchain.zigBuildDefaults(this_dep.builder, .{});
        tc.CMAKE = this_dep.namedWriteFiles("cmake").getDirectory().path(this_dep.builder, "bin/cmake");
        if (this_dep.builder.lazyDependency("gnumake", .{
            .target = b.graph.host,
        })) |gnumake| {
            if (opt.global_cache) gnumake.builder.cache_root = b.graph.global_cache_root;
            const gnumake_exe = gnumake.artifact("make");
            tc.MAKE = gnumake_exe.getEmittedBin();
        }
        return cmake.CMakeStep.init(b, .{
            .name = opt.name,
            .source_dir = opt.source_dir,
            .target = opt.target,
            .toolchain = tc,
            .verbose = opt.verbose,
            .defines = opt.defines,
            .global_cache = opt.global_cache,
            .remove_build = opt.remove_build,
        });
    }

    return cmake.CMakeStep.init(b, opt);
}

pub const SubBuild = enum {
    cmake,
    libgit2,
    gnumake,

    pub const mapping = .{
        .{ SubBuild.cmake, addCMakeBootstrap },
        .{ SubBuild.libgit2, addLibGitBuild },
        .{ SubBuild.gnumake, addGnuMakeBuild },
    };
};

fn addLibGitBuild(b: *std.Build, defaults: DefaultBuildOptions) void {
    if (b.lazyDependency("libgit2", defaults)) |dep| {
        libgit2.build(dep.builder);
        const git2_step = b.step("git2", "build the git2 exe");
        inline for (.{ "git2", "libgit2", "pcre", "git2_util", "xdiff" }) |f| {
            const git2_art = b.addInstallArtifact(
                dep.artifact(f),
                .{},
            );
            git2_step.dependOn(&git2_art.step);
            b.step("libgit2_" ++ f, "").dependOn(&git2_art.step);
        }
        b.getInstallStep().dependOn(git2_step);
    }
}

fn addCMakeBootstrap(b: *std.Build, defaults: DefaultBuildOptions) void {
    const CMakeOptionsType: type = mergeStructFields(DefaultBuildOptions, cmake.ConfigHeaders.Options);
    var cmake_options: CMakeOptionsType = .{
        .target = defaults.target,
        .optimize = defaults.optimize,
        .global_cache = defaults.global_cache,
    };
    inline for (@typeInfo(cmake.ConfigHeaders.Options).Struct.fields) |f| {
        if (b.option(f.type, "CMAKE_" ++ f.name, "cmake - " ++ f.name)) |opt| {
            @field(cmake_options, f.name) = opt;
        }
    }

    const cmake_stage1_target_opt = b.option(
        []const u8,
        "cmake_stage1_target",
        "The CPU architecture, OS, and ABI to build cmake stage1 for",
    );
    const cmake_stage1_target = blk: {
        if (cmake_stage1_target_opt) |tstr| {
            const query = std.Build.parseTargetQuery(.{
                .arch_os_abi = tstr,
            }) catch @panic("Unknown Target");
            break :blk b.resolveTargetQuery(query);
        }
        break :blk b.host;
    };
    if (b.lazyDependency("cmake", .{
        .target = cmake_stage1_target,
        .optimize = defaults.optimize,
    })) |dep| {
        if (defaults.global_cache) {
            dep.builder.cache_root = b.graph.global_cache_root;
        }
        cmake.build(dep.builder);
        const stage1_step = b.step("cmake-stage1", "build the cmake stage1 exe");
        inline for (.{ "cmake", "uv" }) |f| {
            const cm_art = dep.artifact(f);
            const cm_name = if (cm_art.kind == .lib and cm_art.linkage == .dynamic)
                "cmake_bootstrap_" ++ f ++ ".so"
            else
                "cmake_bootstrap_" ++ f;

            const cm_install = b.addInstallArtifact(cm_art, .{
                .dest_sub_path = cm_name,
            });
            stage1_step.dependOn(&cm_install.step);
        }

        const cmake_tc = cmake.Toolchain.zigBuildDefaults(b, .{
            .optimize = cmake_options.optimize,
        });
        cmake_tc.CMAKE = dep.artifact("cmake").getEmittedBin();

        if (b.lazyDependency("gnumake", .{
            .target = cmake_options.target,
            .optimize = cmake_options.optimize,
        })) |gnumake| {
            if (cmake_options.global_cache) {
                gnumake.builder.cache_root = b.graph.global_cache_root;
            }
            const gnumake_exe = gnumake.artifact("make");
            cmake_tc.MAKE = gnumake_exe.getEmittedBin();
        }

        const stage2_step = cmake.stage2(
            dep.builder,
            cmake_tc,
            cmake_options.target,
        );
        _ = stage2_step.installNamedWriteFile(b, "cmake");
        const stage2_install = b.addInstallDirectory(.{
            .source_dir = stage2_step.install_dir,
            .install_dir = .{ .custom = "cmake" },
            .install_subdir = "",
        });
        stage2_install.step.dependOn(&stage2_step.step);
        b.getInstallStep().dependOn(&stage2_install.step);
        b.step("cmake", "run cmake bootstrap stage2 and install").dependOn(&stage2_install.step);
    } else {
        _ = b.addNamedWriteFiles("cmake");
    }
}

fn addGnuMakeBuild(b: *std.Build, defaults: DefaultBuildOptions) void {
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

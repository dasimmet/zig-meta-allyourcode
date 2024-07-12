// meta_allyourcode
//
// by Tobias Simetsreiter <dasimmet@gmail.com>
//

const meta_allyourcode = @This();
const std = @import("std");
const FunctionStep = @import("src/FunctionStep.zig");

pub fn build(b: *std.Build) void {
    const defaults: DefaultBuildOptions = .{
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
    };
    const func = FunctionStep.init(b, .{
        .makeFunc = testFunction,
        .cacheFunc = testFunction,
    });
    b.step("func", "").dependOn(&func.step);

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
}

pub fn addLibGitBuild(b: *std.Build, defaults: DefaultBuildOptions) void {
    const libgit2 = @import("src/libgit2.zig");
    if (b.lazyDependency("libgit2", defaults)) |dep| {
        libgit2.build(dep.builder);
        const git2_exe = b.addInstallArtifact(dep.artifact("git2"), .{
            .dest_sub_path = "git2",
        });
        b.getInstallStep().dependOn(&git2_exe.step);
        b.step("git2", "build the git2 exe").dependOn(&git2_exe.step);
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
        const cmake_exe = b.addInstallArtifact(dep.artifact("bootstrap"), .{
            .dest_sub_path = "cmake",
        });
        b.getInstallStep().dependOn(&cmake_exe.step);
        b.step("cmake", "build the cmake exe").dependOn(&cmake_exe.step);
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
        .is_tuple = false,
    } });
}

pub const DefaultBuildOptions = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    @"test": u8 = 0,
};

fn testFunction(man: *std.Build.Cache.Manifest, ctx: ?*anyopaque) anyerror!void{
    _ = ctx;
    var rand = std.Random.DefaultPrng.init(@as(u64, @bitCast(std.time.milliTimestamp())));
    man.hash.add(rand.random().int(u64));
}

pub const lazy = struct {
    pub fn dependency(b: *std.Build, name: []const u8, args: anytype) ?*std.Build.Dependency {
        const this_dep = b.dependencyFromBuildZig(meta_allyourcode, .{
            .dependency = name,
        });
        return this_dep.builder.lazyDependency(name, args);
    }
};
